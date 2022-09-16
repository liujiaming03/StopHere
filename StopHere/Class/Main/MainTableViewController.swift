//
//  MainTableViewController.swift
//  StopHere
//
//  Created by yuszha on 2017/7/19.
//  Copyright © 2017年 yuszha. All rights reserved.
//

import UIKit
import CoreBluetooth
import MJRefresh

class MainTableViewController: UITableViewController {
    
//    var storeHouseRefreshControl : CBStoreHouseRefreshControl?
    var buttonModel: Model? = nil
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        custemImageTitle()
        
        BlueToothHelper.shared.addDelegate(self)
        BlueToothHelper.shared.discoverPeripherals()
        
        tableView.register(UINib.init(nibName: "MainTableViewCell", bundle: nil), forCellReuseIdentifier: "MainTableViewCell")
        tableView.tableFooterView = UIView()
        
//        automaticallyAdjustsScrollViewInsets = true
    
//        storeHouseRefreshControl =  CBStoreHouseRefreshControl.attach(to: tableView, target: self, refreshAction: #selector(MainTableViewController.refreshAction as (MainTableViewController) -> () -> ()), plist: "storehouse", color: .black, lineWidth: 1.5, dropHeight: 80, scale: 1, horizontalRandomness: 150, reverseLoadingAnimation: true, internalAnimationFactor: 0.5)
        
        tableView.mj_header = MJRefreshStateHeader.init(refreshingTarget: self, refreshingAction: #selector(MainTableViewController.refreshAction as (MainTableViewController) -> () -> ()))

    }
    
    @objc func refreshAction() {
        BlueToothHelper.shared.reDiscoverPeripherals()
//        storeHouseRefreshControl?.finishingLoading()
        tableView.mj_header?.endRefreshing()
        activityIndicatorView.startAnimating()
        refreshButton.setTitle("停止", for: UIControlState())
    }
    
    
    deinit {
        BlueToothHelper.shared.removeDelegate(self)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        BlueToothHelper.shared.readRSSI(stop: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        BlueToothHelper.shared.readRSSI(stop: true)
    }
    
    @IBAction func refreshAction(_ sender: UIButton) {
        if sender.titleLabel?.text == "停止" {
            activityIndicatorView.stopAnimating()
            sender.setTitle("刷新", for: UIControlState())
            BlueToothHelper.shared.stopDiscoverPeripherals()
        }
        else {
            activityIndicatorView.startAnimating()
            sender.setTitle("停止", for: UIControlState())
            BlueToothHelper.shared.discoverPeripherals()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return BlueToothHelper.shared.peripherals.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell") as! MainTableViewCell
        
        if indexPath.row < BlueToothHelper.shared.peripherals.count {
            let peripheral = BlueToothHelper.shared.peripherals[indexPath.row]
            cell.peripheral = peripheral
        }
        
        // Configure the cell...

        return cell
    }
 
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let vc = PeripheralSettingViewController()
        
        let peripheral = BlueToothHelper.shared.peripherals[indexPath.row]
//        BlueToothHelper.shared.stopDiscoverPeripherals()
        BlueToothHelper.shared.connect(peripheral)
        
        vc.peripheral = peripheral
        vc.hidesBottomBarWhenPushed = true
                
        navigationController?.pushViewController(vc, animated: true)
        
        
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MainTableViewController {
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        storeHouseRefreshControl?.scrollViewDidScroll()
//    }
//
//    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        storeHouseRefreshControl?.scrollViewDidEndDragging()
//    }
}

extension MainTableViewController : BlueToothHelperDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    
    }
    
    func discoverPeripheral(_ helper: BlueToothHelper) {
        self.tableView.reloadData()
    }
}
