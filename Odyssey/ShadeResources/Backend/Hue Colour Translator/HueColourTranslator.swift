//
//  HueColourTranslator.swift
//  Shade
//
//  Created by Amy While on 26/10/2020.
//

import UIKit

class HueColourTranslator {
    static let shared = HueColourTranslator()

    public func convertFromHue(_ light: LightState!) -> UIColor {
        let hue: CGFloat = CGFloat(CGFloat(light.hue!) / CGFloat(65535))
        let sat: CGFloat = CGFloat(CGFloat(light.sat!) / CGFloat(254))
  
        let colour = UIColor(hue: hue, saturation: sat, brightness: 1.0, alpha: 1.0)
        return colour
    }
    
}
