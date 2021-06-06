//
//  PreferencesSceneDelegate.swift
//  pronouncymac
//
//  Created by Tianran Ding on 6/06/21.
//

import UIKit

class PreferencesSceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            
            windowScene.title = "Preferences"
            
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.preferencesSceneSession = session
            }
            
            let window = UIWindow(windowScene: windowScene)
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(identifier: "SettingViewController") { coder -> SettingViewController? in
                SettingViewController(notifyEnable: true, coder: coder)
            }
            window.rootViewController = vc
            window.backgroundColor = .secondarySystemBackground
            
            window.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: UIFloat(600), height: UIFloat(600))
            window.windowScene?.sizeRestrictions?.maximumSize = CGSize(width: UIFloat(800), height: UIFloat(800))
                        
            self.window = window
            
            AppDelegate.appKitController?.perform(NSSelectorFromString("configurePreferencesWindowForSceneIdentifier:"), with: windowScene.session.persistentIdentifier)

            window.makeKeyAndVisible()
        }
    }
}
