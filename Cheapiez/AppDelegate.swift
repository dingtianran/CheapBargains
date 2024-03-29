//
//  AppDelegate.swift
//  Cheapiez
//
//  Created by Tianran Ding on 23/09/20.
//

import UIKit

extension NSObject {
    @objc public func _marzipan_setupWindow(_ sender:Any) {
        
    }
    
    @objc public func configurePreferencesWindowForSceneIdentifier(_ sceneIdentifier:String) {
        
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var preferencesSceneSession:UISceneSession?
    static var appKitController:NSObject?
    
    class func loadAppKitIntegrationFramework() {
        if let frameworksPath = Bundle.main.privateFrameworksPath {
            let bundlePath = "\(frameworksPath)/AppKitIntegration.framework"
            do {
                try Bundle(path: bundlePath)?.loadAndReturnError()
                
                let bundle = Bundle(path: bundlePath)!
                NSLog("[APPKIT BUNDLE] Loaded Successfully")
                
                if let appKitControllerClass = bundle.classNamed("AppKitIntegration.AppKitController") as? NSObject.Type {
                    appKitController = appKitControllerClass.init()
                    
                    NotificationCenter.default.addObserver(appKitController as Any, selector: #selector(_marzipan_setupWindow(_:)), name: NSNotification.Name("UISBHSDidCreateWindowForSceneNotification"), object: nil)
                }
            }
            catch {
                NSLog("[APPKIT BUNDLE] Error loading: \(error)")
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Observe "Open Preferences" notification
        NotificationCenter.default.addObserver(forName: NSNotification.Name("OPEN_PREFERENCES"), object: nil, queue: .main) { [unowned self] notification in
            self.showPreferences("")
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if options.userActivities.filter({$0.activityType == "com.iDing.cheapieshub.preferences"}).first != nil {
            return UISceneConfiguration(name: "Preferences", sessionRole: .windowApplication)
        }
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    override func buildMenu(with builder: UIMenuBuilder) {
        do {
            let prefCommand = UIKeyCommand(input: ",", modifierFlags: [.command], action: #selector(showPreferences(_:)))
            prefCommand.title = NSLocalizedString("Preferences…", comment: "")
            let prefMenu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier("MENU_PREF"), options: .displayInline, children: [prefCommand])
            
            builder.insertSibling(prefMenu, afterMenu: .about)
            builder.remove(menu: .help)
        }
        super.buildMenu(with: builder)
    }

    @objc func showPreferences(_ sender: Any) {
        let userActivity = NSUserActivity(activityType: "com.iDing.cheapieshub.preferences")
        UIApplication.shared.requestSceneSessionActivation(preferencesSceneSession, userActivity: userActivity, options: nil)
    }
    
    

}

