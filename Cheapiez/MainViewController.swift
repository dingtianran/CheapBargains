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
    @IBOutlet weak var upgradeLabel: UILabel!
    @IBOutlet weak var upgradeLabelHeight: NSLayoutConstraint!
    
    private var cancellables: Set<AnyCancellable> = []
    var dataSource: UITableViewDataSource?
    
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(downloadNewVersionHandler(_:)))
        upgradeLabel.addGestureRecognizer(tapGesture)
        
        //Forced upgrading needed
        NetworkingPipeline.shared.$buildObsolete.sink { [weak self] obsolete in
            DispatchQueue.main.async {
                if obsolete == true {
                    let action = UIAlertAction(title: "I see", style: .default) { action in
                        if let storeurl = URL(string: "https://github.com/dingtianran/CheapBargains/releases/latest/"), UIApplication.shared.canOpenURL(storeurl) {
                            UIApplication.shared.open(storeurl)
                        }
                    }
                    let alert = UIAlertController(title: "Obsolete Version", message: "To continue, please download new build", preferredStyle: .alert)
                    alert.addAction(action)
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }.store(in: &cancellables)
        
        //New build available
        NetworkingPipeline.shared.$newVersionAvailable.sink { [weak self] newVersion in
            DispatchQueue.main.async {
                self?.upgradeLabelHeight.constant = newVersion == true ? 34 : 0
                self?.upgradeLabel.isHidden = !newVersion
            }
        }.store(in: &cancellables)
    }
    
    func reloadSourceFromRSS(forceRefresh: Bool) {
        if NetworkingPipeline.shared.reload(forceRefresh) == true {
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
    
    @objc func downloadNewVersionHandler(_ sender: Any) {
        if let storeurl = URL(string: "https://github.com/dingtianran/CheapBargains/releases/latest/"), UIApplication.shared.canOpenURL(storeurl) {
            UIApplication.shared.open(storeurl)
        }
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
