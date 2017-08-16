//
//  ConditionalOperation.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/11/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import SystemConfiguration
import SwiftyJSON

let OperationErrorDomain = "OperationErrors"

enum OperationErrorCode: Int {
    case ConditionFailed = 1
    case ExecutionFailed = 2
}


class ConditionalOperations: Operation {
    
    private(set) var conditions = [OperationCondition]()
    private(set) var observers = [OperationObserver]()
    private var _internalErrors = [NSError]()
    private var _state = State.Initialized
    private let stateLock = NSLock()
    private var hasFinishedAlready = false
    
    class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    private enum State: Int, Comparable {
        /// The initial state of an `Operation`.
        case Initialized
        
        /// The `Operation` is ready to begin evaluating conditions.
        case Pending
        
        /// The `Operation` is evaluating conditions.
        case EvaluatingConditions
        
        /**
         The `Operation`'s conditions have all been satisfied, and it is ready
         to execute.
         */
        case Ready
        
        /// The `Operation` is executing.
        case Executing
        
        /**
         Execution of the `Operation` has finished, but it has not yet notified
         the queue of this.
         */
        case Finishing
        
        /// The `Operation` has finished executing.
        case Finished
        
        func canTransitionToState(target: State) -> Bool {
            switch (self, target) {
            case (.Initialized, .Pending):
                return true
            case (.Pending, .EvaluatingConditions):
                return true
            case (.EvaluatingConditions, .Ready):
                return true
            case (.Ready, .Executing):
                return true
            case (.Ready, .Finishing):
                return true
            case (.Executing, .Finishing):
                return true
            case (.Finishing, .Finished):
                return true
            default:
                return false
            }
        }
        
        static func <(lhs: ConditionalOperations.State, rhs: ConditionalOperations.State) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        static func ==(lhs: ConditionalOperations.State, rhs: ConditionalOperations.State) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }

    func willEnqueue() {
        _state = .Pending
    }
    
    private var state: State {
        get {
            return stateLock.withCriticalScope {
                _state
            }
        }
        
        set(newState) {
            /*
             It's important to note that the KVO notifications are NOT called from inside
             the lock. If they were, the app would deadlock, because in the middle of
             calling the `didChangeValueForKey()` method, the observers try to access
             properties like "isReady" or "isFinished". Since those methods also
             acquire the lock, then we'd be stuck waiting on our own lock. It's the
             classic definition of deadlock.
             */
            willChangeValue(forKey: "state")
            
            stateLock.withCriticalScope { Void -> Void in
                guard _state != .Finished else {
                    return
                }
                
                assert(_state.canTransitionToState(target: newState), "Performing invalid state transition.")
                _state = newState
            }
            
            didChangeValue(forKey: "state")
        }
    }
    
    // Here is where we extend our definition of "readiness".
    override var isReady: Bool {
        switch state {
            
        case .Initialized:
            // If the operation has been cancelled, "isReady" should return true
            return isCancelled
    
        case .Pending:
            // If the operation has been cancelled, "isReady" should return true
            guard !isCancelled else {
                return true
            }
            
            // If super isReady, conditions can be evaluated
            if super.isReady {
                evaluateConditions()
            }
            
            // Until conditions have been evaluated, "isReady" returns false
            return false
            
        case .Ready:
            return super.isReady || isCancelled
            
        default:
            return false
        }
    }
    
    override var isExecuting: Bool {
        return state == .Executing
    }
    
    override var isFinished: Bool {
        return state == .Finished
    }
    
    private func evaluateConditions() {
        assert(state == .Pending && !isCancelled, "evaluateConditions() was called out-of-order")
        
        state = .EvaluatingConditions
        OperationConditionEvaluator.evaluate(conditions: conditions, operation: self) { failures in
            self._internalErrors.append(contentsOf: failures)
            self.state = .Ready
        }
    }
    
    
    func addCondition(condition: OperationCondition) {
        assert(state < .EvaluatingConditions, "Cannot modify conditions after execution has begun.")
        conditions.append(condition)
    }
    
    func addObserver(observer: OperationObserver) {
        assert(state < .Executing, "Cannot modify observers after execution has begun.")
        
        observers.append(observer)
    }
    
    override func addDependency(_ operation: Operation) {
        assert(state < .Executing, "Dependencies cannot be modified after execution has begun.")
        super.addDependency(operation)
    }
    
    override final func start() {
        super.start()
        if isCancelled {
            finish()
        }
    }
    
