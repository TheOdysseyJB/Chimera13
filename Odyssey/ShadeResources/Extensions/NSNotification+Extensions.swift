//
//  NSNotification+Extensions.swift
//  Shade
//
//  Created by Amy While on 26/10/2020.
//

import Foundation

extension NSNotification.Name {
    static let LightRefactor = Notification.Name("Shade.LightRefactor")
    static let HidePopup = Notification.Name("Shade.HidePopup")
    static let ShowColourPicker = Notification.Name("Shade.ShowColourPicker")
    static let BrightnessChanged = Notification.Name("Shade.BrightnessChanged")
    static let HideHomeWelcome = Notification.Name("Shade.HideHomeWelcome")
}
