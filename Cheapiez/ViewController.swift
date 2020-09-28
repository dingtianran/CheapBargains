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
    @IBOutlet weak var sourceSelector: UISegmentedControl!
    var sourceURL = "https://www.cheapies.nz/deals/feed"
    
    var cheapiesUpdatedDate: Date?
    var ozbUpdatedDate: Date?
    
    var cheapiesRssItems: [RSSItem]?
    var ozbRssItems: [RSSItem]?

    override func viewDidLoad() {
        super.viewDidLoad()
        sourceSelector.apportionsSegmentWidthsByContent = true
        
        reloadSourceFromRSS()
    }
    
    func reloadSourceFromRSS() {
        AF.request(sourceURL).responseString { (response: AFDataResponse<String>) in
            switch response.result {
            case .success:
                if let newItems = self.processXML(response.value) {
                    if self.sourceURL == "https://www.cheapies.nz/deals/feed" {
                        self.cheapiesRssItems = newItems
                        self.cheapiesUpdatedDate = Date()
                    } else if self.sourceURL == "https://www.ozbargain.com.au/deals/feed" {
                        self.ozbRssItems = newItems
                        self.ozbUpdatedDate = Date()
                    }
                }
                self.tableView.reloadData()
            case let .failure(error):
                print(error)
            }
        }
    }
    
    func processXML(_ xml: String?) -> [RSSItem]? {
        guard let xmlString = xml else { return nil }
        let parser = SWXMLHash.parse(xmlString)
        var items = [RSSItem]()
        for item in parser["rss"]["channel"]["item"].all {
            //assembly categorris
            var categories = [Category]()
            for cat in item["category"].all {
                let domain = cat.element?.attribute(by: "domain")?.text
                let text = cat.element?.text
                categories.append(Category(domain: domain, text: text))
            }
            //assembly rss entry
            let title = item["title"].element?.text
            let link = item["link"].element?.text
            let desc = item["description"].element?.text
            let creator = item["dc:creator"].element?.text
            let pubDate: Date? = try? item["pubDate"].value()
            let thumbnail = item["media:thumbnail"].element?.attribute(by: "url")?.text
            let entry = RSSItem(title: title, link: link, description: desc, creator: creator, pubDate: pubDate, imageURL: thumbnail, category: categories.count>0 ? categories:nil)
            items.append(entry)
        }
        return items
    }
    
    @IBAction func sourceValueChanged(_ sender: Any) {
        switch sourceSelector.selectedSegmentIndex {
        case 0:
            sourceURL = "https://www.cheapies.nz/deals/feed"
        default:
            sourceURL = "https://www.ozbargain.com.au/deals/feed"
        }
    }
    
    @IBAction func forceRefreshButtonPressed(_ sender: Any) {
        reloadSourceFromRSS()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        140.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.sourceURL == "https://www.cheapies.nz/deals/feed" {
            return cheapiesRssItems?.count ?? 0
        } else if self.sourceURL == "https://www.ozbargain.com.au/deals/feed" {
            return ozbRssItems?.count ?? 0
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.identifier) as! ItemCell
        if self.sourceURL == "https://www.cheapies.nz/deals/feed" {
            cell.updateWithItem(cheapiesRssItems![indexPath.row])
        } else if self.sourceURL == "https://www.ozbargain.com.au/deals/feed" {
            cell.updateWithItem(ozbRssItems![indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if self.sourceURL == "https://www.cheapies.nz/deals/feed" {
            let item = cheapiesRssItems![indexPath.row]
            UIApplication.shared.open(URL(string: item.link!)!)
        } else if self.sourceURL == "https://www.ozbargain.com.au/deals/feed" {
            let item = ozbRssItems![indexPath.row]
            UIApplication.shared.open(URL(string: item.link!)!)
        }
    }
}

extension Date: XMLElementDeserializable, XMLAttributeDeserializable {
    private static var rssFormatter: DateFormatter {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            return dateFormatter
        }
    }
    
    public static func deserialize(_ element: XMLElement) throws -> Date {
        let date = stringToDate(element.text)

        guard let validDate = date else {
            throw XMLDeserializationError.typeConversionFailed(type: "Date", element: element)
        }

        return validDate
    }

    public static func deserialize(_ attribute: XMLAttribute) throws -> Date {
        let date = stringToDate(attribute.text)

        guard let validDate = date else {
            throw XMLDeserializationError.attributeDeserializationFailed(type: "Date", attribute: attribute)
        }

        return validDate
    }

    private static func stringToDate(_ dateAsString: String) -> Date? {
        return rssFormatter.date(from: dateAsString)
    }
}
