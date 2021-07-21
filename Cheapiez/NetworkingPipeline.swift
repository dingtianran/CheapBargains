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

class NetworkingPipeline: NSObject {
    
    //feed: cheapies by default
    static let shared = NetworkingPipeline()
    
    var previousXMLString1: String?
    var previousXMLString2: String?
    var previousXMLString3: String?
    var updatedDate: Date?
    var refreshTimer: Timer
    
    var cheapiesRssItems: [FeedEntry]?
    var cheapiesKeyBucket = [String]()
    var chchlahRssItems: [FeedEntry]?
    var chchlahKeyBucket = [String]()
    var ozbRssItems: [FeedEntry]?
    var ozbKeyBucket = [String]()
    
    @Published private(set) var refreshFrequency: Double = 0.0
    @Published private(set) var sourceIndex = 1
    
    var darkMode: Bool = false
    {//Whenever title color changed, re-render every titles
        didSet {
            reRenderItems()
        }
    }
    
    override init() {
        self.refreshTimer = Timer()
        //clear notify badge number when user enter foreground
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NSApplicationDidBecomeActiveNotification"), object: nil, queue: .main) { (notification: Notification) in
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    private static var rssFormatter: DateFormatter {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy - HH:mm"
            dateFormatter.locale = .current
            return dateFormatter
        }
    }
    
