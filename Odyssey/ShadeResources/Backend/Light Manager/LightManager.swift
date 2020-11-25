//
//  LightManager.swift
//  Shade
//
//  Created by Amy While on 25/10/2020.
//

import Foundation
import UIKit

enum Context {
    case brightness
    case toggle
    case colour
    case colourLoop
}

enum Effect {
    case colorloop
    case other
}

struct Light {
    var id: String?
    var state: LightState?
    var type: String?
    var uniqueid: String?
    var name: String?
    var ip: String?
    var username: String?
    
    init(id: String?, state: LightState?, type: String?, uniqueid: String, name: String?, ip: String?, username: String?) {
        self.id = id
        self.state = state
        self.type = type
        self.uniqueid = uniqueid
        self.name = name
        self.ip = ip
        self.username = username
    }
}

struct LightState {
    var on: Bool?
    var bri: Int?
    var hue: Int?
    var sat: Int?
    var xy: (Float, Float)?
    var ct: Int?
    var reachable: Bool?
    var effect: Effect?
    
    init(on: Bool?, bri: Int?, hue: Int?, sat: Int?, xy: (Float, Float)?, ct: Int?, reachable: Bool?, effect: Effect?) {
        self.on = on
        self.bri = bri
        self.hue = hue
        self.sat = sat
        self.xy = xy
        self.ct = ct
        self.reachable = reachable
        self.effect = effect
    }
}

class LightManager {
    
    static let shared = LightManager()
    var lights = [Light]()
    var timer: Timer?
  
    @objc public func grabLightsFromBridge() {
        for bridge in BridgeManager.shared.bridges {
            if let url = URL(string: "http://\(bridge.ip!)/api/\(bridge.username!)/lights") {
                NetworkManager.shared.requestWithDict(url: url, method: "GET", headers: nil, jsonbody: nil, completion: { (success, dict) -> Void in
                    if success {
                        for (id, uwu) in dict {
                            if let light = uwu as? [String : Any] {
                                let type = light["type"] as? String ?? "Error"
                                let name = light["name"] as? String ?? "Error"
                                let uniqueID = light["uniqueid"] as? String ?? "Error"
                                
                                let state = light["state"] as! [String : Any]
                                let bri = state["bri"] as! Int
                                let ct = state["ct"] as! Int
                                let hue = state["hue"] as! Int
                                let sat = state["sat"] as! Int
                                let on = state["on"] as! Bool
                                let reachable = state["reachable"] as! Bool
                                
                                var setEffect: Effect!
                                let effect = state["effect"] as! String
                                if effect == "colorloop" {
                                    setEffect = .colorloop
                                } else {
                                    setEffect = .other
                                }
                                
                                let x = Float(truncating: (state["xy"] as! [NSNumber])[0])
                                let y = Float(truncating: (state["xy"] as! [NSNumber])[1])
                                let lightState = LightState(on: on, bri: bri, hue: hue, sat: sat, xy: (x, y), ct: ct, reachable: reachable, effect: setEffect)
                                
                                let light = Light(id: id, state: lightState, type: type, uniqueid: uniqueID, name: name, ip: bridge.ip!, username: bridge.username!)
                                
                                var found = false
                                for (index, uwu) in self.lights.enumerated() {
                                    if uwu.uniqueid == light.uniqueid {
                                        found = true
                                        self.lights[index] = light
                                    }
                                }
                                
                                if !found {
                                    self.lights.append(light)
                                }
                                
                            }
                        }
                        print("[i] Refreshed light cache, \(self.lights.count) in memory")
                        NotificationCenter.default.post(name: .LightRefactor, object: nil)
                    } else {
                        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.grabLightsFromBridge), userInfo: nil, repeats: false)
                    }
                })
            }
        }
    }
    
    private func sendCommand(_ light: Light, _ command: String, _ context: Context) {
        if let url = URL(string: "http://\(light.ip!)/api/\(light.username!)/lights/\(light.id!)/state") {
            NetworkManager.shared.request(url: url, method: "PUT", headers: nil, jsonbody: command, completion: { (success, dict) -> Void in
                DispatchQueue.main.async {
                    let generator = UINotificationFeedbackGenerator()

                    if success {
                        if dict.count == 0 { generator.notificationOccurred(.error); return }
                        
                        for response in dict {
                            if (response["success"] as? [String : Any]) != nil {
                                //self.grabLightsFromBridge()
                                //This isn't needed here
                            } else {
                                generator.notificationOccurred(.error); return
                            }
                        }
                        
                        if context != .brightness { generator.notificationOccurred(.success) }
                        NotificationCenter.default.post(name: .LightRefactor, object: nil)
                    } else {
                        generator.notificationOccurred(.error)
                    }
                }
            })
        }
    }
    
    public func getIndex(_ id: String) -> Int {
        for (index, light2) in self.lights.enumerated() {
            if light2.id == id {
                return index
            }
        }
        
        return -1
    }
    
    public func toggle(_ light: Light) {
        let body: String!
        if light.state!.on! {
            body = "{\"on\":false}"
        } else {
            body = "{\"on\":true}"
        }
        
        self.sendCommand(light, body, .toggle)
    }
    
    public func setColour(_ light: Light, _ colour: UIColor, _ bri: Int) {
        let hueColours = colour.hueColours
        let hue = hueColours.h; let sat = hueColours.s
        let body = "{\"effect\":\"none\", \"on\":true, \"sat\":\(sat), \"hue\":\(hue), \"bri\":\(bri)}"
        
        self.sendCommand(light, body, .brightness)
    }
    
    public func setBrightness(_ light: Light, _ brightness: Int) {
        let shouldBeOn = !(brightness == 0)
        let body = "{\"on\":\(shouldBeOn), \"bri\":\(brightness)}"
        
        self.sendCommand(light, body, .brightness)
    }
    
    public func setLoop(_ light: Light) {
        let currentEffect = light.state!.effect!
        let body: String!
        switch currentEffect {
        case .colorloop: body = "{\"on\":true, \"effect\":\"none\"}"
        case .other: body = "{\"on\":true, \"effect\":\"colorloop\"}"
        }

        self.sendCommand(light, body, .colourLoop)
    }
    
    public func restoreState(_ light: Light) {
        let state = light.state!
        let on = (state.on! ? "true" : "false")
        let body = "{\"effect\":\"none\", \"on\":\(on), \"stat\":\(state.sat!), \"hue\":\(state.hue!), \"bri\":\(state.bri!)}"
        self.sendCommand(light, body, .brightness)
    }
}
