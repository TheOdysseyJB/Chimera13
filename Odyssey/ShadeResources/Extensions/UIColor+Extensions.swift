//
//  UIColor+Extensions.swift
//  Shade
//
//  Created by Amy While on 26/10/2020.
//

import UIKit

extension UIColor {
    var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h: h, s: s, b: b, a: a)
    }
    
    var hueColours: (h: Int, s: Int) {
        let hsba = self.hsba
        
        let hue = Int(hsba.h * 65535)
        let sat = Int(hsba.s * 254)
  
        return (hue, sat)
    }
 }
