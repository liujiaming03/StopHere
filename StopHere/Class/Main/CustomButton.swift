//
//  CustomButton.swift
//  StopHere
//
//  Created by LJM on 2022/9/14.
//  Copyright © 2022 yuszha. All rights reserved.
//

import Foundation
import UIKit

class CustomButton: UIButton {
    
    var info: Item!
    
    override init(frame: CGRect) {
        super .init(frame: frame)
        backgroundColor = UIColor(red: 210/255.0, green: 232/255.0, blue: 232/255.0, alpha: 1)
        self.setTitleColor(.black, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setInfo(info: Item) {
        self.info = info
        self.setTitle(info.displayname, for: .normal)
    }
}
