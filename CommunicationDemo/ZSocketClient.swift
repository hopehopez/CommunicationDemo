//
//  ZSocketClient.swift
//  CommunicationDemo
//
//  Created by zsq on 2018/4/10.
//  Copyright © 2018年 zsq. All rights reserved.
//

import UIKit

protocol  ZSocketClientDelegate: NSObjectProtocol{
    func updateServiceList(list: [NetService])
    func receivedNewMessage(message: String)
}

class ZSocketClient: NSObject {
    
    var boujourBrowser: NetServiceBrowser?
    var boujourServices = [NetService]()
    weak var delegate: ZSocketClientDelegate?
    let port: Int32 = 9002
    override init() {
        super.init()
    }
    
    func startSearchServer() {
        let browser = NetServiceBrowser.init()
        browser.delegate = self
        browser.searchForServices(ofType: "_JYQJ._tcp.", inDomain: "")
        boujourBrowser = browser
    }
    
    func startConnect(serviece: NetService) {
        NotificationCenter.default.addObserver(self, selector: #selector(SRWebSocketDidOpen), name: Notification.Name.init(kWebSocketDidOpenNote), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SRWebSocketDidReceiveMsg(noti:)), name: Notification.Name.init(kWebSocketdidReceiveMessageNote), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WebSocketDidCloseNote), name: Notification.Name.init(kWebSocketDidCloseNote), object: nil)
        
        serviece.delegate = self
        serviece.resolve(withTimeout: 1)
    }
    
    func stopSearchServer()  {
        boujourBrowser?.stop()
        boujourServices.removeAll()
        delegate?.updateServiceList(list: boujourServices)
    }
    
    func closeConnect() {
        
        SocketRocketUtility.instance().srWebSocketClose()
        
    }
    
    func sendMessage(msg: String) {
        SocketRocketUtility.instance().sendData(msg)
    }
    
    
    func SRWebSocketDidOpen() {
        print("socketClient 开启")
        //个人信息
        let dict = ["header":
            ["packet_type": "S2T_1",
             "desc": "用户信息",
             "sender": BonjorConfig.shared().clientMobile,
             "client_type": "iOS"
            ],
                    "data":
                        ["name":  BonjorConfig.shared().clientName,
                         "icon": "",
                         "mobile": BonjorConfig.shared().clientMobile
            ]
        ]
        do {
             let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
             let str = String.init(data: data, encoding: String.Encoding.utf8) ?? ""
            SocketRocketUtility.instance().sendData(str)
        } catch {
            
        }
       
       
        
    }
    
    func WebSocketDidCloseNote() {
        print("sockerClient 关闭")
    }
    
    func SRWebSocketDidReceiveMsg(noti: Notification){
        let message = noti.object as? String ?? ""
        delegate?.receivedNewMessage(message: message)
        print("client receive:" + message)
    }
}

extension ZSocketClient: NetServiceBrowserDelegate {
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser){
        print("开始查找bonjour服务")
    }
    
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser){
        print("停止查找bonjour服务")
        closeConnect()
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]){
        print("查找bongjour服务失败: ", errorDict)
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool){
        let name = service.name
        let items = name.components(separatedBy: "_")
        if items[0] == "jyqf" {
            var flag = false
            for ser in boujourServices {
                if ser.name == service.name {
                    flag = true
                    break
                }
            }
            if flag == false {
                print("发现Bonjour服务: \(service.name)")
                boujourServices.append(service)
                delegate?.updateServiceList(list: boujourServices)
            }
        }
        
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool){
        
        if let index = boujourServices.index(of: service) {
            boujourServices.remove(at: index)
        }
        
        if moreComing {
            return
        }
        
        delegate?.updateServiceList(list: boujourServices)
    }
}

extension ZSocketClient: NetServiceDelegate{
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("netServiceDidResolveAddress get called with \(sender).")
        
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        
        guard let data = sender.addresses?.first else {
            print("guard let data failed")
            return
        }
        do {
            try data.withUnsafeBytes { (pointer:UnsafePointer<sockaddr>) -> Void in
                guard getnameinfo(pointer, socklen_t(data.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                    throw NSError(domain: "domain", code: 0, userInfo: ["error":"unable to get ip address"])
                }
            }
        } catch {
            print(error)
            return
        }
        let address = String(cString:hostname)
        print("Adress:", address)
        
        let url = "ws://\(address):\(sender.port)"
//         let url = "ws://\(address):9002"
        SocketRocketUtility.instance().srWebSocketOpen(withURLString: url)
        
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]){
        print(errorDict)
    }
}
