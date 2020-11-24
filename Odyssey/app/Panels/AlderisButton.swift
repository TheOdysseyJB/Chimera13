//
//  AlderisButton.swift
//  Odyssey
//
//  Created by Amy While on 06/09/2020.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class AlderisButton: UIControl {
    static let showAlderisName = NSNotification.Name("ShowAlderisPicker")
    
    @IBInspectable var defaultKey: String = ""
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
                
        self.addTarget(self, action: #selector(AlderisButton.showAlderisPicker), for: .touchUpInside)
    }
    
    @objc func showAlderisPicker() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: AlderisButton.self.showAlderisName.rawValue), object: nil, userInfo: ["default": defaultKey])
    }
}

 


