//
//  UserModel.swift
//  StopHereManager
//
//  Created by yuszha on 2018/2/26.
//  Copyright © 2018年 yuszha. All rights reserved.
//

import UIKit

import ObjectMapper

let USER_LOGIN_MOBILE = "USER_LOGIN_MOBILE"
let USER_LOGIN_PASSWORD = "USER_LOGIN_PASSWORD"
let USER_LOGIN_UID = "USER_LOGIN_UID"
let USER_LOGIN_MID = "USER_LOGIN_MID"
let USER_LOGIN_NAME = "USER_LOGIN_NAME"

class UserModel: NSObject {
    
    public static let shared = UserModel()
    
    var uId: Int! {
        didSet {
            UserDefaults.standard.set(uId, forKey: USER_LOGIN_UID)
        }
    }
    var mId: Int! {
        didSet {
            UserDefaults.standard.set(mId, forKey: USER_LOGIN_MID)
        }
    }
    var name: String! {
        didSet {
            UserDefaults.standard.set(name, forKey: USER_LOGIN_NAME)
        }
    }
    
    override init() {
        uId = UserDefaults.standard.object(forKey: USER_LOGIN_UID) as? Int
        mId = UserDefaults.standard.object(forKey: USER_LOGIN_MID) as? Int
        name = UserDefaults.standard.object(forKey: USER_LOGIN_NAME) as? String
    }
    
    var mobile : String? {
        get {
            return UserDefaults.standard.object(forKey: USER_LOGIN_MOBILE) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: USER_LOGIN_MOBILE)
        }
    }
    
    var password : String? {
        get {
            return UserDefaults.standard.object(forKey: USER_LOGIN_PASSWORD) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: USER_LOGIN_PASSWORD)
        }
    }
}
