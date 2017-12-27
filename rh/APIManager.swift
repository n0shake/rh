//
//  APIManager.swift
//  rh
//
//  Created by Banthia, Abhishek on 8/8/17.
//  Copyright © 2017 Abhishek Banthia. All rights reserved.
//

import Cocoa
import Foundation
import SwiftyJSON

public enum Endpoints : String {
    case BaseURL = "https://api.robinhood.com"
    case TokenURL = "/api-token-auth/"
    case WatchListURL = "/watchlists/Default/"
    case PortfolioURL = "/portfolios/"
    case SecuritiesURL = "/positions/?nonzero=true"
    case QuotesURL = "/quotes/?symbols="
    
    var url: String {
        switch self {
        case .BaseURL:
            return Endpoints.BaseURL.rawValue
            
        default:
            return "\(Endpoints.BaseURL.rawValue)\(self.rawValue)"
        }
    }
}

class APIManager: NSObject {
    
    private lazy var urlSession : URLSession = {
        let session = URLSessionConfiguration.default
        session.urlCache = nil
        session.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: session)
    }()
    
    static var shared: APIManager {
        struct Singleton {
            static let instance = APIManager()
        }
        return Singleton.instance
    }
    
    func authenticate(username: String, password:String, MFA : String?, completion : @escaping (_ response : String?, _ error : Error?) -> Void) {
    
        var parameters = String(format: "username=%@&password=%@", username, password)
        
        if let mfa_code = MFA {
            let mfa = String(format: "&mfa_code=%@", mfa_code)
            parameters.append(mfa)
        }
    
        var request = URLRequest(url: URL(string:Endpoints.TokenURL.url)!)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let task = self.urlSession.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            let json = try? JSON(data: data)
            
            if let _ = json!["mfa_required"].bool, let mfa_type = json!["mfa_type"].string{
                let userInfoDictionary : [String:Any] = [NSLocalizedDescriptionKey : "2FA required by type \(mfa_type)"]
                let error = NSError(domain:"2FA on.", code:100, userInfo:userInfoDictionary)
                completion(nil, error)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                let response = responseString!
                let userInfoDictionary : [String:Any] = response.contains("Unable to log in with provided credentials") ? [NSLocalizedDescriptionKey : "Invalid Credentials"] : [NSLocalizedDescriptionKey : response]
                let error = NSError(domain:"Unsuccessful API request", code:httpStatus.statusCode, userInfo:userInfoDictionary)
                completion(nil, error)
                return
            }
            
            completion(responseString, nil)
        }
        
        task.resume()
    }

    func getRequest(_ url: String, completionHandler : @escaping (_ response : JSON?, _ error : Error?) -> Void) {
        
        guard let token = Authenticator.shared.authenticationToken else {
            return
        }

        let headers = ["authorization": "Token \(token)"]
        let request = NSMutableURLRequest(url: URL(string: url)!,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let dataTask = self.urlSession.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            guard let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                var userInfoDictionary : [String:Any] = httpStatus.statusCode == 401 ? [NSLocalizedDescriptionKey : "Invalid Credentials"] : [NSLocalizedDescriptionKey : JSON(data).string ?? "API Error \(httpStatus.statusCode)"]
                if httpStatus.statusCode == 500 {
                    userInfoDictionary = [NSLocalizedDescriptionKey : "Server Error"]
                }
                
                let error = NSError(domain:"Unsuccessful API request", code:httpStatus.statusCode, userInfo:userInfoDictionary)
                completionHandler(nil, error)
                return
            }

            let json = try? JSON(data: data)
            completionHandler(json!, nil)

        })
        
        dataTask.resume()
    }
    
    func getQuotes(_ url: String, completionHandler : @escaping (_ response : Array<Quote>?, _ error : Error?) -> Void){

        guard let token = Authenticator.shared.authenticationToken else {
            return
        }
        
        let headers = ["authorization": "Token \(token)"]
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let dataTask = self.urlSession.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error ?? "Error")
            } else {
                let json = try? JSON(data: data!)
                let quotes = json!["results"].array
                var modelArray = Array<Quote>()
                for quote in quotes! {
                    let quoteModel = Quote(json: quote)
                    modelArray.append(quoteModel)
                }
                completionHandler(modelArray, nil)
            }
        })
        
        dataTask.resume()
    }
    
    func getInstrument(withURL: String, completionHandler : @escaping (_ response : JSON?, _ error : Error?) -> Void) {
        
        var request = URLRequest(url: URL(string: withURL)!,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10.0)
        request.httpMethod = "GET"
        
        let dataTask = self.urlSession.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            guard let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                let response = responseString!
                let userInfoDictionary : [String:Any] = response.contains("Unable to log in with provided credentials") ? [NSLocalizedDescriptionKey : "Invalid Credentials"] : [NSLocalizedDescriptionKey : response]
                let error = NSError(domain:"Unsuccessful API request", code:httpStatus.statusCode, userInfo:userInfoDictionary)
                completionHandler(nil, error)
                return
            }
            
            let json = try? JSON(data: data)
            completionHandler(json!, nil)
        })
        
        dataTask.resume()
        
    }
    
    
}
