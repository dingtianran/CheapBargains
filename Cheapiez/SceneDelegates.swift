//
//  SceneDelegate.swift
//  Cheapiez
//
//  Created by Tianran Ding on 23/09/20.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        let svc = UISplitViewController()
        svc.primaryBackgroundStyle = .sidebar
        
        let stb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let source = stb.instantiateViewController(withIdentifier: "SourceViewController")
        let main = stb.instantiateViewController(withIdentifier: "MainViewController")
        svc.viewControllers = [source, main]
        
        if let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .hidden
            titlebar.toolbar = nil
        }
        
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 480, height: 640)
        }
        
        window?.rootViewController = svc
        window?.makeKeyAndVisible()
    }
}

class PreferencesSceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            
            windowScene.title = NSLocalizedString("Preferences", comment: "")
            
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.preferencesSceneSession = session
            }
            
            let window = UIWindow(windowScene: windowScene)
            let stb = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = stb.instantiateViewController(identifier: "SettingViewController") { coder -> SettingViewController? in
                SettingViewController(notifyEnable: true, coder: coder)
            }
            window.rootViewController = vc
            window.backgroundColor = .secondarySystemBackground
            
            window.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: UIFloat(600), height: UIFloat(600))
            window.windowScene?.sizeRestrictions?.maximumSize = CGSize(width: UIFloat(800), height: UIFloat(1200))
                        
            self.window = window
            
            AppDelegate.appKitController?.perform(NSSelectorFromString("configurePreferencesWindowForSceneIdentifier:"), with: windowScene.session.persistentIdentifier)

            window.makeKeyAndVisible()
        }
    }
}
