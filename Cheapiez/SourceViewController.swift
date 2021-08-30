//
//  SourceViewController.swift
//  Cheapiez
//
//  Created by Tianran Ding on 20/07/21.
//

import UIKit

class SourceViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
    }
}

extension SourceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50.0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Feed / Sources"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "SourceCell")
        cell.selectionStyle = .gray
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NetworkingPipeline.shared.markSourceIndex(indexPath.row + 1)
    }
}
