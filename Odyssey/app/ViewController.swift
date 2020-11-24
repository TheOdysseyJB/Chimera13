//
//  ViewController.swift
//  Electra13
//
//  Created by CoolStar on 3/1/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit
import MachO.dyld_images

class ViewController: UIViewController, ElectraUI {

    var electra: Electra?
    var allProc = UInt64(0)
        
    fileprivate var scrollAnimationClosures: [() -> Void] = []
    private var popClosure: DispatchWorkItem?
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var backgroundOverlay: UIView!
    
    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var jailbreakButton: UIButton?
    @IBOutlet weak var progressRing: UICircularProgressRing!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var vibrancyView: UIVisualEffectView!
    @IBOutlet weak var updateOdysseyView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var switchesView: PanelStackView!
    
    @IBOutlet weak var themeCopyrightButton: UIButton!
    
    @IBOutlet weak var enableTweaksSwitch: UISwitch!
    @IBOutlet weak var restoreRootfsSwitch: UISwitch!
    @IBOutlet weak var logSwitch: UISwitch!
    @IBOutlet weak var nonceSetter: TextButton!
    
    @IBOutlet weak var containerViewYConstraint: NSLayoutConstraint!
    @IBOutlet weak var jailbreakButtonHeightConstraint: NSLayoutConstraint!
    
    var themeImagePicker: ThemeImagePicker!
    
    var activeColourDefault = ""
    let colorPickerViewController = ColorPickerViewController()
    
    private var currentView: (UIView & PanelView)?

