//
//  AppDelegate.swift
//  StopHere
//
//  Created by yuszha on 2017/7/19.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import BuglyHotfix


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        IQKeyboardManager.shared.enable = true
        setupShareSDK()
        configBugly()
//        PeripheralInfoHelper.shared.configureLocalInfo()
        
        let fileManager = FileManager()
        
        if let firstUrl = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first {
            let historyRecord = firstUrl + "/HistoryRecord"
            try? fileManager.createDirectory(atPath: historyRecord, withIntermediateDirectories: true, attributes: nil)
            if let paths = fileManager.subpaths(atPath: historyRecord) {
                for path in paths {
                    try? fileManager.removeItem(at: URL.init(fileURLWithPath: historyRecord + "/" + path))
                }
            }
            
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = LoginViewController()
        if #available(iOS 13.0, *) {
            UIApplication.shared.statusBarStyle = UIStatusBarStyle.darkContent
        } else {
            // Fallback on earlier versions
        };
        UINavigationBar.appearance().barTintColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1)
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func setupShareSDK() {
        /**
         *  设置ShareSDK的appKey，如果尚未在ShareSDK官网注册过App，请移步到http://mob.com/login 登录后台进行应用注册，
         *  在将生成的AppKey传入到此方法中。我们Demo提供的appKey为内部测试使用，可能会修改配置信息，请不要使用。
         *  方法中的第二个参数用于指定要使用哪些社交平台，以数组形式传入。第三个参数为需要连接社交平台SDK时触发，
         *  在此事件中写入连接代码。第四个参数则为配置本地社交平台时触发，根据返回的平台类型来配置平台信息。
         *  如果您使用的时服务端托管平台信息时，第二、四项参数可以传入nil，第三项参数则根据服务端托管平台来决定要连接的社交SDK。
         */
        
        ShareSDK.registerActivePlatforms( [], onImport: { (platform : SSDKPlatformType) in

        }) { (platform : SSDKPlatformType, appInfo : NSMutableDictionary?) in

        };
        ShareSDK.registerActivePlatforms(
            [
                SSDKPlatformType.typeWechat.rawValue,
                SSDKPlatformType.typeQQ.rawValue,
            ],
            // onImport 里的代码,需要连接社交平台SDK时触发
            onImport: {(platform : SSDKPlatformType) -> Void in
                switch platform
                {
                case SSDKPlatformType.typeWechat:
                    ShareSDKConnector.connectWeChat(WXApi.classForCoder())
                case SSDKPlatformType.typeQQ:
                    ShareSDKConnector.connectQQ(QQApiInterface.classForCoder(), tencentOAuthClass: TencentOAuth.classForCoder())
                default:
                    break
                }
        },
            onConfiguration: {(platform : SSDKPlatformType , appInfo : NSMutableDictionary?) -> Void in
                switch platform
                {

                case SSDKPlatformType.typeWechat:
                    //设置微信应用信息
                    appInfo?.ssdkSetupWeChat(byAppId: "wx99597cb1494f184e",
                                             appSecret: "270fb60875b594a7a5bef2d48eb14101")
                case SSDKPlatformType.typeQQ:
                    //设置QQ应用信息
                    appInfo?.ssdkSetupQQ(byAppId: "1105814166",
                                         appKey: "l1lXNh8L37BoqpPV",
                                         authType: SSDKAuthTypeBoth)


                default:
                    break
                }
        })
    }
    
    private func configBugly() {
        let buglyConfig = BuglyConfig()
        buglyConfig.debugMode = true
        buglyConfig.reportLogLevel = .info
        Bugly.start(withAppId: "45b218052a",config:buglyConfig)
        
        JPEngine.handleException { (msg) in
            let exception = NSException(name: NSExceptionName(rawValue: "Hotfix Exception"), reason: msg, userInfo: nil)
            Bugly.report(exception)
        }
        
        
        BuglyMender.shared().checkRemoteConfig { (event:BuglyHotfixEvent, info:[AnyHashable : Any]?) in
            if (event == BuglyHotfixEvent.patchValid || event == BuglyHotfixEvent.newPatch) {
                let patchDirectory = BuglyMender.shared().patchDirectory() as NSString
                let patchFileName = "main.js"
                let patchFilePath = patchDirectory.appendingPathComponent(patchFileName)
                if let str = try? String.init(contentsOfFile: patchFilePath) {
                    print(str)
                }
                if (FileManager.default.fileExists(atPath: patchFilePath) && JPEngine.evaluateScript(withPath: patchFilePath) != nil) {
                    BuglyLog.level(.info, logs: "evaluateScript success")
                    BuglyMender.shared().report(.activeSucess)
                }else {
                    BuglyLog.level(.error, logs: "evaluateScript fail")
                    BuglyMender.shared().report(.activeFail)
                }
                
            }
            self.updateNewVersion()
        }
        
    }
    
    func updateNewVersion() {
        
        let infoDictionary = Bundle.main.infoDictionary
        if let app_version = infoDictionary?["CFBundleShortVersionString"] as? String {
            let version = self.checkVersion()
            if version != app_version {
                let alert = UIAlertController.init(title: "有新的版本，请升级", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "升级", style: .default, handler: { [weak self] (sender) in
                    if let str = self?.newVersionAddress(), str.count > 0, let url = URL.init(string: str) {
                        UIApplication.shared.openURL(url)
                    }
                }))
                alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (sender) in
                    
                }))
                DispatchQueue.main.async { [weak self] in
                    while true {
                        Thread.sleep(forTimeInterval: 3.0)
                        if let rootViewController = self?.window?.rootViewController {
                            rootViewController.present(alert, animated: true, completion: nil)
                            break
                        }
                        
                    }
                }
            }
        }
        
        
    }
    
    @objc dynamic func newVersionAddress() -> String {
        return "";
    }
    
    @objc dynamic func checkVersion() -> String {
        let infoDictionary = Bundle.main.infoDictionary
        return (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "";
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
    


}

