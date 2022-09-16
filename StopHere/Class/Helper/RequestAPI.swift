//
//  RequestAPI.swift
//  StopHereSwift
//
//  Created by yuszha on 2017/9/14.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON
import CryptoSwift

// MARK: - Provider setup

private func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data // fallback to original data if it can't be serialized.
    }
}

private func JSONRequestDataFormatterTask(_ dictionary : Dictionary<String, Any>) -> Task {
    if let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
        return Task.requestCustomJSONEncodable(data, encoder: JSONEncoder())
    }
    else {
        return Task.requestPlain
    }
    
}


let StopHereProvider = MoyaProvider<StopHereTarget>(plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter)])

// MARK: - Provider support

private extension String {
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

public enum StopHereTarget {
    //登陆
    case login(String, String)
    case selectLockProduction(String)
    case controlHub(String, String)
    case getOtaRecord()
    case uploadDNName(String, String)
    case insertSdkRecord([String : Any])
}


let BASE_URL = "http://39.107.202.236:8086" //正式

//let BASE_URL = "http://47.93.113.61:8086"  // 测试

//let BASE_URL = "http://39.107.202.236:8086"


extension StopHereTarget: TargetType {
    public var baseURL: URL {
//        switch self {
//
//        case .selectLockProduction(_):
//            return URL(string: BASE_URL)!
//        case .controlHub(_, _):
//            return URL(string: "http://39.107.202.236:8086")!
//
//        }
        
        switch self {
        case .insertSdkRecord(_):
            return URL(string: "http://zentao.wiparking.net:9090")!
        default:
            return URL(string: BASE_URL)!
        }
        
    }
    public var path: String {
        switch self {
        case .login(_, _):
            return "/manage/user/login"
        case .selectLockProduction(_):
            return "manage/install/selectLockProduction"
        case .controlHub(_, _):
            return "/manage/inspection/controlHub"
        case .getOtaRecord():
            return "manage/blend/getOtaRecord"
            
        case .uploadDNName(_, _):
            return "manage/blend/insertOtaMac"
        case .insertSdkRecord(_) :
            return "/parkinglock/insertSdkRecord"
            
        }
    }
    public var method: Moya.Method {
        return .post
    }
    public var parameters: [String: Any]? {
        switch self {
      
        default:
            return nil
        }
    }
    public var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    public var task: Task {
        switch self {
        case .login(let mobile, let password):
            return .requestJSONEncodable(["mobile": mobile, "password": password.md5().subString(to: 15)])
        case .selectLockProduction(let batch):
            return .requestJSONEncodable(["batch": batch])
        case .controlHub(let ssId, let lockCode):
            return JSONRequestDataFormatterTask(["ssId": ssId, "lockCode": lockCode, "sdkId": "35bd5797380356", "token": "0f0f84aeaaee58de38f49ca1e8786c66", "uId": UserModel.shared.uId, "platform": 1, "sourceSign" : 5])
        case .getOtaRecord():
            return .requestJSONEncodable(["": ""])
        case .uploadDNName(let name, let subName):
            return .requestJSONEncodable(["name": name, "ssid": subName])
        case .insertSdkRecord(let parameter):
            return JSONRequestDataFormatterTask(parameter)
        }
        
    }
    public var validate: Bool {
        switch self {
        default:
            return false
        }
    }
    public var sampleData: Data {
        return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
    }
    public var headers: [String: String]? {
        return nil
    }
}

public func url(_ route: TargetType) -> String {
    return route.baseURL.appendingPathComponent(route.path).absoluteString
}

//MARK: - Response Handlers

extension Moya.Response {
    func mapNSArray() throws -> NSArray {
        let any = try self.mapJSON()
        guard let array = any as? NSArray else {
            throw MoyaError.jsonMapping(self)
        }
        return array
    }
}

//open class RequestJSONEncoder : JSONEncoder {
//    override open func encode<T>(_ value: T) throws -> Data where T : Encodable {
//        if let value = value as? AnyEncodable {
//            if let encodable = value.encodable as? Data {
//                return encodable
//            }
//            return try JSONSerialization.data(withJSONObject: value.encodable, options: [])
//        }
//        return try super.encode(value)
//    }
//}

