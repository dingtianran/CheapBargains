//
//  FeedModels.swift
//  Cheapiez
//
//  Created by Tianran Ding on 30/09/21.
//

import Foundation

struct Feed: Hashable, Codable, Identifiable {
    var id: Int
    let feedName: String
    let feedFlag: String
}
