//
//  ServerController.swift
//  CommunicationDemo
//
//  Created by zsq on 2018/4/11.
//  Copyright © 2018年 zsq. All rights reserved.
//

import UIKit

class ServerController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var textView: UITextView!
    
    var userList = [ERConnectedUserModel]()
    
    var server: ZSocketServer = ZSocketServer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func clear(_ sender: Any) {
        textView.text = ""
    }
    @IBAction func startServer(_ sender: Any) {
        server.delegate = self
        server.startServer(name: "jyqf_\(BonjorConfig.shared().serverMobile)_\(BonjorConfig.shared().serverName)")
    }
    
    @IBAction func stopServer(_ sender: Any) {
        
        server.stopServer()
        server.delegate = nil
    }
    
    
    @IBAction func sendMessage(_ sender: Any) {
        server.send(message: textField.text!)
    }
    
}

extension ServerController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
        }
        let user = userList[indexPath.row]
        cell?.textLabel?.text = user.name
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
extension ServerController: ZSocketServerDelegate {
    func serverReceive(message: String) {
        let str = textView.text + "\n" + message
        textView.text = str
    }
    
    func serverConnectUpdate(list: [ERConnectedUserModel]) {
        userList = list
        tableView.reloadData()
    }
    
    
}
