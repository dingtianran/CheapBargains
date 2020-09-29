//
//  Pipeline.swift
//  Cheapiez
//
//  Created by Tianran Ding on 29/09/20.
//

import Foundation
import Alamofire
import SWXMLHash

class NetworkingPipeline {
    
    var sourceFeed: String
    
    var cheapiesUpdatedDate: Date?
    var chchlalUpdatedDate: Date?
    var ozbUpdatedDate: Date?
    
    var cheapiesRssItems: [RSSItem]?
    var chchlalRssItems: [RSSItem]?
    var ozbRssItems: [RSSItem]?
    
    init(initialFeed: String) {
        self.sourceFeed = initialFeed
    }
    
    //Return isReady
    func reload(sourceIndex: Int, force: Bool) -> Bool {
        switch sourceIndex {
        case 1:
            //ozbargain
            sourceFeed = "https://www.ozbargain.com.au/deals/feed"
        case 2:
            //chchlah
            sourceFeed = "https://www.cheapcheaplah.com/deals/feed"
        default:
            //cheapies
            sourceFeed = "https://www.cheapies.nz/deals/feed"
        }
        
        var pendingRefrsh = true
        if sourceFeed == "https://www.cheapies.nz/deals/feed" {
            if let previous = cheapiesUpdatedDate {
                if Date().timeIntervalSince(previous) < 180.0 {
                    pendingRefrsh = false
                }
            }
        } else if sourceFeed == "https://www.ozbargain.com.au/deals/feed" {
            if let previous = ozbUpdatedDate {
                if Date().timeIntervalSince(previous) < 180.0 {
                    pendingRefrsh = false
                }
            }
        } else if sourceFeed == "https://www.cheapcheaplah.com/deals/feed" {
            if let previous = chchlalUpdatedDate {
                if Date().timeIntervalSince(previous) < 180.0 {
                    pendingRefrsh = false
                }
            }
        }
        
        if pendingRefrsh == true || force == true {
            AF.request(sourceFeed).responseString { (response: AFDataResponse<String>) in
                switch response.result {
                case .success:
                    if let newItems = self.processXML(response.value) {
                        if self.sourceFeed == "https://www.cheapies.nz/deals/feed" {
                            self.cheapiesRssItems = newItems
                            self.cheapiesUpdatedDate = Date()
                        } else if self.sourceFeed == "https://www.ozbargain.com.au/deals/feed" {
                            self.ozbRssItems = newItems
                            self.ozbUpdatedDate = Date()
                        } else if self.sourceFeed == "https://www.cheapcheaplah.com/deals/feed" {
                            self.chchlalRssItems = newItems
                            self.chchlalUpdatedDate = Date()
                        }
                    }
                    NotificationCenter.default.post(name: Notification.Name("RSSFeedRefreshingReady"), object: nil)
                case let .failure(error):
                    print(error)
                }
            }
            return false
        } else {
            return true
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
    
    func allFeedItems() -> [RSSItem] {
        if self.sourceFeed == "https://www.cheapies.nz/deals/feed" {
            return cheapiesRssItems ?? [RSSItem]()
        } else if self.sourceFeed == "https://www.ozbargain.com.au/deals/feed" {
            return ozbRssItems ?? [RSSItem]()
        } else if self.sourceFeed == "https://www.cheapcheaplah.com/deals/feed" {
            return chchlalRssItems ?? [RSSItem]()
        } else {
            return [RSSItem]()
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
