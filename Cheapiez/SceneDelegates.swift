//
//  SceneDelegate.swift
//  Cheapiez
//
//  Created by Tianran Ding on 23/09/20.
//

import UIKit
import SwiftUI

// MARK: - Main scene delegate
class SceneDelegate: UIResponder, UIWindowSceneDelegate, NSToolbarDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let svc = UISplitViewController()
        svc.primaryBackgroundStyle = .sidebar
        svc.preferredPrimaryColumnWidth = 250
        
        let stb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let feed = UIHostingController(rootView: FeedSourcesView())
        feed.view.backgroundColor = .clear
        let main = stb.instantiateViewController(withIdentifier: "MainViewController")
        svc.viewControllers = [feed, main]
        
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 480, height: 640)
        }
        
        window?.rootViewController = svc
        window?.makeKeyAndVisible()
        
        setupNSToolbar()
    }
    
    func setupNSToolbar() {
        let toolbar = NSToolbar()
        toolbar.delegate = self
        window?.windowScene?.titlebar?.toolbar = toolbar
        window?.windowScene?.titlebar?.titleVisibility = .hidden
    }
    
    //MARK: - NSToolbarDelegate
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [NSToolbarItem.Identifier("refreshButton"), NSToolbarItem.Identifier("settingsButton"), .flexibleSpace]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [NSToolbarItem.Identifier("refreshButton"), NSToolbarItem.Identifier("settingsButton"), .flexibleSpace]
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
        case NSToolbarItem.Identifier("refreshButton"):
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise.circle"), style: .plain, target: self, action: #selector(refreshButtonPressed(_:)))
            return NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
        case NSToolbarItem.Identifier("settingsButton"):
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(settingsButtonPressed(_:)))
            return NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
        default:
            break
        }
        
        return NSToolbarItem(itemIdentifier: itemIdentifier)
    }
    
    @objc func refreshButtonPressed(_ sender: Any) {
        // TODO: refresh
    }
    
    @objc func settingsButtonPressed(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("OPEN_PREFERENCES"), object: nil)
    }
}

// MARK: - Pref scene delegate
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
