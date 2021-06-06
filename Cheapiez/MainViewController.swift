//
//  ViewController.swift
//  Cheapiez
//
//  Created by Tianran Ding on 23/09/20.
//

import UIKit
import Combine
import Alamofire
import SWXMLHash

class ViewController: UIViewController {
    @IBOutlet weak var topNotchGap: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var notifySwitch: UISwitch!
    @IBOutlet weak var notifyMessage: UILabel!
    @IBOutlet weak var sourceSelector: UISegmentedControl!
    @IBOutlet weak var settingsButton: UIButton!
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if !targetEnvironment(macCatalyst)
        topNotchGap.constant = 20.0
        #endif
        
        sourceSelector.apportionsSegmentWidthsByContent = true
        
        UNUserNotificationCenter.current().delegate = self
        
        //setup updating chain
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RSSFeedRefreshingReady"), object: nil, queue: OperationQueue.main) { (notification: Notification) in
            self.tableView.reloadData()
        }
        //setup notification status
        NotificationHub.shared.$enableNotify.sink { [weak self] enabled in
            DispatchQueue.main.async {
                self?.notifySwitch.isOn = enabled ?? false
            }
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
        if NetworkingPipeline.shared.reload(sourceIndex: sourceSelector.selectedSegmentIndex, force: forceRefresh) == true {
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
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OPEN_PREFERENCES"), object: nil)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        140.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NetworkingPipeline.shared.allFeedItems().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.identifier) as! ItemCell
        cell.updateWithItem(NetworkingPipeline.shared.allFeedItems()[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = NetworkingPipeline.shared.allFeedItems()[indexPath.row]
        UIApplication.shared.open(URL(string: item.link)!)
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        self.tableView.contentOffset = CGPoint(x: 0.0, y: 0.0)
        completionHandler()
    }
}
