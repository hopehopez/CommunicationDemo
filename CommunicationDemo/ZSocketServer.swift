//
//  ZSocketServer.swift
//  CommunicationDemo
//
//  Created by zsq on 2018/4/10.
//  Copyright © 2018年 zsq. All rights reserved.
//

import UIKit
import SwiftyJSON
protocol ZSocketServerDelegate: NSObjectProtocol {
    func serverReceive(message: String)
    func serverConnectUpdate(list: [ERConnectedUserModel])
}

class ZSocketServer: NSObject {
    
    var netService: NetService?
    var socketServer: PSWebSocketServer?
    var serviceName: String!
    let port: Int32 = 9002
    var socketDict = [String : PSWebSocket]()
    weak var delegate: ZSocketServerDelegate?
    var users = [ERConnectedUserModel]()
    var socketList = [PSWebSocket]()
    override init() {
        super.init()
    }
    
    func startServer(name: String)  {
        startBonjourService(name: name)
    }
    
    func stopServer() {
        users.removeAll()
        socketDict.removeAll()
        delegate?.serverConnectUpdate(list: users)
        stopBonjourService()
    }
    
    func send(message: String) {
//        for socket in socketDict.values {
//            socket.send(message)
//            print("socketServer send: \(message)")
//        }
        
        socketList.map { (webSocket: PSWebSocket)  in
            webSocket.send(message)
        }
    }
    
    //MAKR: - Boujour 部分
    fileprivate func startBonjourService(name: String) {
        let service = NetService.init(domain: "local.", type: "_JYQJ._tcp.", name: name, port: port)
        
        service.schedule(in: RunLoop.current, forMode: .commonModes)
        service.delegate = self
        service.publish()
        netService = service
    }
    
    fileprivate func stopBonjourService() {
        netService?.stop()
        netService = nil
    }
    
    //MAKR: - websocket 部分
    fileprivate func startScoketServer() {
        if let ip = getLocalIPAddressForCurrentWiFi() {
            let server = PSWebSocketServer.init(host: ip, port: UInt(port))!
            server.delegate = self
            socketServer = server
            server.start()
        } else {
            print("ip 获取失败")
        }
    }
    
    fileprivate func stopSocekServer(){
        socketServer?.stop()
        
    }
    
    
    
    // 获取当前wifi的IP地址
    fileprivate func getLocalIPAddressForCurrentWiFi() -> String? {
        var address: String?
        
        // get list of all interfaces on the local machine
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        guard let firstAddr = ifaddr else {
            return nil
        }
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            
            let interface = ifptr.pointee
            
            // Check for IPV4 or IPV6 interface
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                // Check interface name
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    
                    // Convert interface address to a human readable string
                    var addr = interface.ifa_addr.pointee
                    var hostName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostName, socklen_t(hostName.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostName)
                }
            }
        }
        print("ip: " , address ?? "0.0.0.0")
        freeifaddrs(ifaddr)
        return address
    }
    
}
extension ZSocketServer: NetServiceDelegate {
    
    public func netServiceDidPublish(_ sender: NetService){
        print("bongjour服务发布成功:" + sender.name)
        startScoketServer()
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]){
        print("bongjour服务发布失败: ", errorDict)
        
    }
    
    public func netServiceDidStop(_ sender: NetService) {
        print("bongjour服务关闭:" + sender.name)
        stopSocekServer()
    }
    
}

extension ZSocketServer: PSWebSocketServerDelegate {
    
    func serverDidStart(_ server: PSWebSocketServer!) {
        print("socketServer 启动成功")
    }
    
    func server(_ server: PSWebSocketServer!, didFailWithError error: Error!) {
        print("socketServer 启动失败: \(error)")
    }
    
    func serverDidStop(_ server: PSWebSocketServer!) {
        print("socketServer 停止服务")
    }
    
    func server(_ server: PSWebSocketServer!, webSocketDidOpen webSocket: PSWebSocket!) {
        socketList.append(webSocket)
    }
    
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didReceiveMessage message: Any!) {
        let string = message as! String
        delegate?.serverReceive(message: string)
        let data = string.data(using: String.Encoding.utf8)
        var dict: Dictionary<String, Any>?
        do {
            dict = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Dictionary<String, Any>
        } catch {
            
            return
        }
        
        if let dic = dict {
            let json = JSON(dic)
            let type = json["header"]["packet_type"].stringValue
            if type == "S2T_1" {
                
                let mobile = json["header"]["sender"].stringValue
                for user in users {
                    if mobile == user.mobile {
                        return
                    }
                }
                
                let user = ERConnectedUserModel()
                user.icon = json["data"]["icon"].stringValue
                user.name = json["data"]["name"].stringValue
                user.mobile = mobile
                user.timeStamp = Date().timeIntervalSince1970
                users.append(user)
                delegate?.serverConnectUpdate(list: users)
                socketDict[mobile] = webSocket
                delegate?.serverReceive(message: string)
            } else if type == "S2T_2" { //心跳
                let mobile = json["header"]["sender"].stringValue
                for user in users {
                    if mobile == user.mobile {
                        user.timeStamp = Date().timeIntervalSince1970
                    }
                }
            } else {
//                  delegate?.serverReceive(message: string)
                print(message)
            }
        } else {
//              delegate?.serverReceive(message: string)
            print(message)
        }
        
    }
    
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didFailWithError error: Error!) {
        print("建立socket连接失败: \(webSocket), \(error)")
    }
    
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("关闭socket连接")
        
        if let index  = socketList.index(of: webSocket) {
            socketList.remove(at: index)
        }
        
        for (key, value) in socketDict {
            if value == webSocket {
                socketDict.removeValue(forKey: key)
                for user in users {
                    if user.mobile == key {
                        let index = users.index(of: user)
                        users.remove(at: index!)
                        break
                    }
                }
                delegate?.serverConnectUpdate(list: users)
                break
            }
            
        }
        
    }
}
