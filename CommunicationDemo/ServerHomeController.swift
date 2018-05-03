//
//  ServerHomeController.swift
//  CommunicationDemo
//
//  Created by zsq on 2018/4/11.
//  Copyright © 2018年 zsq. All rights reserved.
//

import UIKit

class ServerHomeController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func mobileChange(_ sender: UITextField) {
        BonjorConfig.shared().serverMobile = sender.text!
    }
    
    @IBAction func nameChange(_ sender: UITextField) {
        BonjorConfig.shared().serverName = sender.text!
    }
    

}
