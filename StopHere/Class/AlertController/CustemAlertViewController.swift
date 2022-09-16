//
//  CustemAlertViewController.swift
//  StopHere
//
//  Created by yuszha on 2017/7/19.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit

class CustemAlertViewController: UIViewController {

    var userAction:((String) -> (Bool))?
    @IBOutlet weak var titleLabe: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var inputTF: UITextField!
    @IBAction func submitAction(_ sender: Any) {
        
        _ = self.inputTF.resignFirstResponder()
        
        guard let title = inputTF.text else {
            return
        }
        
        guard title.characters.count != 0 else {
            return
        }
        
        if userAction?(title) == true {
            view.isHidden = true
        }
    }
    @IBAction func tapAction(_ sender: Any) {
        self.view.endEditing(true)
        view.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