    // By default it is 180 sec
    func resetTimerForNextRefresh(_ freq: Double = 180.0) {
        refreshFrequency = freq
        //setup refresh freq to every given seconds
        if self.refreshTimer.isValid {
            self.refreshTimer.invalidate()
        }
        self.refreshTimer = Timer.scheduledTimer(timeInterval: refreshFrequency, target: self, selector: #selector(refreshTimerHandler(_:)), userInfo: nil, repeats: false)
        self.refreshTimer.tolerance = 300.0
    }
    
    @objc func refreshTimerHandler(_ sender: Timer) {
        print("Timer fired!")
        _ = reload(true)
    }
    
    func markSourceIndex(_ source: Int) {
        sourceIndex = source
    }
    
    //Return isReady
    func reload(_ force: Bool) -> Bool {
        var pendingRefrsh = true
        if let previous = updatedDate {
            if Date().timeIntervalSince(previous) < refreshFrequency {
                pendingRefrsh = false
            }
        }
        
        if pendingRefrsh == true || force == true {
            let group = DispatchGroup()
            //cheapies
            group.enter()
            let sourceFeed1 = "https://www.cheapies.nz/deals/feed"
            AF.request(sourceFeed1).responseString { (response: AFDataResponse<String>) in
                switch response.result {
                case .success:
                    self.previousXMLString1 = response.value
                    if let newItems = self.processXML(index: 1, xml: response.value) {
                        self.cheapiesRssItems = newItems
                    }
                case let .failure(error):
                    print(error)
                }
                group.leave()
            }
            //ozbargain
            group.enter()
            let sourceFeed2 = "https://www.ozbargain.com.au/deals/feed"
            AF.request(sourceFeed2).responseString { (response: AFDataResponse<String>) in
                switch response.result {
                case .success:
                    self.previousXMLString2 = response.value
                    if let newItems = self.processXML(index: 2, xml: response.value) {
                        self.ozbRssItems = newItems
                    }
                case let .failure(error):
                    print(error)
                }
                group.leave()
            }
            //chchlah
            group.enter()
            let sourceFeed3 = "https://www.cheapcheaplah.com/deals/feed"
            AF.request(sourceFeed3).responseString { (response: AFDataResponse<String>) in
                switch response.result {
                case .success:
                    self.previousXMLString3 = response.value
                    if let newItems = self.processXML(index: 3, xml: response.value) {
                        self.chchlahRssItems = newItems
                    }
                case let .failure(error):
                    print(error)
                }
                group.leave()
            }
            
            group.notify(queue: DispatchQueue.global()) {
                self.updatedDate = Date()
                NotificationCenter.default.post(name: Notification.Name("RSSFeedRefreshingReady"), object: nil)
            }
            resetTimerForNextRefresh()
            return false
        } else {
            return true
        }
    }
    
    func reRenderItems() {
        if let newItems = processXML(index: 1, xml: previousXMLString1) {
            cheapiesRssItems = newItems
        }
        if let newItems = processXML(index: 2, xml: previousXMLString2) {
            ozbRssItems = newItems
        }
        if let newItems = processXML(index: 3, xml: previousXMLString3) {
            chchlahRssItems = newItems
        }
    }
    
    private func processXML(index: Int, xml: String?) -> [FeedEntry]? {
        guard let xmlString = xml else { return nil }
        let parser = SWXMLHash.parse(xmlString)
        var items = [FeedEntry]()
        var newIncomingBucket = [FeedEntry]()
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
            let positiveVote = item["ozb:meta"].element?.attribute(by: "votes-pos")?.text
            let negtiveVote = item["ozb:meta"].element?.attribute(by: "votes-neg")?.text
            let comments = item["ozb:meta"].element?.attribute(by: "comment-count")?.text
            let titleTag = item["ozb:title-msg"].element?.attribute(by: "type")?.text ?? "active"
            let thumbnail = item["media:thumbnail"].element?.attribute(by: "url")?.text
            let guid = item["guid"].element?.text
            let entry = RSSItem(title: title, link: link, description: desc, creator: creator, pubDate: pubDate, positiveVote: positiveVote, negtiveVote: negtiveVote, comments: comments, titleTag: titleTag, imageURL: thumbnail, category: categories.count>0 ? categories:nil, guid: guid)
            let vm = assembleVModelFrom(rssModel: entry)
            items.append(vm)
            
            if let id = guid {
                if index == 1 {
                    if !cheapiesKeyBucket.contains(id) {
                        newIncomingBucket.append(vm)
                    }
                } else if index == 2 {
                    if !ozbKeyBucket.contains(id) {
                        newIncomingBucket.append(vm)
                    }
                } else if index == 3 {
                    if !chchlahKeyBucket.contains(id) {
                        newIncomingBucket.append(vm)
                    }
                }
            }
        }
        
        if index == 1 {
            if cheapiesKeyBucket.count > 0 {
                handleNewIncoming(items: newIncomingBucket, for: "Cheapies")
            }
            cheapiesKeyBucket.append(contentsOf: newIncomingBucket.map({ $0.id }))
        } else if index == 2 {
            if ozbKeyBucket.count > 0 {
                handleNewIncoming(items: newIncomingBucket, for: "OzBargain")
            }
            ozbKeyBucket.append(contentsOf: newIncomingBucket.map({ $0.id }))
        } else if index == 3 {
            if chchlahKeyBucket.count > 0 {
                handleNewIncoming(items: newIncomingBucket, for: "CheapcheapLah")
            }
            chchlahKeyBucket.append(contentsOf: newIncomingBucket.map({ $0.id }))
        }
        return items
    }
    
