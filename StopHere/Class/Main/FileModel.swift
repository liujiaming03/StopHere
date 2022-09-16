//
//  FileModel.swift
//  StopHere
//
//  Created by LJM on 2022/9/16.
//  Copyright © 2022 yuszha. All rights reserved.
//

import Foundation

class FileModel: NSObject {
    
    public static let shared = FileModel()
    
    var fileModel: DownloadFileModel?
    
    override init() {
        fileModel = nil
    }
}