    override final func main() {
        assert(state == .Ready, "This operation must be performed on an operation queue.")
        if _internalErrors.isEmpty && !isCancelled {
            state = .Executing
            execute()
            
            for observer in observers {
                observer.operationDidStart(operation: self)
            }

        }
        else {
            finish()
        }
    }
    
    func execute() {
            finish()
    }
    
    final func produceOperation(operation: Operation) {
        for observer in observers {
            observer.operation(operation: self, didProduceOperation: operation)
        }
    }

    
    final func finish(errors: [NSError] = []) {
        if !hasFinishedAlready {
            hasFinishedAlready = true
            state = .Finishing
            
            let combinedErrors = _internalErrors + errors
            finished(errors: combinedErrors)
            
            for observer in observers {
                observer.operationDidFinish(operation: self, errors: combinedErrors)
            }
            
            state = .Finished
        }
    }
    
    final func finishWithError(error: NSError?) {
        if let error = error {
            finish(errors: [error])
        }
        else {
            finish()
        }
    }
    
    func finished(errors: [NSError]) {
        // No op.
    }

}

let OperationConditionKey = "OperationCondition"

/**
 A protocol for defining conditions that must be satisfied in order for an
 operation to begin execution.
 */
protocol OperationCondition {
    /**
     The name of the condition. This is used in userInfo dictionaries of `.ConditionFailed`
     errors as the value of the `OperationConditionKey` key.
     */
    static var name: String { get }
    
    /**
     Specifies whether multiple instances of the conditionalized operation may
     be executing simultaneously.
     */
    static var isMutuallyExclusive: Bool { get }
    
    /**
     Some conditions may have the ability to satisfy the condition if another
     operation is executed first. Use this method to return an operation that
     (for example) asks for permission to perform the operation
     
     - parameter operation: The `Operation` to which the Condition has been added.
     - returns: An `NSOperation`, if a dependency should be automatically added. Otherwise, `nil`.
     - note: Only a single operation may be returned as a dependency. If you
     find that you need to return multiple operations, then you should be
     expressing that as multiple conditions. Alternatively, you could return
     a single `GroupOperation` that executes multiple operations internally.
     */
    func dependencyForOperation(operation: Operation) -> OperationCondition?
    
    /// Evaluate the condition, to see if it has been satisfied or not.
    func evaluateForOperation(operation: Operation, completion: @escaping (OperationConditionResult) -> Void)
}

/**
 An enum to indicate whether an `OperationCondition` was satisfied, or if it
 failed with an error.
 */
enum OperationConditionResult: Equatable {
    case Satisfied
    case Failed(NSError)
    
    var error: NSError? {
        if case .Failed(let error) = self {
            return error
        }
        
        return nil
    }
}

func ==(lhs: OperationConditionResult, rhs: OperationConditionResult) -> Bool {
    switch (lhs, rhs) {
    case (.Satisfied, .Satisfied):
        return true
    case (.Failed(let lError), .Failed(let rError)) where lError == rError:
        return true
    default:
        return false
    }
}