    override func viewDidLoad() {
        super.viewDidLoad()

        //This will reset user defaults, used it a lot for testing
        /*
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        */
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showAlderisPicker(_:)), name: AlderisButton.showAlderisName, object: nil)
        colorPickerViewController.delegate = self
 
        if self.view.bounds.height <= 667 {
            stackView.spacing = 40
            if self.view.bounds.height <= 568 {
                stackView.spacing = 20
                self.containerView.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
                self.jailbreakButtonHeightConstraint.constant = 125
            }
        }
        
        currentView = switchesView
        nonceSetter.delegate = NonceManager.shared
        
        var formatter = UICircularProgressRingFormatter()
        formatter.showValueInteger = false
        formatter.valueIndicator = "Jailbreak"
        
        if #available(iOS 13.5.1, *) {
            jailbreakButton?.isEnabled = false
            formatter.valueIndicator = "Unsupported"
            if let allProcStr = UIPasteboard.general.string {
                let prefix = "allproc: "
                if allProcStr.hasPrefix(prefix) {
                    let allProcHex = String(allProcStr.dropFirst(prefix.count + 2))
                    if let allProc = UInt64(allProcHex, radix: 16) {
                        self.allProc = allProc
                        jailbreakButton?.isEnabled = true
                        formatter.valueIndicator = "Jailbreak"
                    }
                }
            }
        }
        
        if isJailbroken() {
            jailbreakButton?.isEnabled = false
            formatter.valueIndicator = "Jailbroken"
        }
        
        progressRing.valueFormatter = formatter
        
        let updateTapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(shouldOpenUpdateLink))
        updateOdysseyView.addGestureRecognizer(updateTapGestureRecogniser)
        
        AppVersionManager.shared.doesApplicationRequireUpdate { result in
            switch result {
            case .failure(let error):
                print(error)
                return
            
            case .success(let updateRequired):
                if (updateRequired) {
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.5) {
                            self.updateOdysseyView.isHidden = false
                        }
                    }
                }
            }
        }
        
        self.themeImagePicker = ThemeImagePicker(presentationController: self, delegate: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: ThemesManager.themeChangeNotification, object: nil)
        self.updateTheme()
        LightManager.shared.grabLightsFromBridge()
        // Do any additional setup after loading the view.
    }

    @objc func updateTheme() {
        let custom = UserDefaults.standard.string(forKey: "theme") == "custom"
        let customColour = UserDefaults.standard.string(forKey: "theme") == "customColourTheme"

        var bgImage: UIImage?
        
        if custom {
            if UserDefaults.standard.object(forKey: "customImage") == nil {
                let alert = UIAlertController(title: "Note", message: "This jailbreak is a tribute, please don't be disrespectful.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                    self.themeImagePicker.present(from: self.view)
                }))
                self.present(alert, animated: true)
                return
            } else {
                bgImage = ThemesManager.shared.customImage
            }
        } else {
            bgImage = ThemesManager.shared.currentTheme.backgroundImage
        }
        
        if let bgImage = bgImage {
            if custom {
                backgroundImage.image = bgImage
            } else {
                let aspectHeight = self.view.bounds.height
                let aspectWidth = self.view.bounds.width
                    
                let maxDimension = max(aspectHeight, aspectWidth)
                let isiPad = UIDevice.current.userInterfaceIdiom == .pad
                
                backgroundImage.image = ImageProcess.shared.sizeImage(image: bgImage,
                                                                      aspectHeight: isiPad ? maxDimension : aspectHeight,
                                                                      aspectWidth: isiPad ? maxDimension : aspectWidth,
                                                                      center: ThemesManager.shared.currentTheme.backgroundCenter)
            }
        } else {
            backgroundImage.image = nil
        }
        
        if (custom || customColour) { vibrancyView.isHidden = !ThemesManager.shared.customThemeBlur } else { vibrancyView.isHidden = !ThemesManager.shared.currentTheme.enableBlur }
        
        backgroundOverlay.backgroundColor = ThemesManager.shared.currentTheme.backgroundOverlay ?? UIColor.clear
        themeCopyrightButton.isHidden = ThemesManager.shared.currentTheme.copyrightString.isEmpty
    }
    
    @objc private func shouldOpenUpdateLink() {
        AppVersionManager.shared.launchBestUpdateApplication()
    }
    
    func getHSP4(tfp0: inout mach_port_t) -> Bool {
        let host = mach_host_self()
        let ret = host_get_special_port(host, HOST_LOCAL_NODE, 4, &tfp0)
        mach_port_destroy(mach_task_self_, host)
        return ret == KERN_SUCCESS && tfp0 != MACH_PORT_NULL
    }
    
    func showAlert(_ title: String, _ message: String, sync: Bool, callback: (() -> Void)? = nil, yesNo: Bool = false, noButtonText: String? = nil) {
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: yesNo ? "Yes" : "OK", style: .default) { _ in
                if let callback = callback {
                    callback()
                }
                if sync {
                    sem.signal()
                }
            })
            if yesNo {
                alertController.addAction(UIAlertAction(title: noButtonText ?? "No", style: .default) { _ in
                    if sync {
                        sem.signal()
                    }
                })
            }
            (self.presentedViewController ?? self).present(alertController, animated: true, completion: nil)
        }
        if sync {
            sem.wait()
        }
    }
    
    @IBAction func jailbreak() {
        jailbreakButton?.isEnabled = false
        containerView.isUserInteractionEnabled = false

        if self.logSwitch.isOn {
            UIView.animate(withDuration: 0.5) {
                self.containerView.alpha = 0.3
                self.performSegue(withIdentifier: "logSegue", sender: self.jailbreakButton)
            }
        } else {
            self.progressRing.startProgress(to: 33, duration: 2)
        }
        
        let enableTweaks = self.enableTweaksSwitch.isOn
        let restoreRootFs = self.restoreRootfsSwitch.isOn
        let generator = NonceManager.shared.currentValue
        let simulateJailbreak = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DispatchQueue.global(qos: .userInteractive).async {
                usleep(500 * 1000)
                
                if simulateJailbreak {
                    sleep(1)
                    DispatchQueue.main.async {
                        self.progressRing.startProgress(to: 40, duration: 2)
                    }
                    var outStream = StandardOutputStream.shared
                    var errStream = StandardErrorOutputStream.shared
                    print("Testing log", to: &outStream)
                    print("Testing stderr", to: &errStream)
                    
                    sleep(2)
                    DispatchQueue.main.async {
                        self.progressRing.startProgress(to: 80, duration: 2)
                    }
                    print("Testing log2", to: &outStream)
                    print("Testing stderr2", to: &errStream)
                    
                    sleep(1)
                    DispatchQueue.main.async {
                        self.progressRing.startProgress(to: 100, duration: 2)
                    }
                    print("Testing log3", to: &outStream)
                    print("Testing stderr3", to: &errStream)
                    
                    self.showAlert("Test alert", "Testing an alert message", sync: true)
                    print("Alert done")
                    
                    return
                }
                
                var tfp0 = mach_port_t()
                var any_proc = UInt64(0)
                if self.getHSP4(tfp0: &tfp0) {
                    tfpzero = tfp0
                    any_proc = rk64(self.allProc)
                } else {
                    if #available(iOS 13.5.1, *) {
                        fatalError("Unable to get tfp0")
                    } else if #available(iOS 13.3.1, *) {
                        print("Selecting tardy0n for iOS 13.4 -> 13.5 (+ 13.5.5b1)")
                        tardy0n()
                        tfpzero = getTaskPort()
                        tfp0 = tfpzero
                        let our_task = getOurTask()
                        any_proc = rk64(our_task + Offsets.shared.task.bsd_info)
                    } else if #available(iOS 13, *) {
                        print("Selecting time_waste for iOS 13.0 -> 13.3")
                        get_tfp0()
                        tfp0 = tfpzero
                        let our_task = rk64(task_self + Offsets.shared.ipc_port.ip_kobject)
                        any_proc = rk64(our_task + Offsets.shared.task.bsd_info)
                    }
                }
                DispatchQueue.main.async {
                    self.progressRing.startProgress(to: 66, duration: 2)
                }
                let electra = Electra(ui: self,
                                      tfp0: tfpzero,
                                      any_proc: any_proc,
                                      enable_tweaks: enableTweaks,
                                      restore_rootfs: restoreRootFs,
                                      nonce: generator)
                
                self.electra = electra
                let err = electra.jailbreak()

                DispatchQueue.main.async {
                    if err == .ERR_NOERR {
                        self.progressRing.startProgress(to: 100, duration: 2)
                    } else {
                        self.progressRing.startProgress(to: 100, duration: 2)
                        
                        self.showAlert("Oh no", "\(String(describing: err))", sync: false, callback: {
                            UIApplication.shared.beginBackgroundTask {
                                print("odd. this should never be called.")
                            }
                        })
                    }
                }
            }
        }
    }
    
    func popCurrentView(animated: Bool) {
        guard let currentView = currentView,
            !currentView.isRootView else {
            return
        }
        let scrollView: UIScrollView = self.scrollView
        if !animated {
            currentView.isHidden = true
            scrollView.contentSize = CGSize(width: currentView.parentView.frame.maxX, height: scrollView.contentSize.height)
        } else {
            scrollAnimationClosures.append {
                currentView.parentView.viewShown()
                currentView.isHidden = true
                scrollView.contentSize = CGSize(width: currentView.parentView.frame.maxX, height: scrollView.contentSize.height)
            }
        }
        self.currentView = currentView.parentView
        scrollView.scrollRectToVisible(currentView.parentView.frame, animated: animated)
        
        if !currentView.parentView.isRootView {
            self.resetPopTimer()
        }
    }
    
    func resetPopTimer() {
        self.popClosure?.cancel()
        let popClosure = DispatchWorkItem {
            self.popCurrentView(animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: popClosure)
        self.popClosure = popClosure
    }
    
    func cancelPopTimer() {
        self.popClosure?.cancel()
        self.popClosure = nil
    }
    
    @IBAction func showPanel(button: PanelButton) {
        button.childPanel.isHidden = false
        self.currentView = button.childPanel
        
        scrollAnimationClosures.append {
            button.childPanel.viewShown()
        }
        
        scrollView.contentSize = CGSize(width: button.childPanel.frame.maxX, height: scrollView.contentSize.height)
        scrollView.scrollRectToVisible(button.childPanel.frame, animated: true)
        self.resetPopTimer()
    }
    
    @IBAction func themeInfo() {
        self.showAlert("Theme Copyright Info", ThemesManager.shared.currentTheme.copyrightString, sync: false)
    }
    
    @IBAction func changeCustomImage(_ sender: UIButton) {
        if UserDefaults.standard.object(forKey: "customImage") == nil {
            self.cancelPopTimer()
            let alert = UIAlertController(title: "Note", message: "This jailbreak is a tribute, please don't be disrespectful.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                self.themeImagePicker.present(from: sender)
            }))
            self.present(alert, animated: true)
        } else {
            self.themeImagePicker.present(from: sender)
        }
    }
    
    @objc public func showAlderisPicker(_ notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            if let key = dict["default"] as? String {
                activeColourDefault = key
            } else {
                fatalError("Set a key for the colour picker")
            }
        }
        
        navigationController!.present(colorPickerViewController, animated: true)
    }
    
}

