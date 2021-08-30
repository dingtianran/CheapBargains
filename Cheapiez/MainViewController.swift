//
//  ViewController.swift
//  Cheapiez
//
//  Created by Tianran Ding on 23/09/20.
//

import UIKit
import Combine

class MainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        UNUserNotificationCenter.current().delegate = self
        
        //setup updating chain
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RSSFeedRefreshingReady"), object: nil, queue: OperationQueue.main) { [weak self] (notification: Notification) in
            self?.tableView.reloadData()
        }
        
        NetworkingPipeline.shared.$sourceIndex.sink { [weak self] newIndex in
            self?.tableView.reloadData()
        }.store(in: &cancellables)
        
        reloadSourceFromRSS(forceRefresh: true)
    }
    
    //For light/dark scheme transition
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            NetworkingPipeline.shared.darkMode = self.traitCollection.userInterfaceStyle == .dark
            tableView.reloadData()
        }
    }
    
    func reloadSourceFromRSS(forceRefresh: Bool) {
        if NetworkingPipeline.shared.reload(forceRefresh) == true {
            self.tableView.reloadData()
            self.tableView.contentOffset = CGPoint(x: 0.0, y: 0.0)
        }
    }
    
    @IBAction func sourceValueChanged(_ sender: Any) {
        reloadSourceFromRSS(forceRefresh: false)
    }
    
    @IBAction func forceRefreshButtonPressed(_ sender: Any) {
        reloadSourceFromRSS(forceRefresh: true)
    }
    
    @IBAction func notifyValueChanged(_ sender: Any) {
        NotificationHub.shared.toggleNotification()
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(identifier: "SettingViewController") { coder -> SettingViewController? in
            SettingViewController(notifyEnable: true, coder: coder)
        }
        let navi = UINavigationController(rootViewController: vc)
        self.present(navi, animated: true, completion: nil)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        140.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NetworkingPipeline.shared.allFeedItemsFor(NetworkingPipeline.shared.sourceIndex).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.identifier) as! ItemCell
        cell.updateWithItem(NetworkingPipeline.shared.allFeedItemsFor(NetworkingPipeline.shared.sourceIndex)[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = NetworkingPipeline.shared.allFeedItemsFor(NetworkingPipeline.shared.sourceIndex)[indexPath.row]
        UIApplication.shared.open(URL(string: item.link)!)
    }
}

extension MainViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        self.tableView.contentOffset = CGPoint(x: 0.0, y: 0.0)
        completionHandler()
    }
}
