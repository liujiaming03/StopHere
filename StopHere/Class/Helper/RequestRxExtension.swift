//
//  RequestRxExtension.swift
//  StopHereManager
//
//  Created by yuszha on 2018/2/26.
//  Copyright © 2018年 yuszha. All rights reserved.
//
import Foundation
import RxSwift
import SVProgressHUD
import Moya

enum RequestError : Error {
    case noData
    case errorCode
}

public extension Reactive where Base: MoyaProviderType {
//    , errorCallBack: ((String) -> (Void))? = nil
    public func mapRequest(_ token: Base.Target, callbackQueue: DispatchQueue? = nil) -> Single<Dictionary<String, Any>> {
        return Single.create { [weak base] single in
            let cancellableToken = base?.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response):
                    if let map = try? response.mapJSON() as? Dictionary<String, Any> {
                        if let errorCode = map?["errCode"] as? Int , errorCode == 1 {
                            single(.success(map!))
                            if let resultData = map!["resultData"] as? Array<Dictionary<String, Any>>, let first = resultData.first {
                                var str3 = ""
                                var str4 = ""
                                for (key, value) in first {
                                    if let _ = value as? Int {
                                        str3 += "var " + key + ": Int = 0"
                                    }
                                    else if let _ = value as? String {
                                        str3 += "var " + key + ": String?"
                                    }
                                    else if let _ = value as? Float {
                                        str3 += "var " + key + ": Float = 0.0"
                                    }
                                        
                                    else {
                                        str3 += "var " + key + ": Other"
                                    }
                                    str4 += key + " <- map[\"" + key + "\"]" + "\n"
                                    
                                    str3 += "\n"
                                }
                                print(str3)
                                print(str4)
                            }
                            else if let resultData = map!["resultData"] as? Dictionary<String, Any> {
                                var str = ""
                                var str2 = ""
                                
                                for (key, value) in resultData {
                                    if let _ = value as? Int {
                                        str += "var " + key + ": Int = 0"
                                    }
                                    else if let _ = value as? String {
                                        str += "var " + key + ": String?"
                                    }
                                    else if let _ = value as? Float {
                                        str += "var " + key + ": Float = 0.0"
                                    }
                                    else if let value = value as? Array<Dictionary<String, Any>> {
                                        var str3 = ""
                                        var str4 = ""
                                        if value.count != 0 {
                                            for (key, value) in value.first! {
                                                if let _ = value as? Int {
                                                    str3 += "var " + key + ": Int = 0"
                                                }
                                                else if let _ = value as? String {
                                                    str3 += "var " + key + ": String?"
                                                }
                                                else if let _ = value as? Float {
                                                    str3 += "var " + key + ": Float = 0.0"
                                                }
                                                    
                                                else {
                                                    str3 += "var " + key + ": Other"
                                                }
                                                str4 += key + " <- map[\"" + key + "\"]" + "\n"
                                                
                                                str3 += "\n"
                                            }
                                        }
                                        
                                        print(str3)
                                        print(str4)
                                        
                                        str += "var " + key + ": Array<Dictionary<String, Any>>?"
                                    }
                                    else if let value = value as? Dictionary<String, Any> {
                                        var str3 = ""
                                        var str4 = ""
                                        for (key, value) in value {
                                            if let _ = value as? Int {
                                                str3 += "var " + key + ": Int = 0"
                                            }
                                            else if let _ = value as? String {
                                                str3 += "var " + key + ": String?"
                                            }
                                            else if let _ = value as? Float {
                                                str3 += "var " + key + ": Float = 0.0"
                                            }
                                                
                                            else {
                                                str3 += "var " + key + ": Other"
                                            }
                                            str4 += key + " <- map[\"" + key + "\"]" + "\n"
                                            
                                            str3 += "\n"
                                        }
                                        print(str3)
                                        print(str4)
                                        
                                        str += "var " + key + ": Dictionary<String, Any>?"
                                    }
                                    else {
                                        str += "var " + key + ": Other"
                                    }
                                    str2 += key + " <- map[\"" + key + "\"]" + "\n"
                                    
                                    str += "\n"
                                }
                                print(str)
                                print(str2)
                            }
                            
                            return
                        }
                        if let msg = map?["msg"] as? String {
//                            ShowHUD(error: msg)
                            SVProgressHUD.showError(withStatus: msg)
                            
                        }
                        single(.error(RequestError.errorCode))
                        return
                    }
                    single(.error(RequestError.noData))
                case let .failure(error):
                    single(.error(error))
                }
            }
            
            return Disposables.create {
                cancellableToken?.cancel()
            }
        }
    }
}
