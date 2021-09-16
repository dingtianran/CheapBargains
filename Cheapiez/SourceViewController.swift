//
//  SourceViewController.swift
//  Cheapiez
//
//  Created by Tianran Ding on 20/07/21.
//

import UIKit
import Combine

class SourceViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
        
        NetworkingPipeline.shared.$cheapiesNewEntries.sink { [weak self] newCount in
            self?.tableView.reloadData()
        }.store(in: &cancellables)
        
        NetworkingPipeline.shared.$ozbNewEntries.sink { [weak self] newCount in
            self?.tableView.reloadData()
        }.store(in: &cancellables)
        
        NetworkingPipeline.shared.$chchlahNewEntries.sink { [weak self] newCount in
            self?.tableView.reloadData()
        }.store(in: &cancellables)
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
            cell.detailTextLabel?.text = NetworkingPipeline.shared.cheapiesNewEntries > 0 ? "\(NetworkingPipeline.shared.cheapiesNewEntries)" : nil
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "🇦🇺 OzBargain"
            cell.detailTextLabel?.text = NetworkingPipeline.shared.ozbNewEntries > 0 ? "\(NetworkingPipeline.shared.ozbNewEntries)" : nil
        } else if indexPath.row == 2 {
            cell.textLabel?.text = "🇸🇬 CheapcheapLah"
            cell.detailTextLabel?.text = NetworkingPipeline.shared.chchlahNewEntries > 0 ? "\(NetworkingPipeline.shared.chchlahNewEntries)" : nil
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NetworkingPipeline.shared.markSourceReadForIndex(indexPath.row + 1)
    }
}
