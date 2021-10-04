//
//  FeedSourceViewModel.swift
//  Cheapiez
//
//  Created by Tianran Ding on 1/10/21.
//

import Foundation
import Combine

struct FeedSource: Identifiable {
    let id: Int
    let feedFlag: String
    let feedName: String
    var unread: Int = 0
    
    init(id: Int, flag: String, name: String) {
        self.id = id
        self.feedName = name
        self.feedFlag = flag
    }
}

class FeedSourceViewModel: ObservableObject {
    @Published private(set) var feeds = [FeedSource]()
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        let decoder = JSONDecoder()
        let path = Bundle.main.path(forResource: "Config", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonData = try! decoder.decode([Feed].self, from: data)
        jsonData.forEach { feed in
            let entity = FeedSource(id: feed.id, flag: feed.feedFlag, name: feed.feedName)
            feeds.append(entity)
        }
        
        NetworkingPipeline.shared.$unreadCounts.sink { counterDict in
            for feedIndex in counterDict.keys {
                if let newCount = counterDict[feedIndex] {
                    var feed = self.feeds[feedIndex - 1]
                    feed.unread = newCount
                    self.feeds[feedIndex - 1] = feed
                }
            }
        }.store(in: &cancellables)
    }
}
