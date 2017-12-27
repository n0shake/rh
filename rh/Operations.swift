//
//  ConditionalOperation.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/11/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import SystemConfiguration

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

