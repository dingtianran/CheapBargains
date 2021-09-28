//
//  Pipeline.swift
//  Cheapiez
//
//  Created by Tianran Ding on 29/09/20.
//

import Foundation
import UserNotifications
import Alamofire
import AEXML
import UIKit

class NetworkingPipeline: NSObject {
    
    //feed: cheapies by default
    static let shared = NetworkingPipeline()
    
    var previousXMLStringData1: Data?
    var previousXMLStringData2: Data?
    var previousXMLStringData3: Data?
    var updatedDate: Date?
    var refreshTimer: Timer
    let dateFormatter: DateFormatter
    
    var cheapiesRssItems: [FeedEntry]?
    var cheapiesKeyBucket = [String]()
    var chchlahRssItems: [FeedEntry]?
    var chchlahKeyBucket = [String]()
    var ozbRssItems: [FeedEntry]?
    var ozbKeyBucket = [String]()
    
    @Published private(set) var refreshFrequency: Double = 0.0
    @Published private(set) var sourceIndex = 1
//    @Published private(set) var cheapiesNewEntries: Int = 0
//    @Published private(set) var ozbNewEntries: Int = 0
//    @Published private(set) var chchlahNewEntries: Int = 0
    @Published private(set) var unreadCounts: [Int: Int] = [Int: Int]()
    
    var darkMode: Bool = false
    {//Whenever title color changed, re-render every titles
        didSet {
            reRenderItems()
        }
    }
    
    override init() {
        self.refreshTimer = Timer()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        self.dateFormatter = dateFormatter
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
    
    func markSourceReadForIndex(_ source: Int) {
        sourceIndex = source
        // Mark unread entries zero after user switched feed
        unreadCounts[source] = 0
//        if source == 1 && cheapiesNewEntries != 0 {
//            cheapiesNewEntries = 0
//        } else if source == 2 && ozbNewEntries != 0{
//            ozbNewEntries = 0
//        } else if source == 3 && chchlahNewEntries != 0 {
//            chchlahNewEntries = 0
//        }
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
            AF.request(sourceFeed1).responseData { [weak self] (response: AFDataResponse<Data>) in
                switch response.result {
                case .success:
                    self?.previousXMLStringData1 = response.value
                    if let newItems = self?.processXMLData(index: 1, xml: response.value) {
                        self?.cheapiesRssItems = newItems
                    }
                case let .failure(error):
                    print(error)
                }
                group.leave()
            }
            //ozbargain
            group.enter()
            let sourceFeed2 = "https://www.ozbargain.com.au/deals/feed"
            AF.request(sourceFeed2).responseData { [weak self] (response: AFDataResponse<Data>) in
                switch response.result {
                case .success:
                    self?.previousXMLStringData2 = response.value
                    if let newItems = self?.processXMLData(index: 2, xml: response.value) {
                        self?.ozbRssItems = newItems
                    }
                case let .failure(error):
                    print(error)
                }
                group.leave()
            }
            //chchlah
            group.enter()
            let sourceFeed3 = "https://www.cheapcheaplah.com/deals/feed"
            AF.request(sourceFeed3).responseData { [weak self] (response: AFDataResponse<Data>) in
                switch response.result {
                case .success:
                    self?.previousXMLStringData3 = response.value
                    if let newItems = self?.processXMLData(index: 3, xml: response.value) {
                        self?.chchlahRssItems = newItems
                    }
                case let .failure(error):
                    print(error)
                }
                group.leave()
            }
            
            // All three feeds are updated & ready to display
            group.notify(queue: DispatchQueue.global()) { [weak self] in
                self?.updatedDate = Date()
                NotificationCenter.default.post(name: Notification.Name("RSSFeedRefreshingReady"), object: nil)
            }
            resetTimerForNextRefresh()
            return false
        } else {
            return true
        }
    }
    