extension ViewController: UIScrollViewDelegate {   
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let animationClosures = scrollAnimationClosures
        scrollAnimationClosures = []
        for closure in animationClosures {
            closure()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.cancelPopTimer()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var popCount = 0
        guard var view = self.currentView else {
            return
        }
        while view.frame.minX != self.scrollView.contentOffset.x {
            guard view.frame.minX > self.scrollView.contentOffset.x else {
                fatalError("User dragged the other way???")
            }
            popCount += 1
            view = view.parentView
        }
        
        for _ in 0..<popCount {
            self.popCurrentView(animated: false)
        }
        
        self.resetPopTimer()
    }
}

extension ViewController: ThemeImagePickerDelegate {
    func didSelect(image: UIImage?) {
        if (image != nil) {
            UserDefaults.standard.set(image!.pngData(), forKey: "customImage")
            UserDefaults.standard.synchronize()
            
            self.updateTheme()
        }
    }
}

extension ViewController {
    func bindToKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func unbindKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc
    func keyboardWillChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
            let curFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
            let targetFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        self.view.layoutIfNeeded()
        let deltaY = targetFrame.origin.y - curFrame.origin.y
        self.containerViewYConstraint.constant += deltaY
        UIView.animateKeyframes(withDuration: duration, delay: 0.00, options: UIView.KeyframeAnimationOptions(rawValue: curve), animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

func isJailbroken() -> Bool {
    var flags = UInt32()
    let CS_OPS_STATUS = UInt32(0)
    csops(getpid(), CS_OPS_STATUS, &flags, 0)
    if flags & Consts.shared.CS_PLATFORM_BINARY != 0 {
        return true
    }
    
    let imageCount = _dyld_image_count()
    for i in 0..<imageCount {
        if let cName = _dyld_get_image_name(i) {
            let name = String(cString: cName)
            if name == "/usr/lib/pspawn_payload-stg2.dylib" {
                return true
            }
        }
    }
    return false
}

extension ViewController: ColorPickerDelegate {
    func colorPicker(_ colorPicker: ColorPickerViewController, didSelect color: UIColor) {
        UserDefaults.standard.set(color, forKey: activeColourDefault)
        
        let notification = Notification(name: Notification.Name(ThemesManager.themeChangeNotification.rawValue))
        NotificationCenter.default.post(notification)
    }
}

//Taken from https://stackoverflow.com/questions/1275662/saving-uicolor-to-and-loading-from-nsuserdefaults
extension UserDefaults {

    func color(forKey key: String) -> UIColor? {

        guard let colorData = data(forKey: key) else { return nil }

        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
        } catch let error {
            print("color error \(error.localizedDescription)")
            return nil
        }

    }

    func set(_ value: UIColor?, forKey key: String) {

        guard let color = value else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            set(data, forKey: key)
        } catch let error {
            print("error color key data not saved \(error.localizedDescription)")
        }

    }

}

 
