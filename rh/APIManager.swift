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
    
    static var shared: APIManager {
        struct Singleton {
            static let instance = APIManager()
        }
        return Singleton.instance
    }
    
    func authenticate(username: String, password:String, completion : @escaping (_ response : String?, _ error : Error?) -> Void) {
    
        let parameters = String(format: "username=%@&password=%@", username, password)
        var request = URLRequest(url: URL(string:Endpoints.TokenURL.url)!)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                let response = responseString!
                let userInfoDictionary : [String:Any] = response.contains("Unable to log in with provided credentials") ? [NSLocalizedDescriptionKey : "Invalid Credentials"] : [NSLocalizedDescriptionKey : "API Error \(httpStatus.statusCode)"]
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
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            guard let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                let userInfoDictionary : [String:Any] = httpStatus.statusCode == 401 ? [NSLocalizedDescriptionKey : "Invalid Credentials"] : [NSLocalizedDescriptionKey : "API Error \(httpStatus.statusCode)"]
                let error = NSError(domain:"Unsuccessful API request", code:httpStatus.statusCode, userInfo:userInfoDictionary)
                completionHandler(nil, error)
                return
            }

            let json = JSON(data: data)
            completionHandler(json, nil)

        })
        
        dataTask.resume()
    }
    
    func getInstrument(withURL: String, completionHandler : @escaping (_ response : JSON?, _ error : Error?) -> Void) {
        
        var request = URLRequest(url: URL(string: withURL)!,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10.0)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            guard let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                let response = responseString!
                let userInfoDictionary : [String:Any] = response.contains("Unable to log in with provided credentials") ? [NSLocalizedDescriptionKey : "Invalid Credentials"] : [NSLocalizedDescriptionKey : "API Error \(httpStatus.statusCode)"]
                let error = NSError(domain:"Unsuccessful API request", code:httpStatus.statusCode, userInfo:userInfoDictionary)
                completionHandler(nil, error)
                return
            }
            
            let json = JSON(data: data)
            completionHandler(json, nil)
        })
        
        dataTask.resume()
        
    }
    
    
}
