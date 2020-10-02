//
//  ViewController.swift
//  Cheapiez
//
//  Created by Tianran Ding on 23/09/20.
//

import UIKit
import Alamofire
import SWXMLHash

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var notifySwitch: UISwitch!
    @IBOutlet weak var notifyMessage: UILabel!
    @IBOutlet weak var sourceSelector: UISegmentedControl!
    
    var pipeline: NetworkingPipeline!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sourceSelector.apportionsSegmentWidthsByContent = true
        
        UNUserNotificationCenter.current().delegate = self
        //feed: cheapies by default
        pipeline = NetworkingPipeline(initialFeed: "https://www.cheapies.nz/deals/feed")
        //setup updating chain
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RSSFeedRefreshingReady"), object: nil, queue: OperationQueue.main) { (notification: Notification) in
            self.tableView.reloadData()
        }
        //setup notify status
        pipeline.getCurrentNotifyStatus { (verdict: Bool, possibleMessage: String?) in
            self.notifySwitch.isOn = verdict
        }
        reloadSourceFromRSS(forceRefresh: true)
    }
    
    func reloadSourceFromRSS(forceRefresh: Bool) {
        if pipeline.reload(sourceIndex: sourceSelector.selectedSegmentIndex, force: forceRefresh) == true {
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
        pipeline.userSetEnableNotify(on: notifySwitch.isOn) { (verdict: Bool, possibleMessage: String?) in
            if verdict != self.notifySwitch.isOn {
                self.notifySwitch.isOn = verdict
            }
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        140.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pipeline.allFeedItems().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.identifier) as! ItemCell
        cell.updateWithItem(pipeline.allFeedItems()[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = pipeline.allFeedItems()[indexPath.row]
        UIApplication.shared.open(URL(string: item.link)!)
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        self.tableView.contentOffset = CGPoint(x: 0.0, y: 0.0)
        completionHandler()
    }
}
