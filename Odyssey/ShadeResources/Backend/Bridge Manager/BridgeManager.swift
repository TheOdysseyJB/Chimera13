//
//  BridgeManager.swift
//  Shade
//
//  Created by Amy While on 25/10/2020.
//

import Foundation

struct Bridge {
    var ip: String!
    var username: String!
    
    init(ip: String, username: String) {
        self.ip = ip
        self.username = username
    }
}

class BridgeManager {
    static let shared = BridgeManager()
    
    public var bridges = [Bridge]()
    
    public func addBridge(ip: String, username: String) {
        var bridges = UserDefaults.standard.object(forKey: "PairedBridges") as? [[String : String]] ?? [[String : String]]()
        for bridge in bridges {
            if bridge["ip"] == ip {
                return
            }
        }
        
        let newBridge: [String : String] = [
            "ip" : ip,
            "username" : username
            ]
        
        bridges.append(newBridge)
        UserDefaults.standard.setValue(bridges, forKey: "PairedBridges")
        
        self.reload()
    }
    
    init() {
        reload()
    }
    
    public func reload() {
        let bridges = UserDefaults.standard.object(forKey: "PairedBridges") as? [[String : String]] ?? [[String : String]]()
        for bridge in bridges {
            let bridgeObject = Bridge(ip: bridge["ip"]!, username: bridge["username"]!)
            self.bridges.append(bridgeObject)
        }
    }
}