    func reRenderItems() {
        if let newItems = processXMLData(index: 1, xml: previousXMLStringData1) {
            cheapiesRssItems = newItems
        }
        if let newItems = processXMLData(index: 2, xml: previousXMLStringData2) {
            ozbRssItems = newItems
        }
        if let newItems = processXMLData(index: 3, xml: previousXMLStringData3) {
            chchlahRssItems = newItems
        }
    }
    
    private func processXMLData(index: Int, xml: Data?) -> [FeedEntry]? {
        guard let data = xml else { return nil }
        var items = [FeedEntry]()
        var newIncomingBucket = [FeedEntry]()
        do {
            let xmlDoc = try AEXMLDocument(xml: data)
            for child in xmlDoc.root["channel"]["item"].all! {
                //assembly categories
                var categories = [Category]()
                for cate in child["category"].all! {
                    if let domain = cate.attributes["domain"], let text = cate.value {
                        categories.append(Category(domain: domain, text: text))
                    }
                }
                //assembly other RSS entries
                let title = child["title"].value
                let link = child["link"].value
                let desc = child["description"].value
                let creator = child["dc:creator"].value
                let pubDate: Date? = dateFormatter.date(from: child["pubDate"].value ?? "")
                let positiveVote = child["ozb:meta"].attributes["votes-pos"]
                let negtiveVote = child["ozb:meta"].attributes["votes-neg"]
                let comments = child["ozb:meta"].attributes["comment-count"]
                let titleTag = child["ozb:title-msg"].attributes["type"] ?? "active"
                let thumbnail = child["media:thumbnail"].attributes["url"]
                let guid = child["guid"].value
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
        } catch {
            return nil
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
        
        caterForNotification()
        
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
                let cms = NSAttributedString(string: ", Comments: ", attributes: attributesComments)
                attr.append(cms)
                let attributesCommentsCount: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.orange,
                ]
                let cmsCount = NSAttributedString(string: "\(comments)", attributes: attributesCommentsCount)
                attr.append(cmsCount)
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
    func handleNewIncoming(items: [FeedEntry], for source: String) {
        if source == "Cheapies" {
            // New entries from cheapies
            unreadCounts[1] = items.count
        } else if source == "OzBargain" {
            // New entries from ozb
            unreadCounts[2] = items.count
        } else if source == "CheapcheapLah" {
            // New entries from chchlah
            unreadCounts[3] = items.count
        }
    }
    
    func caterForNotification() {
        // Figure out what notification fit to send
        let content = UNMutableNotificationContent()
        let identifier = "FeedUpdated"
        content.badge = NSNumber(value: Array(unreadCounts).count)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let cheapiesNewEntries = unreadCounts[1] ?? 0
        let ozbNewEntries = unreadCounts[2] ?? 0
        let chchlahNewEntries = unreadCounts[3] ?? 0
        if cheapiesNewEntries > 0 && ozbNewEntries == 0 && chchlahNewEntries == 0 {
            content.title = "New goodies arrived at \"Cheapies\""
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else if cheapiesNewEntries == 0 && ozbNewEntries > 0 && chchlahNewEntries == 0 {
            content.title = "New goodies arrived at \"OzBargain\""
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else if cheapiesNewEntries == 0 && ozbNewEntries == 0 && chchlahNewEntries > 0 {
            content.title = "New goodies arrived at \"CheapcheapLah\""
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else if cheapiesNewEntries > 0 && ozbNewEntries > 0 && chchlahNewEntries == 0 {
            content.title = "New goodies arrived at \"Cheapies\" and \"OzBargain\""
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else if cheapiesNewEntries > 0 && ozbNewEntries == 0 && chchlahNewEntries > 0 {
            content.title = "New goodies arrived at \"Cheapies\" and \"CheapcheapLah\""
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else if cheapiesNewEntries == 0 && ozbNewEntries > 0 && chchlahNewEntries > 0 {
            content.title = "New goodies arrived at \"OzBargain\" and \"CheapcheapLah\""
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else if cheapiesNewEntries > 0 && ozbNewEntries > 0 && chchlahNewEntries > 0 {
            content.title = "New goodies arrived at \"OzBargain\" and \"Cheapies\" and \"CheapcheapLah\""
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
}