    func assembleVModelFrom(rssModel: RSSItem) -> FeedEntry {
        //title line
        let titleline = NSMutableAttributedString()
        if let tag = rssModel.titleTag {
            var tagColor: UIColor
            if tag == "targeted" {
                tagColor = .systemBlue
            } else if tag == "active" {
                tagColor = .systemTeal
            } else if tag == "expired" {
                tagColor = .red
            } else if tag == "longrunning" {
                tagColor = .systemBlue
            } else if tag == "upcoming" {
                tagColor = .systemGreen
            } else {
                tagColor = .systemBlue
            }
            let attributesTag: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.white,
                .backgroundColor: tagColor,
            ]
            let tagAttr = NSAttributedString(string: (" "+tag+" ").uppercased(), attributes: attributesTag)
            titleline.append(tagAttr)
        }
        let attributesTitle: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: (darkMode==true ? UIColor.white: UIColor.black),
        ]
        let titleAttr = NSAttributedString(string: " "+(rssModel.title ?? ""), attributes: attributesTitle)
        titleline.append(titleAttr)
        
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
        //comments
        if let comments = rssModel.comments {
            if comments != "0" {
                let attributesComments: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor(white: 0.5, alpha: 1.0),
                ]
                let cms = NSAttributedString(string: ", Comments: "+comments, attributes: attributesComments)
                attr.append(cms)
            }
        }
        
        //html description
        let input = rssModel.description ?? ""
        let html = formattingDescription(input)
        let fullHtml = (darkMode==true ? htmlHeadDark:htmlHeadLight) + html + htmlTail
        let data = Data(fullHtml.utf8)
        let desc = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        
        //categorys
        var cats = [String]()
        if let categories = rssModel.category {
            for cat in categories {
                cats.append(cat.text!)
            }
        }
        
        //votings: up and down
        let voline = NSMutableAttributedString()
        if let up = rssModel.positiveVote, let down = rssModel.negtiveVote {
            let attributesUp: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.systemGreen,
            ]
            let attributesDown: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.systemRed,
            ]
            let upStr = NSAttributedString(string: "+"+up, attributes: attributesUp)
            voline.append(upStr)
            let downStr = NSAttributedString(string: "  -"+down, attributes: attributesDown)
            voline.append(downStr)
        }
        
        let vm = FeedEntry(id: rssModel.guid ?? "",
                           title: titleline,
                           link: rssModel.link ?? "",
                           imageURL: rssModel.imageURL ?? "",
                           subtitle: attr,
                           votings: voline,
                           desc: desc ?? blank,
                           category: cats)
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
    
    func allFeedItemsFor(_ index: Int) -> [FeedEntry] {
        if index == 1 {
            return cheapiesRssItems ?? [FeedEntry]()
        } else if index == 2 {
            return ozbRssItems ?? [FeedEntry]()
        } else if index == 3 {
            return chchlahRssItems ?? [FeedEntry]()
        } else {
            return [FeedEntry]()
        }
    }
    
    let htmlHeadLight = """
    <html>
    <head>
    <style>
    body {
      font-size: 16px;
      color: black;
    }
    </style>
    </head>
    <body>
    """
    
    let htmlHeadDark = """
    <html>
    <head>
    <style>
    body {
      font-size: 16px;
      color: #F8F8FF;
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

//Handling notification
extension NetworkingPipeline: UNUserNotificationCenterDelegate {
    func handleNewIncoming(items: [FeedEntry], for source:String) {
        if items.count > 1 {
            let content = UNMutableNotificationContent()
            content.title = "More new goodies are available at " + source
            content.body = extractSubtitleFrom(items: items)
            content.badge = NSNumber(value: items.count)
            content.sound = .none
            let identifier = "LocalNotification"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
              repeats: false)
            let request = UNNotificationRequest(identifier: identifier,
              content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            print("More new cheapies are available!")
        } else if items.count == 1 {
            let content = UNMutableNotificationContent()
            content.title = "One new goody is available at " + source
            content.body = extractSubtitleFrom(items: items)
            content.badge = NSNumber(value: 1)
            content.sound = .none
            let identifier = "LocalNotification"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
              repeats: false)
            let request = UNNotificationRequest(identifier: identifier,
              content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            print("More new cheapies are available!")
        }
    }
    
    func extractSubtitleFrom(items: [FeedEntry]) -> String {
        if items.count == 1 {
            return items.first!.title.string
        } else {
            let keyDict = items.reduce([String: Int]()) { (result: [String: Int], item: FeedEntry) -> [String: Int] in
                var varResult = result
                for cat in item.category {
                    varResult[cat] = 1
                }
                return varResult
            }
            let keys = Array(keyDict.keys)
            let msg = keys.joined(separator: ", ")
            return "Categories: " + msg
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
