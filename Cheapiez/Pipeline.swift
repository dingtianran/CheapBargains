//
//  Pipeline.swift
//  Cheapiez
//
//  Created by Tianran Ding on 29/09/20.
//

import Foundation
import UserNotifications
import Alamofire
import SWXMLHash
import UIKit

class NetworkingPipeline {
    
    var sourceFeed: String
    var userIntentToSeeNotify: Bool
    var cheapiesUpdatedDate: Date?
    var chchlalUpdatedDate: Date?
    var ozbUpdatedDate: Date?
    
    var cheapiesRssItems: [FeedEntry]?
    var chchlalRssItems: [FeedEntry]?
    var ozbRssItems: [FeedEntry]?
    
    init(initialFeed: String) {
        self.sourceFeed = initialFeed
        self.userIntentToSeeNotify = UserDefaults.standard.bool(forKey: "UserWant2SeeNotification")
    }
    
    private static var rssFormatter: DateFormatter {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy - HH:mm"
            dateFormatter.locale = NSLocale.current
            return dateFormatter
        }
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
                    DispatchQueue.global().async {
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
                    }
                case let .failure(error):
                    print(error)
                }
            }
            return false
        } else {
            return true
        }
    }
    
    func processXML(_ xml: String?) -> [FeedEntry]? {
        guard let xmlString = xml else { return nil }
        let parser = SWXMLHash.parse(xmlString)
        var items = [FeedEntry]()
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
            let vm = assembleVModelFrom(rssModel: entry)
            items.append(vm)
        }
        return items
    }
    
    func assembleVModelFrom(rssModel: RSSItem) -> FeedEntry {
        let blank = NSAttributedString(string: "")
        //subtitle line
        let attr = NSMutableAttributedString()
        //creator
        let creator = rssModel.creator ?? "N/A"
        let attributesCreator: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor(red: 1.0/256.0, green: 25.0/256.0, blue: 147.0/256.0, alpha: 1.0),
        ]
        let creatorAttr = NSAttributedString(string: creator, attributes: attributesCreator)
        attr.append(creatorAttr)
        //date
        let attributesDate: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor(white: 0.5, alpha: 1.0),
        ]
        if let date = rssModel.pubDate {
            let dateStr = " on " + NetworkingPipeline.rssFormatter.string(from: date)
            let on = NSAttributedString(string: dateStr, attributes: attributesDate)
            attr.append(on)
        }
        
        //html description
        let input = rssModel.description ?? ""
        let html = formattingDescription(input)
        let fullHtml = htmlHead + html + htmlTail
        let data = Data(fullHtml.utf8)
        let desc = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        
        let vm = FeedEntry(title: rssModel.title ?? "",
                           link: rssModel.link ?? "",
                           imageURL: rssModel.imageURL ?? "",
                           subtitle: attr,
                           desc: desc ?? blank)
        return vm
    }
    
    //Get rid of the first div which is a web hack for thumbnail
    func formattingDescription(_ input: String) -> String {
        var processed = input.replacingOccurrences(of: "\n", with: "")
        let regex1 = try? NSRegularExpression(pattern: "\\<div(.*)\\<\\/div\\>", options: .caseInsensitive)
        let matches = regex1!.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        if let match = matches.first {
            let range = match.range(at:0)
            if let divRange = Range(range, in: input) {
                processed.removeSubrange(divRange)
            }
        }
        //get rid of all tables
        processed = processed.replacingOccurrences(of: "\\<table[^>]*\\>(.*?)\\<\\/table\\>", with: "", options: .regularExpression)
        return processed
    }
    
    func allFeedItems() -> [FeedEntry] {
        if self.sourceFeed == "https://www.cheapies.nz/deals/feed" {
            return cheapiesRssItems ?? [FeedEntry]()
        } else if self.sourceFeed == "https://www.ozbargain.com.au/deals/feed" {
            return ozbRssItems ?? [FeedEntry]()
        } else if self.sourceFeed == "https://www.cheapcheaplah.com/deals/feed" {
            return chchlalRssItems ?? [FeedEntry]()
        } else {
            return [FeedEntry]()
        }
    }
    
    func getCurrentNotifyStatus(completion: @escaping (Bool, String?) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings: UNNotificationSettings) in
            DispatchQueue.main.async {
                if settings.badgeSetting != .enabled || self.userIntentToSeeNotify == false {
                    completion(false, "Enable notification here ->")
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    func userSetEnableNotify(on: Bool, completion: @escaping (Bool, String?) -> Void) {
        userIntentToSeeNotify = on
        UserDefaults.standard.setValue(on, forKey: "UserWant2SeeNotification")
        if on == true {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge,.alert]) { (granted, error) in
                DispatchQueue.main.async {
                    if error != nil {
                        completion(false, "notification is disabled")
                    } else {
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    let htmlHead = """
    <html>
    <head>
    <style>
    p {
      font-size: 16px;
    }
    </style>
    </head>
    <body>
    """
    
    let htmlTail = """
    </body>
    </html>
    """
}

struct NotificationHandler {
    
    
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
