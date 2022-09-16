//
//  Model.swift
//  www
//
//  Created by LJM on 2022/9/2.
//

import Foundation
import CoreText
import UIKit

struct Model: Codable {
    var array: [Item]
    
    private enum CodingKeys: String, CodingKey {
        case array = "array"
    }
    
    init(array: [Item]) {
        self.array = array
    }
}

struct Item: Codable {
    var displayname: String
    var orderStr: String
    var numberStr: String
    var lockCode: String
    
    private enum CodingKeys: String, CodingKey {
        case displayname = "displayname"
        case orderStr = "orderStr"
        case numberStr = "numberStr"
        case lockCode = "lockCode"
    }
    
    init(displayname: String, orderStr: String, numberStr: String, lockCode: String) {
        self.displayname = displayname
        self.orderStr = orderStr
        self.numberStr = numberStr
        self.lockCode = lockCode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayname = try container.decodeIfPresent(String.self, forKey: .displayname) ?? ""
        orderStr = try container.decodeIfPresent(String.self, forKey: .orderStr) ?? ""
        numberStr = try container.decodeIfPresent(String.self, forKey: .numberStr) ?? ""
        lockCode = try container.decodeIfPresent(String.self, forKey: .lockCode) ?? ""
    }
}
