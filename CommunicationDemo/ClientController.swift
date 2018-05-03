//
//  ClientController.swift
//  CommunicationDemo
//
//  Created by zsq on 2018/4/11.
//  Copyright © 2018年 zsq. All rights reserved.
//

import UIKit

class ClientController: UIViewController {

    @IBOutlet weak var textFiled: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    let socketClient = ZSocketClient()
    var serverList = [NetService]()
    var currentServer: NetService?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clear(_ sender: UIButton) {
         textView.text = ""
    }
    @IBAction func startSearch(_ sender: Any) {
        socketClient.delegate = self
        socketClient.startSearchServer()
    }
    
    @IBAction func stopSearch(_ sender: Any) {
        socketClient.stopSearchServer()
    }
    
    @IBAction func connect(_ sender: Any) {
       if  let server = currentServer {
            socketClient.startConnect(serviece: server)
        }
    }
    
    @IBAction func disConnect(_ sender: Any) {
        socketClient.closeConnect()
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        socketClient.sendMessage(msg: textFiled.text!)
    }
}
extension ClientController: ZSocketClientDelegate {
    func updateServiceList(list: [NetService]) {
        serverList = list
        tableView.reloadData()
    }
    
    func receivedNewMessage(message: String) {
        let string = textView.text + "\n" + message
        textView.text = string
    }
}

extension ClientController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serverList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
               cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
        }
        let server = serverList[indexPath.row]
        cell?.textLabel?.text = server.name
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let server = serverList[indexPath.row]
        currentServer = server
        
    }
}