extension NSLock {
    func withCriticalScope<T>( block: (Void) -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

extension NSError {
    convenience init(code: OperationErrorCode, userInfo: [NSObject: AnyObject]? = nil) {
        self.init(domain: OperationErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}

struct OperationConditionEvaluator {
    static func evaluate(conditions: [OperationCondition], operation: Operation, completion: @escaping ([NSError]) -> Void) {
        // Check conditions.
        let conditionGroup = DispatchGroup()
        
        var results = [OperationConditionResult?](repeating: nil, count: conditions.count)
        
        // Ask each condition to evaluate and store its result in the "results" array.
        for (index, condition) in conditions.enumerated() {
            conditionGroup.enter()
            condition.evaluateForOperation(operation: operation) { result in
                results[index] = result
                conditionGroup.leave()
            }
        }
        
        
        conditionGroup.notify(queue: DispatchQueue.global()) {
            // Aggregate the errors that occurred, in order.
            var failures = results.flatMap { $0?.error }
            
            /*
             If any of the conditions caused this operation to be cancelled,
             check for that.
             */
            if operation.isCancelled {
                failures.append(NSError(code: .ConditionFailed))
            }
            
            completion(failures)
        }
    }
}

/**
 The protocol that types may implement if they wish to be notified of significant
 operation lifecycle events.
 */
protocol OperationObserver {
    
    /// Invoked immediately prior to the `Operation`'s `execute()` method.
    func operationDidStart(operation: ConditionalOperations)
    
    /// Invoked when `Operation.produceOperation(_:)` is executed.
    func operation(operation: ConditionalOperations, didProduceOperation newOperation: Operation)
    
    /**
     Invoked as an `Operation` finishes, along with any errors produced during
     execution (or readiness evaluation).
     */
    func operationDidFinish(operation: ConditionalOperations, errors: [NSError])
    
}


private var URLSessionTaksOperationKVOContext = 0

/**
 `URLSessionTaskOperation` is an `Operation` that lifts an `NSURLSessionTask`
 into an operation.
 
 Note that this operation does not participate in any of the delegate callbacks \
 of an `NSURLSession`, but instead uses Key-Value-Observing to know when the
 task has been completed. It also does not get notified about any errors that
 occurred during execution of the task.
 
 An example usage of `URLSessionTaskOperation` can be seen in the `DownloadEarthquakesOperation`.
 */
class URLSessionTaskOperation: ConditionalOperations {
    let task: URLSessionTask
    
    init(task: URLSessionTask) {
        assert(task.state == .suspended, "Tasks must be suspended.")
        self.task = task
        super.init()
    }
    
    override func execute() {
        assert(task.state == .suspended, "Task was resumed by something other than \(self).")
        task.addObserver(self, forKeyPath: "state", options: [], context: &URLSessionTaksOperationKVOContext)
        task.resume()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &URLSessionTaksOperationKVOContext else { return }
        
        if keyPath == "state" && task.state == .completed {
            task.removeObserver(self, forKeyPath: "state")
            finish()
        }
        
    }
    
    override func cancel() {
        task.cancel()
        super.cancel()
    }
}

struct ReachabilityCondition: OperationCondition {
    /// Evaluate the condition, to see if it has been satisfied or not.
    func evaluateForOperation(operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        ReachabilityController.requestReachability(url: host) { reachable in
            if reachable {
                completion(.Satisfied)
            }
            else {
                let error = NSError(code: .ConditionFailed, userInfo: [
                    OperationConditionKey as NSObject: "Dynamic Type" as AnyObject
                    ])
                
                completion(.Failed(error))
            }
        }

    }

    /**
     Some conditions may have the ability to satisfy the condition if another
     operation is executed first. Use this method to return an operation that
     (for example) asks for permission to perform the operation
     
     - parameter operation: The `Operation` to which the Condition has been added.
     - returns: An `NSOperation`, if a dependency should be automatically added. Otherwise, `nil`.
     - note: Only a single operation may be returned as a dependency. If you
     find that you need to return multiple operations, then you should be
     expressing that as multiple conditions. Alternatively, you could return
     a single `GroupOperation` that executes multiple operations internally.
     */
    func dependencyForOperation(operation: Operation) -> OperationCondition? {
        return nil
    }

    static let hostKey = "Host"
    static let name = "Reachability"
    static let isMutuallyExclusive = false
    
    let host: NSURL
    
    
    init(host: NSURL) {
        self.host = host
    }
    
}

/// A private singleton that maintains a basic cache of `SCNetworkReachability` objects.
private class ReachabilityController {
    static var reachabilityRefs = [String: SCNetworkReachability]()
    
    static let reachabilityQueue = DispatchQueue(label: "Operations.Reachability")
    
    static func requestReachability(url: NSURL, completionHandler: @escaping (Bool) -> Void) {
        if let host = url.host {
            reachabilityQueue.async() {
                var ref = self.reachabilityRefs[host]
                
                if ref == nil {
                    let hostString = host as NSString
                    ref = SCNetworkReachabilityCreateWithName(nil, hostString.utf8String!)
                }
                
                if let ref = ref {
                    self.reachabilityRefs[host] = ref
                    
                    var reachable = false
                    var flags: SCNetworkReachabilityFlags = []
                    if SCNetworkReachabilityGetFlags(ref, &flags) != false {
                        /*
                         Note that this is a very basic "is reachable" check.
                         Your app may choose to allow for other considerations,
                         such as whether or not the connection would require
                         VPN, a cellular connection, etc.
                         */
                        reachable = flags.contains(.reachable)
                    }
                    completionHandler(reachable)
                }
                else {
                    completionHandler(false)
                }
            }
        }
        else {
            completionHandler(false)
        }
    }
}

public class OperationQueueManager {
    
    lazy var queue : OperationQueue = {
        let q = OperationQueue()
        q.name = "SharedQueue"
        q.qualityOfService = .background
        return q
    }()

    static var shared : OperationQueueManager {
        struct Singleton {
            static let instance = OperationQueueManager()
        }
        return Singleton.instance
    }
}

