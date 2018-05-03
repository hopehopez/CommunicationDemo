//
//  BonjorConfig.swift
//  CommunicationDemo
//
//  Created by zsq on 2018/4/11.
//  Copyright © 2018年 zsq. All rights reserved.
//

import UIKit
private let config = BonjorConfig()
public class BonjorConfig: NSObject {

   public var serverMobile = "12345678"
   public var serverName = "发起者"
    
   public var clientMobile = "666666"
   public var clientName = "小明"
    
    public class  func shared() -> BonjorConfig {
        return config
    }
}
