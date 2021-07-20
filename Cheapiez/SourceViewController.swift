//
//  SourceViewController.swift
//  Cheapiez
//
//  Created by Tianran Ding on 20/07/21.
//

import UIKit

class SourceViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Feed / Sources"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshButtonPressed(_:)))
    }
    
    @objc func refreshButtonPressed(_ sender: Any) {
        
    }
}

extension SourceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "SourceCell")
        if indexPath.row == 0 {
            cell.textLabel?.text = "🇳🇿 ChoiceCheapies"
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "🇦🇺 OzBargain"
        } else if indexPath.row == 2 {
            cell.textLabel?.text = "🇸🇬 CheapcheapLah"
        }
        cell.detailTextLabel?.text = "12"
        return cell
    }
}
