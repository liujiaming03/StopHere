//
//  LBXScanViewControllerHelper.swift
//  StopHereManager
//
//  Created by yuszha on 2018/3/6.
//  Copyright © 2018年 yuszha. All rights reserved.
//

import UIKit
import AVFoundation
import swiftScan

protocol ScanViewControllerDelegate {
    func scanResult(_ result : String)
}

class ScanViewController : LBXScanViewController {
    
    var scanViewDelegate: ScanViewControllerDelegate?
    var scanResultBlock : ((String) -> (Void))!
    
    let backButton : UIButton = {
        let button = UIButton()
        button.setImage(UIImage.init(named: "back"), for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 22.0
        button.frame = CGRect.init(x: 20, y: 20, width: 44, height: 44)
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        
        return button
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.arrayCodeType = [AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.ean8, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.pdf417]
        
        var style = LBXScanViewStyle()
        
        style.centerUpOffset = 60;
        style.xScanRetangleOffset = 30;
        
        if UIScreen.main.bounds.size.height <= 480
        {
            //3.5inch 显示的扫码缩小
            style.centerUpOffset = 40;
            style.xScanRetangleOffset = 20;
        }
        readyString = "相机启动中..."
        
        style.color_NotRecoginitonArea = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.4)
        
        
        style.photoframeAngleStyle = LBXScanViewPhotoframeAngleStyle.Inner;
        style.photoframeLineW = 2.0;
        style.photoframeAngleW = 16;
        style.photoframeAngleH = 16;
        
        style.isNeedShowRetangle = false;
        
        style.anmiationStyle = LBXScanViewAnimationStyle.NetGrid;
        style.animationImage = UIImage(named: "CodeScan.bundle/qrcode_scan_full_net")
        
        self.scanStyle = style
        
        
        
    }
    
    @objc func backAction() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if navigationController == nil {
            
            self.view.addSubview(backButton)
        }
        
        title = "扫一扫"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.bringSubview(toFront: backButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override open func handleCodeResult(arrayResult:[LBXScanResult])
    {
        self.navigationController? .popViewController(animated: true)
        let result:LBXScanResult = arrayResult[0]
        
        if let rusultStr = result.strScanned {
            scanViewDelegate?.scanResult(rusultStr)
            scanResultBlock?(rusultStr)
            dismiss(animated: true, completion: nil)
        }
        else {
            self.startScan()
        }
        
    }
}

