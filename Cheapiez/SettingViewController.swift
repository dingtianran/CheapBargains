//
//  SettingViewController.swift
//  Cheapiez
//
//  Created by Tianran Ding on 10/26/20.
//

import UIKit
import Combine

class SettingViewController: UIViewController {
    @IBOutlet weak var frequencyControl: UISegmentedControl!
    @IBOutlet weak var notificationSwitch: UISwitch!
    
    private var cancellables: Set<AnyCancellable> = []
        
    init?(notifyEnable: Bool, coder: NSCoder) {
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("💣💀")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(closeButtonPressed(_:)))
        
        //setup notification status
        NotificationHub.shared.$enableNotify.sink { [weak self] enabled in
            DispatchQueue.main.async {
                self?.notificationSwitch.isOn = enabled ?? false
            }
        }.store(in: &cancellables)
        
        //setup refresh frequency
        NetworkingPipeline.shared.$refreshFrequency.sink { [weak self] freq in
            DispatchQueue.main.async {
                switch freq {
                case 600.0:
                    self?.frequencyControl.selectedSegmentIndex = 1
                case 1800.0:
                    self?.frequencyControl.selectedSegmentIndex = 2
                case 3600.0:
                    self?.frequencyControl.selectedSegmentIndex = 3
                default:
                    self?.frequencyControl.selectedSegmentIndex = 0
                }
            }
        }.store(in: &cancellables)
    }
    
    @objc func closeButtonPressed(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshFrequencyChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0://3 mins
            NetworkingPipeline.shared.resetTimerForNextRefresh()
        case 1://10 mins
            NetworkingPipeline.shared.resetTimerForNextRefresh(600.0)
        case 2://30 mins
            NetworkingPipeline.shared.resetTimerForNextRefresh(1800.0)
        default://60 mins
            NetworkingPipeline.shared.resetTimerForNextRefresh(3600.0)
        }
    }
    
    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {
        NotificationHub.shared.toggleNotification()
    }
}
