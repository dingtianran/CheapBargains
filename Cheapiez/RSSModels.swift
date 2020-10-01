//
//  RSSModels.swift
//  Cheapiez
//
//  Created by Tianran Ding on 24/09/20.
//

import Foundation

struct Category {
    let domain: String?
    let text: String?
}

struct RSSItem {
    let title: String?
    let link: String?
    let description: String?
    let creator: String?
    let pubDate: Date?
    let imageURL: String?
    let category: [Category]?
    let guid: String?
    
    private static let dateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd hh:mm:ss"
            return df
    }()
}

struct FeedEntry {
    let title: String
    let link: String
    let imageURL: String
    let subtitle: NSAttributedString
    let desc: NSAttributedString
    let category: [String]
}
