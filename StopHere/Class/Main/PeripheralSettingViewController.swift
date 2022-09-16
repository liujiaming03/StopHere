//
//  PeripheralSettingViewController.swift
//  StopHere
//
//  Created by yuszha on 2017/7/20.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import CoreBluetooth
import MessageUI
import SVProgressHUD
import RxSwift
import RxCocoa

import SCLAlertView

import MessageUI
import iOSDFULibrary

class PeripheralSettingViewController: UIViewController {
    
    var buttonModel: Model!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var downloadView: UIView!
    
    @IBOutlet var custemRightView: UIView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var recieveTypeButton: UIButton!
    @IBOutlet weak var electricityLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var outputTextView: UITextView!
    
    @IBOutlet weak var saleOrMutButton: UIButton!
    var outputString = ""
    
    @IBOutlet weak var passwordLabel: UILabel!
    let characteristicUUIDString = "FFF6"
    
    lazy var alertController : CustemAlertViewController = {
        let vc = CustemAlertViewController()
        self.addChildViewController(vc)
        self.view.addSubview(vc.view)
        vc.view.frame = self.view.frame

        return vc
    }()

    var peripheral : CBPeripheral!
    
    let disposeBag = DisposeBag()
    
    let serviceStrList = ["FFF1", "FFF2", "FFF3", "FFF4", "FFF5", "FFF6"]
    
    var characteristics = [CBCharacteristic]()
    
    var characteristic : CBCharacteristic?
    var rCharacteristic : CBCharacteristic?

    @IBOutlet var actionButtons: [UIButton]!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var snButton: UIButton!
    @IBOutlet weak var postResultButton: UIButton!
    
    
    // OTA
    @IBOutlet weak var uploadStatus: UILabel!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var fileStatusButton: UIButton!
    
    var fileModel : DownloadFileModel! {
        didSet {
            fileStatusButton.setTitle(fileModel.name, for: .normal)
            if let localPath = fileModel.localPath {
                do {
                    selectedFirmware = try DFUFirmware(urlToZipFile: URL.init(fileURLWithPath: localPath))
                } catch {
                    
                }
            }
        }
    }
    
    var dfuController      : DFUServiceController?
    var selectedFirmware   : DFUFirmware?
    //是否正在写入文件
    var isImportingFile = false
    
    var last_lock_SSID = BlueToothHelper.shared.last_lock_SSID
    var currentLockInfo = PeripheralInfoHelper.shared.getDefaultMap(ssid: BlueToothHelper.shared.last_lock_SSID)
    
    var passwordStr : String!
    
    var offsetNumber = 0
    
