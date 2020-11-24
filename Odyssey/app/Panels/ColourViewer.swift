//
//  ColourViewer.swift
//  Odyssey
//
//  Created by Amy While on 07/09/2020.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class ColourViewer: UIView {
    
    @IBInspectable private var defaultKey: String = ""
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
                
        self.clipsToBounds = true
        self.layer.cornerRadius = 5
                
        NotificationCenter.default.addObserver(self, selector: #selector(setColour), name: ThemesManager.themeChangeNotification, object: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setColour()
    }
    
    @objc private func setColour() {
        self.backgroundColor = UserDefaults.standard.color(forKey: defaultKey) ?? .gray
    }
}
