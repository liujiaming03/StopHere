//
//  CustemChooseServiceViewController.swift
//  StopHere
//
//  Created by yuszha on 2017/7/20.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import CoreBluetooth
import RxSwift
import RxCocoa

class CustemChooseServiceViewController: UIViewController {

    @IBOutlet weak var custemView: UIView!
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var buttonsBackgroundView: UIView!
    var characteristics : [CBCharacteristic]! {
        didSet {
            let number = (characteristics.count + 1) / 2
            viewHeight.constant = CGFloat(number) * 40.0 + 60.0
            addButtons()
        }
    }
    
    let disposeBag = DisposeBag()
    
    var chooseCharacteristic : ((CBCharacteristic) -> (Void))?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func addButtons() {
        
        for view in buttonsBackgroundView.subviews {
            view.removeFromSuperview()
        }
        
        var isLeft = true
        var y = 10.0
        for characteristic in characteristics {
            let button = UIButton()
            button.setTitle(characteristic.uuid.uuidString, for: UIControlState())
            button.setTitleColor(.black, for: UIControlState())
            button.rx.tap.subscribe(onNext: { (_) in
                self.chooseCharacteristic?(characteristic)
                self.view.isHidden = true
            }).addDisposableTo(disposeBag)
            if isLeft {
                button.frame = CGRect.init(x: 20, y: y, width: 90.0, height: 30.0)
            }
            else {
                button.frame = CGRect.init(x: 130, y: y, width: 90.0, height: 30.0)
                y += 40.0
            }
            isLeft = !isLeft
            
            button.layer.borderColor = UIColor.lightGray.cgColor

            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 3.0
            buttonsBackgroundView.addSubview(button)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapAction(_ sender: Any) {
        self.view.endEditing(true)
        view.isHidden = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