    var isBLE = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 导航栏设置
        custemImageTitle()
        view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1)
    
        // 设置蓝牙代理
        BlueToothHelper.shared.addDelegate(self)
        self.buttonView.backgroundColor = .white
        self.downloadView.backgroundColor = UIColor(red: 210/255.0, green: 232/255.0, blue: 232/255.0, alpha: 1)
        self.infoView.backgroundColor = .white
        self.outputTextView.backgroundColor = UIColor(red: 235/255.0, green: 235/255.0, blue: 235/255.0, alpha: 1)
        
        // 拉取 加载json里的button
        getJson()
        
        // 缓存文件
        if FileModel.shared.fileModel?.name != nil {
            fileModel = FileModel.shared.fileModel
        }
        
        passwordStr = PeripheralInfoHelper.shared.getManagerPassword(BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString]! )
        passwordLabel.text = passwordStr
        
        passwordLabel.isHidden = BlueToothHelper.shared.showPassword
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: custemRightView)
        
        if peripheral.state == .connected {
            refreshAction(refreshButton)
        }
        else {
        
        }
        
        if peripheral.state == .connected {
            activityIndicatorView.stopAnimating()
            refreshButton.setTitle("已连接", for: UIControlState())
        }
        else {
            activityIndicatorView.startAnimating()
            refreshButton.setTitle("未连接", for: UIControlState())
        }
        
        navigationItem.leftBarButtonItems = [UIBarButtonItem.init(image: UIImage.init(named: "back"), style: .plain, target: self, action: #selector(backAction)), UIBarButtonItem.init(title: BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] ?? "", style: .plain, target: nil, action: nil)]
        
        
        for button in actionButtons {
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.textAlignment = .center
        }

        recieveTypeButton.setTitle(BlueToothHelper.shared.defaultRecivedType.rawValue, for: UIControlState())

        lockButton.setTitle("Lock：" + (currentLockInfo?["ssid"] ?? ""), for: .normal)
        snButton.setTitle("SN：" + (currentLockInfo?["pid"] ?? ""), for: .normal)
    }
    
    @objc func backAction() {
        
        if self.isImportingFile {
            return
        }
        
        
        if self.rCharacteristic != nil {
            self.peripheral.setNotifyValue(false, for: self.rCharacteristic!)
        }
        
        BlueToothHelper.shared.resetCenterManager()
        BlueToothHelper.shared.removeDelegate(self)
        BlueToothHelper.shared.disConnect(peripheral)
        navigationController?.popViewController(animated: true)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    
    func checkIsConnect() -> Bool {
    
        if (peripheral.state == .disconnected) {
            let alertVC = UIAlertController.init(title: "设备已断开", message: "重新连接？", preferredStyle: UIAlertControllerStyle.alert)
            
            alertVC.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (_) in
                BlueToothHelper.shared.connect(self.peripheral)
            }))
            alertVC.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (_) in
                
            }))
            
            navigationController?.present(alertVC, animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
    
    
    @objc func buttonClick(sender: CustomButton) {
        
        guard passwordStr != nil else {
            return
        }
        
        guard checkIsConnect() else {
            return
        }
        
        guard self.characteristic != nil else {
            return
        }
        guard let title = sender.titleLabel?.text else { return }

//        let passwordStr = PeripheralInfoHelper.shared.getManagerPassword(BlueToothHelper.shared.nameMap[self.peripheral.identifier.uuidString]!)
        
        
        let orderStr = sender.info.orderStr
        let numberStr = sender.info.numberStr
        let lockCode = sender.info.lockCode
        
        if isBLE == false && lockCode.count > 0 , let ssid =  BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] {
            StopHereProvider.rx.request(.controlHub(ssid, lockCode)).subscribe(onSuccess: { (respose) in
                
            }) { (error) in
                
            }.disposed(by: disposeBag)
        }
        else {
            var order = passwordStr + "M" + orderStr + numberStr
            
            if title == "用户鸣叫", let name = BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] {
                order = PeripheralInfoHelper.shared.getUserPassword(name) + "U" + orderStr + numberStr
            }
            
            guard let characteristic = self.characteristic, let peripheral = self.peripheral else { return }
            
            peripheral.writeValue(BlueToothHelper.shared.dataFromString(order), for: characteristic, type: .withResponse)
            
            recordControlLock(lockCode)
        }
    }
    
    
    @IBAction func userAction(_ sender: Any) {
        
        guard passwordStr != nil else {
            return
        }
        
        guard checkIsConnect() else {
            return
        }
        
        guard self.characteristic != nil else {
            return
        }
        guard let button = sender as? UIButton , let _ = button.titleLabel?.text else { return }

        otherUserAction(button.tag)
    }
    
    func recordControlLock(_ lockCode: String) {
        if lockCode.length == 0 {
            return
        }
        var parameter = [String : Any]()
        
        parameter["ssId"] = BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString]!
        
        parameter["lockCode"] = lockCode
        
        parameter["token"] = "0f0f84aeaaee58de38f49ca1e8786c66"
        parameter["sdkId"] = "35bd5797380356"
        parameter["sourceSign"] = 5
        parameter["platform"] = 1
        parameter["uId"] = UserModel.shared.uId
        
        StopHereProvider.rx.mapRequest(.insertSdkRecord(parameter)).subscribe(onSuccess: { (result) in
            
        }) { (error) in
            
        }.disposed(by: disposeBag)
    }
    
    func otherUserAction(_ tag : Int) {
        
        switch tag {
        case 1000: //index
           
            break
        case 1001: //lock
            let alertView = SCLAlertView()
            let textField = alertView.addTextField()
            textField.text = currentLockInfo?["ssid"]
            textField.keyboardType = .default
            alertView.addButton("确定") {
                if let number = textField.text , number.count == 6, let info = PeripheralInfoHelper.shared.getMap( ssid : number) {
                    self.currentLockInfo = info
                    self.last_lock_SSID = info["ssid"]
                    BlueToothHelper.shared.last_lock_SSID = self.last_lock_SSID
                    self.lockButton.setTitle("Lock：" + (self.currentLockInfo?["ssid"] ?? ""), for: .normal)
                    self.snButton.setTitle("SN：" + (self.currentLockInfo?["pid"] ?? ""), for: .normal)
                }
                else {
                    let alertView = SCLAlertView()
                    
                    alertView.showInfo("该编号不存在", subTitle: "", closeButtonTitle: "取消")
                }
            }
            alertView.showEdit("请输入Lock编号", subTitle: "", closeButtonTitle: "取消")
            break
        case 1002: //上一个

            break
        case 1003: //下一个

            break
        case 1004: //开始改名
            if let ssid = currentLockInfo?["ssid"] , let password = passwordStr   {
                let up = PeripheralInfoHelper.shared.getUserPassword(ssid)
                let mp = PeripheralInfoHelper.shared.getManagerPassword(ssid)
                
                let order = password + "M" + "St" + ssid
                let order1 = up + "M" + "Ed" + mp
                guard let characteristic = self.characteristic, let peripheral = self.peripheral else { return }
                
                peripheral.writeValue(BlueToothHelper.shared.dataFromString(order), for: characteristic, type: .withResponse)
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(3), execute: {
                    peripheral.writeValue(BlueToothHelper.shared.dataFromString(order1), for: characteristic, type: .withResponse)
                })
                
//                let alertView = SCLAlertView()
//                let nameField = alertView.addTextField(ssid)
//                nameField.text = ssid
//                nameField.keyboardType = .default
//                let upField = alertView.addTextField(up)
//                upField.text = up
//                upField.keyboardType = .numberPad
//                let mpField = alertView.addTextField(mp)
//                mpField.text = mp
//                mpField.keyboardType = .numberPad
//                alertView.addButton("确定") {
//                    if let rname = nameField.text , let rup = upField.text, let rmp = mpField.text {
//                        let order = password + "M" + "St" + rname
//                        let order1 = rup + "M" + "Ed" + rmp
//                        guard let characteristic = self.characteristic, let peripheral = self.peripheral else { return }
//
//                        peripheral.writeValue(BlueToothHelper.shared.dataFromString(order), for: characteristic, type: .withResponse)
//
//                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(3), execute: {
//                            peripheral.writeValue(BlueToothHelper.shared.dataFromString(order1), for: characteristic, type: .withResponse)
//                        })
//                    }
//
//                }
//                alertView.showEdit("请确认锁信息", subTitle: "依次为锁名、用户密码、管理员密码", closeButtonTitle: "取消")

            }
            
            break
        case 1005: //提交
            break
        case 1006: //扫一扫
            let viewController = ScanViewController()
            viewController.scanResultBlock = { [weak self] str in
                if let info = PeripheralInfoHelper.shared.getMap(pId: str) , let `self` = self {
                    self.currentLockInfo = info
                    self.last_lock_SSID = info["ssid"]
                    BlueToothHelper.shared.last_lock_SSID = self.last_lock_SSID
                    self.lockButton.setTitle("Lock：" + (self.currentLockInfo?["ssid"] ?? ""), for: .normal)
                    self.snButton.setTitle("SN：" + (self.currentLockInfo?["pid"] ?? ""), for: .normal)
                }
                else {
                    let alertView = SCLAlertView()
                    alertView.showInfo("该序号不存在", subTitle: "", closeButtonTitle: "取消")
                }
                
            }
            present(viewController, animated: true, completion: nil)
            break
        default:
            break
        }
        
    }
    
    @IBAction func reGetJson(_ sender: Any) {
        for button in self.buttonView.subviews {
            button.removeFromSuperview()
        }
        self.getJson()
    }
    
    
    @IBAction func changeSendType(_ sender: UIButton) {
        isBLE = !isBLE
        
        if isBLE {
            sender.setTitle("切换到HUB", for: .normal)
            saleOrMutButton.setTitle("管理鸣叫", for: .normal)
        }
        else {
            sender.setTitle("切换到蓝牙", for: .normal)
            saleOrMutButton.setTitle("静音", for: .normal)
        }
    }
    
    func findNewRCharacteristic() {
        if self.rCharacteristic != nil {
            peripheral.setNotifyValue(false, for: self.rCharacteristic!)
        }
        
        for characteristic in self.characteristics {
            if characteristic.uuid.uuidString == BlueToothHelper.shared.rCharacteristicUUIDString {
                self.rCharacteristic = characteristic
                self.recieveButton.setTitle(characteristic.uuid.uuidString, for: UIControlState())
                return
            }
        }
        self.peripheral.discoverServices(nil)
    }
    
    
    
    
    @IBAction func deleteReciveTextAction(_ sender: Any) {
        
        let alertView = SCLAlertView()
        alertView.addButton("确定") {
            self.outputTextView.text = ""
            self.outputString = ""
        }
        
        alertView.showInfo("确认删除", subTitle: "", closeButtonTitle: "取消")
        
    }
    
    
    @IBAction func saveAction(_ sender: UIButton) {
        
        guard let characteristic = self.rCharacteristic  else {
            
            return
        }
        
        if characteristic.isNotifying == false && sender.titleLabel?.text == "开始" {
            sender.setTitle("暂停", for: UIControlState())
            peripheral.setNotifyValue(true, for: characteristic)
        }
        else {
            sender.setTitle("开始", for: UIControlState())
            peripheral.setNotifyValue(false, for: characteristic)
        }
        
    }
    @IBOutlet weak var recieveButton: UIButton!
    
    @IBAction func reciveAction(_ sender: Any) {
        guard checkIsConnect() else {
            return
        }
        
        let vc = CustemChooseCharacteristicTypeTableViewController()
        vc.characteristics = characteristics
        
        vc.chooseCharacteristic = { characteristic in
            if self.rCharacteristic != nil {
                self.peripheral.setNotifyValue(false, for: self.rCharacteristic!)
            }
            self.rCharacteristic = characteristic
            BlueToothHelper.shared.rCharacteristicUUIDString = characteristic.uuid.uuidString
            self.recieveButton.setTitle(characteristic.uuid.uuidString, for: UIControlState())
            self.peripheral.setNotifyValue(true, for: self.rCharacteristic!)
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func asciiAction(_ sender: UIButton) {
        let alertVC = UIAlertController.init(title: "选择接收方式", message: "类型", preferredStyle: UIAlertControllerStyle.alert)
        
        alertVC.addAction(UIAlertAction.init(title: "Hex", style: .default, handler: { (_) in
            BlueToothHelper.shared.defaultRecivedType = .hex
            sender.setTitle("Hex", for: UIControlState())
        }))
        alertVC.addAction(UIAlertAction.init(title: "ASCII", style: .default, handler: { (_) in
            BlueToothHelper.shared.defaultRecivedType = .ascii
            sender.setTitle("ASCII", for: UIControlState())
        }))
        alertVC.addAction(UIAlertAction.init(title: "Number", style: .default, handler: { (_) in
            BlueToothHelper.shared.defaultRecivedType = .number
            sender.setTitle("Number", for: UIControlState())
        }))
        alertVC.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (_) in
            
        }))
        
        navigationController?.present(alertVC, animated: true, completion: nil)
    }
    @IBAction func makeMarkAction(_ sender: Any) {
        DispatchQueue.main.async {
            self.outputString = self.outputString + "\n-----------------------\n"
            self.outputTextViewScrollToButtom()

        }
    }
   
    @IBAction func wxShare(_ sender: Any) {
        
//        let shareParames = NSMutableDictionary()
//        shareParames.ssdkSetupShareParams(byText: self.outputTextView.text ?? "",
//                                          images : [],
//                                          url : nil,
//                                          title : self.peripheral.identifier.uuidString,
//                                          type : SSDKContentType.text)
//        ShareSDK.showShareActionSheet(view, items: [NSNumber.init(value: SSDKPlatformType.subTypeWechatSession.rawValue) , NSNumber.init(value: SSDKPlatformType.subTypeQQFriend.rawValue)], shareParams: shareParames) { (state, type, _, _, _, error) in
//
//        }
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let timeString = (BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] ?? "") + " " + formatter.string(from: date)
        
        let alertView = SCLAlertView()
        let textField = alertView.addTextField(timeString)
        textField.text = timeString
        alertView.addButton("确定") {
            
            var urls = Array<URL>()
            
            if let urlString = self.saveOutPutText(textField.text ?? timeString) {
                let url = URL.init(fileURLWithPath: urlString)
                urls.append(url)
            }
//            if let urlStringFilter = self.saveOutPutFilterText(timeString) {
//                let url = URL.init(fileURLWithPath: urlStringFilter)
//                urls.append(url)
//            }
            
            let controller = UIActivityViewController.init(activityItems: urls, applicationActivities: nil);
            
            if #available(iOS 9.0, *) {
                controller.excludedActivityTypes = [.openInIBooks , .airDrop, .postToTencentWeibo, .postToVimeo, .postToFlickr, .addToReadingList , .saveToCameraRoll, .assignToContact, .copyToPasteboard, .print, .mail, .message , .postToWeibo, .postToTwitter, .postToFacebook]
            } else {
                controller.excludedActivityTypes = [.airDrop, .postToTencentWeibo, .postToVimeo, .postToFlickr, .addToReadingList , .saveToCameraRoll, .assignToContact, .copyToPasteboard, .print, .mail, .message , .postToWeibo, .postToTwitter, .postToFacebook]
                // Fallback on earlier versions
            }
            
            self.present(controller, animated: true, completion: nil)
        }
        alertView.showEdit("请输入文件名", subTitle: "", closeButtonTitle: "取消")

    }
    @IBAction func shareReciveTextAction(_ sender: Any) {
        // 1.创建分享参数
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let timeString = (BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] ?? "") + " " + formatter.string(from: date)
        
        let alertView = SCLAlertView()
        let textField = alertView.addTextField(timeString)
        textField.text = timeString
        alertView.addButton("确定") {
            
            
            guard MFMailComposeViewController.canSendMail() else {
                let alert = SCLAlertView()
                alert.showInfo("无法发送邮件", subTitle: "请在您的手机上添加一个邮箱账户", closeButtonTitle: "确定")
                return
            }
            let picker = MFMailComposeViewController()
            picker.mailComposeDelegate = self
            
            picker.setSubject(textField.text ?? timeString)
            
            let list = ["haoyongjiang@wiparking.net"]
            
            picker.setToRecipients(list)
            
            
            if let urlString = self.saveOutPutText(textField.text ?? timeString) {
                let url = URL.init(fileURLWithPath: urlString)
                if let data = try? Data.init(contentsOf: url) {
                    picker.addAttachmentData(data, mimeType: "text/plain", fileName: (textField.text ?? timeString) + ".txt")
                }
            }
            
            
            if let filterUrlString = self.saveOutPutFilterText(textField.text ?? timeString) {
                let filterUrl = URL.init(fileURLWithPath: filterUrlString)
                if let data = try? Data.init(contentsOf: filterUrl) {
                    picker.addAttachmentData(data, mimeType: "text/plain", fileName: (textField.text ?? timeString) + "处理" + ".txt")
                }
            }
            
            
            let messageBody = "永江, 您好！\n 附件文档是APP采集的地磁数据，如有疑问，随时联系，谢谢！\n\n祝好\niOS客户端"
            
            picker.setMessageBody(messageBody, isHTML: false)
            
            self.present(picker, animated: false, completion: nil)
            


        }
        alertView.showEdit("请输入文件名", subTitle: "", closeButtonTitle: "取消")

    }

    
    func saveOutPutFilterText(_ timeString: String) -> String? {
        
        if let firstUrl = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first, let filterString = filterResultString() , filterString.count > 0 {
            
            let urlString = firstUrl + "/HistoryRecord" + "/\(timeString)处理.txt"
            if let data = filterString.data(using: .utf8, allowLossyConversion: true) {
                let url = URL.init(fileURLWithPath: urlString)
                do {
                    try data.write(to: url)
                    return urlString
                } catch {
                    return nil
                }
            }
        }
        
        return nil
        
    }
    
    func saveOutPutText(_ timeString: String) -> String? {

        if let firstUrl = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first, let localString = outputTextView.text{
            
            let urlString = firstUrl + "/HistoryRecord" + "/\(timeString).txt"
            if let data = localString.data(using: .utf8, allowLossyConversion: true) {
                let url = URL.init(fileURLWithPath: urlString)
                do {
                    try data.write(to: url)
                    return urlString
                } catch {
                    return nil
                }
            }
        }
        
        return nil
        
    }
    
    func filterResultString() -> String? {
        
        let pattern = BlueToothHelper.shared.rCharacteristicUUIDString == "FFF1" ? "q1=(-*\\d+,)q2=(-*\\d+,)" : "x=(-*\\d+,)y=(-*\\d+,)z=(-*\\d+,)"
        guard let localString = outputTextView.text, let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let res = regex.matches(in: localString, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, localString.count))
        
        var result = ""
        
        for subRes in res {
            for index in 1..<subRes.numberOfRanges {
                result += (localString as NSString).substring(with: subRes.range(at: index))
            }

            result += "\n"
        }
        return result
    }
   
    @IBAction func refreshAction(_ sender: UIButton) {
        
        if self.peripheral.state == .disconnected {
            BlueToothHelper.shared.connect(peripheral)
        }
            
        else if self.peripheral.state == .connected {
            BlueToothHelper.shared.disConnect(peripheral)
        }
    }
    
    func updateUploadButtonState() {
        uploadButton.isEnabled = selectedFirmware != nil && peripheral != nil
    }
    
    func disableOtherButtons() {
        refreshButton.isEnabled = false
        
    }
    
    func enableOtherButtons() {
        refreshButton.isEnabled = true
        
    }
    
    func openReleaseAction() {
        guard checkIsConnect() else {
            return
        }
        guard self.characteristic != nil else {
            return
        }
        
        let order = PeripheralInfoHelper.shared.getManagerPassword(self.peripheral.name!) + "MU1000000"
        
        guard let characteristic = self.characteristic, let peripheral = self.peripheral else { return }
        
        peripheral.writeValue(BlueToothHelper.shared.dataFromString(order), for: characteristic, type: .withResponse)
        
    }
    
    
    @IBAction func upLcokInfoLongPressGesture(_ sender: Any) {
        let str = "\(Date().timeIntervalSince1970)"
        
        StopHereProvider.rx.mapRequest(.uploadDNName(str, "---------")).subscribe(onSuccess: { (result) in
            SVProgressHUD.showSuccess(withStatus: "上报分割成功")
        }) { (error) in
            SVProgressHUD.showSuccess(withStatus: "上报分割失败")
            }.disposed(by: disposeBag)
    }
    
    @IBAction func uploadToServer(_ sender: Any) {
        
        if let name = BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString], name.hasPrefix("DN"), name.count >= 6 {
            
            let subname = name.subString(to: name.count - 1, length: 6)
            StopHereProvider.rx.mapRequest(.uploadDNName(name, subname)).subscribe(onSuccess: { (result) in
                SVProgressHUD.showSuccess(withStatus: "上报成功")
            }) { (error) in
                SVProgressHUD.showSuccess(withStatus: "上报失败")
            }.disposed(by: disposeBag)
        }
        else {
            SVProgressHUD.showError(withStatus: "该记录不可上报")
        }
        
    }
    
    @IBAction func downAction(_ sender: Any) {
        let viewController = DownloadFileTableViewController()
        viewController.selectAction = { [weak self] model in
            self?.fileModel = model
            FileModel.shared.fileModel = model
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    
    @IBAction func startReleaseAction(_ sender: Any) {
        handleUploadButtonTapped()
    }
    
    //MARK: - NORDFUViewController implementation
    func handleAboutButtonTapped() {
        //        self.showAbout(message: NORDFUConstantsUtility.getDFUHelpText())
        print(NORDFUConstantsUtility.getDFUHelpText())
    }
    
    func handleUploadButtonTapped() {
        
        guard dfuController != nil   else {
            self.performDFU()
            return
        }
        
        // Pause the upload process. Pausing is possible only during upload, so if the device was still connecting or sending some metadata it will continue to do so,
        // but it will pause just before seding the data.
        dfuController?.pause()
        
        let alert = UIAlertController(title: "Abort?", message: "Do you want to abort?", preferredStyle: .alert)
        let abort = UIAlertAction(title: "Abort", style: .destructive, handler: { (anAction) in
            _ = self.dfuController?.abort()
            self.clearUI()
            alert.dismiss(animated: true, completion: nil)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (anAction) in
            self.dfuController?.resume()
            alert.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(abort)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func performDFU() {
        guard selectedFirmware != nil else {
            let alert = UIAlertController.init(title: "文件未选择", message: "选择文件？", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { [weak self] (_) in
                let viewController = DownloadFileTableViewController()
                viewController.selectAction = { [weak self] model in
                    self?.fileModel = model
                    FileModel.shared.fileModel = model
                }
                self?.navigationController?.pushViewController(viewController, animated: true)
            }))
            alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (_) in
                
            }))
            present(alert, animated: true, completion: nil)
            return
        }
        
        self.openReleaseAction()
        uploadStatus.text = "打开指令发送中..."
        uploadButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0, execute: {
            self.startDFU()
        })
        
        
        
        
    }
    
    func startDFU() {
        self.disableOtherButtons()
        
        progress.isHidden = false
        uploadButton.isEnabled = false
        
        self.registerObservers()
        
        // To start the DFU operation the DFUServiceInitiator must be used
        let initiator = DFUServiceInitiator(centralManager: BlueToothHelper.shared.centralManager, target: peripheral)
        
        initiator.alternativeAdvertisingNameEnabled = true
        initiator.peripheralSelector = self
        
        initiator.logger = self
        initiator.delegate = self
        initiator.progressDelegate = self
        
        dfuController = initiator.with(firmware: selectedFirmware!).start()
        uploadButton.setTitle("取消升级", for: UIControlState())
        uploadButton.isEnabled = true
    }
    
    
    func clearUI() {
        print("------------------ clear UI ------")
        DispatchQueue.main.async {
            self.dfuController          = nil
            self.isImportingFile = false
            
            self.progress.progress      = 0.0
            self.progress.isHidden      = true
            
            self.uploadButton.setTitle("开始升级", for: .normal)
            self.updateUploadButtonState()
            self.enableOtherButtons()
            self.removeObservers()
            
            BlueToothHelper.shared.resetCenterManager()
            
            self.activityIndicatorView.startAnimating()
            self.refreshButton.setTitle("未连接", for: UIControlState())
            self.characteristics.removeAll()
            self.characteristic = nil;
            
            BlueToothHelper.shared.connect(self.peripheral)
        }
    }
    
    func registerObservers() {
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert], categories: nil))
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackgroundCallback), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActiveCallback), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        }
    }
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    @objc func applicationDidEnterBackgroundCallback() {
        if dfuController != nil {
            NORDFUConstantsUtility.showBackgroundNotification(message: "Uploading firmware...")
        }
    }
    
    @objc func applicationDidBecomeActiveCallback() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    // 把json里的button加到页面上
    func addCustomButtons() {
        
        if buttonModel.array.count < 1 {
            return
        }
        
        if buttonView.subviews.count > 0 {
            for button in buttonView.subviews {
                button.removeFromSuperview()
            }
        }
        
        var left = 2
        var top = 2
        let marginV = 2
        let marginH = 2
        let heigh = 40
        let width = (Int(UIScreen.main.bounds.size.width) - 20 - 5 * marginH) / 4
        
        for index in 0...buttonModel.array.count - 1 {
            let button = CustomButton()
            button.setInfo(info: buttonModel.array[index])
            buttonView.addSubview(button)
            button.frame = CGRect(x: left, y: top, width: width, height: heigh)
            if index > 0 && (index+1) % 4 == 0 {
                left = 2
                top += heigh + marginV
            }else{
                left += width + marginH
            }
            button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        }
    }
    
}

extension PeripheralSettingViewController : LoggerDelegate {
    func logWith(_ level: LogLevel, message: String) {
        var levelString : String?
        switch(level) {
        case .application:
            levelString = "Application"
        case .debug:
            levelString = "Debug"
        case .error:
            levelString = "Error"
        case .info:
            levelString = "Info"
        case .verbose:
            levelString = "Verbose"
        case .warning:
            levelString = "Warning"
        }
        print("\(levelString!): \(message)")
    }
    
    
}

extension PeripheralSettingViewController : DFUServiceDelegate {
    //MARK: - DFUServiceDelegate
    func dfuStateDidChange(to state: DFUState) {
        isImportingFile = true
        switch state {
        case .connecting:
            uploadStatus.text = "Connecting..."
        case .starting:
            uploadStatus.text = "Starting DFU..."
        case .enablingDfuMode:
            uploadStatus.text = "Enabling DFU Bootloader..."
        case .uploading:
            uploadStatus.text = "Uploading..."
        case .validating:
            uploadStatus.text = "Validating..."
        case .disconnecting:
            uploadStatus.text = "Disconnecting..."
        case .completed:
            NORDFUConstantsUtility.showAlert(message: "Upload complete")
            if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded() {
                NORDFUConstantsUtility.showBackgroundNotification(message: "Upload complete")
            }
            self.clearUI()
            uploadStatus.text = "Completed!"
        case .aborted:
            NORDFUConstantsUtility.showAlert(message: "Upload aborted")
            if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded(){
                NORDFUConstantsUtility.showBackgroundNotification(message: "Upload aborted")
            }
            self.clearUI()
            uploadStatus.text = "Aborted..."
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        if NORDFUConstantsUtility.isApplicationStateInactiveOrBackgrounded() {
            NORDFUConstantsUtility.showBackgroundNotification(message: message)
        }
        //        clearUI()
        DispatchQueue.main.async {
            self.uploadStatus.text = "Error: \(message)"
            self.uploadStatus.isHidden = false
            
            print(message)
        }
    }
}

extension PeripheralSettingViewController : DFUProgressDelegate {
    //MARK: - DFUProgressDelegate
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        self.progress.setProgress(Float(progress) / 100.0, animated: true)
        //        progressLabel.text = String("\(progress)% (\(part)/\(totalParts))")
    }
}

extension PeripheralSettingViewController : DFUPeripheralSelectorDelegate {
    func select(_ peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber, hint name: String?) -> Bool {
        if self.peripheral == nil {
            return false
        }
        if peripheral.name == "DfuTarg" {
            return true
        }
        return peripheral.identifier == self.peripheral.identifier
    }
    
    func filterBy(hint dfuServiceUUID: CBUUID) -> [CBUUID]? {
        print(dfuServiceUUID)
        return [dfuServiceUUID]
    }
}



extension PeripheralSettingViewController : BlueToothHelperDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService) {
        
        if peripheral == self.peripheral {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    
                    if serviceStrList.contains(characteristic.uuid.uuidString) {
                        if self.characteristics.contains(characteristic) == false {
                            self.characteristics.append(characteristic)
                        }
                        
                        if characteristic.uuid.uuidString == characteristicUUIDString  && self.characteristic == nil {
                            self.characteristic = characteristic
                
                        }
                        if characteristic.uuid.uuidString == BlueToothHelper.shared.rCharacteristicUUIDString  && self.rCharacteristic == nil {
                            self.rCharacteristic = characteristic
                            self.recieveButton.setTitle(characteristic.uuid.uuidString, for: UIControlState())
                            self.peripheral.setNotifyValue(true, for: characteristic)
                        }
                    }
                }
            }
        }
        
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, value: String) {
        if peripheral == self.peripheral , characteristic == self.rCharacteristic {
            DispatchQueue.main.async {
                self.outputString = self.outputString + value
                self.outputTextViewScrollToButtom()
                
            }
        }

    }
    
    func outputTextViewScrollToButtom() {
        
        if offsetNumber > 0 {
            return
        }
    
        self.outputTextView.text = self.outputString
        
        offsetNumber = offsetNumber + 1
        
        self.outputTextView.flashScrollIndicators()

        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.3)
            
            DispatchQueue.main.async {
                let point = CGPoint.init(x: 0, y: max(self.outputTextView.contentSize.height - self.outputTextView.bounds.size.height, 0))
                self.outputTextView.layoutManager.allowsNonContiguousLayout = false
                self.outputTextView.setContentOffset(point, animated: false)
                
                self.offsetNumber = self.offsetNumber - 1
//                print(self.offsetNumber)
            }
        }

    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func centralManagerDidConnect(_ peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            activityIndicatorView.stopAnimating()
            refreshButton.setTitle("已连接", for: UIControlState())
            if peripheral.name != BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] ,  peripheral.name != "Simple"  {
                navigationItem.leftBarButtonItems = [UIBarButtonItem.init(image: UIImage.init(named: "back"), style: .plain, target: self, action: #selector(backAction)), UIBarButtonItem.init(title: BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] ?? "", style: .plain, target: nil, action: nil)]
            }
        }
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        if peripheral.identifier.uuidString == self.peripheral.identifier.uuidString , let name = BlueToothHelper.shared.nameMap[peripheral.identifier.uuidString] {
            
            let password  = PeripheralInfoHelper.shared.getManagerPassword(name)
            
            if passwordStr != password {
                passwordStr = password
                navigationItem.leftBarButtonItems = [UIBarButtonItem.init(image: UIImage.init(named: "back"), style: .plain, target: self, action: #selector(backAction)), UIBarButtonItem.init(title:name, style: .plain, target: nil, action: nil)]
            }

        }
        
    }
    
    func centralManagerDidDisconnectPeripheral(_ peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            activityIndicatorView.startAnimating()
            refreshButton.setTitle("未连接", for: UIControlState())
            characteristics.removeAll()
            characteristic = nil;
            rCharacteristic = nil;
            BlueToothHelper.shared.connect(peripheral)
        }
    }
    
    func centralManagerDidFailToConnect(_ peripheral: CBPeripheral) {
        BlueToothHelper.shared.connect(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateElectricity electricity: Int, state: String) {
        electricityLabel.text = "电量：\(electricity)%"
        stateLabel.text = "状态：\(state)" + (state == "未知" ? "" : "度")
    }
}

extension PeripheralSettingViewController : MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate  {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
        let alertView = SCLAlertView()
        
        var text = "发送成功"
        switch result {
        case .cancelled:
            text = "用户取消"
            break
        case .saved:
            text = "已保存"
            break
        case .sent:
            text = "发送成功"
            break
        case .failed:
            text = "发送失败"
            break
        }
        alertView.showEdit(text, subTitle: "", closeButtonTitle: "确定")
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        
    }
    
}

extension PeripheralSettingViewController {
    func getJson() {
        
        let url = URL(string: "http://www.wiparking.net/appbutton/data.json")!
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
               print(error)
               return
            }
            do {
                let result = try JSONDecoder().decode(Model.self, from: data!)
                
                let deadline = (self.buttonModel == nil) ? DispatchTime.now() : DispatchTime.now() + 0.5
                
                self.buttonModel = result
                
                DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                    self.addCustomButtons()
                })
                
            } catch {
                print(error)
            }
        }
        dataTask.resume()
    }
}
