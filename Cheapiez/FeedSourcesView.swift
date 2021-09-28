//
//  FeedSourcesView.swift
//  Cheapiez
//
//  Created by Tianran Ding on 19/09/21.
//

import SwiftUI

struct Feed: Hashable, Codable, Identifiable {
    var id: Int
    let feedName: String
    let feedFlag: String
}

class FeedList: ObservableObject {
    @Published var feeds: [Feed]
    
    init(source: [Feed]) {
        self.feeds = source
    }
}

struct FeedSourcesView: View {
    @State var selectedFeed: Feed?
    @ObservedObject var list: FeedList
    
    init() {
        let decoder = JSONDecoder()
        let path = Bundle.main.path(forResource: "Config", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonData = try! decoder.decode([Feed].self, from: data)
        let list = FeedList(source: jsonData)
        self.selectedFeed = jsonData.first
        self.list = list
    }
    
    var body: some View {
        List {
            Section(header: Text("Feed / Sources")) {
                ForEach(list.feeds) { feed in
                    FeedCell(feed: feed,
                             selectedFeed: self.$selectedFeed,
                             unreadCount: NetworkingPipeline.shared.unreadCounts[feed.id] ?? 0)
                    
                }
            }
        }
        .listStyle(GroupedListStyle())
        .ignoresSafeArea()
    }
}

struct FeedCell: View {
    let feed: Feed
    @Binding var selectedFeed: Feed?
    let unreadCount: Int

    var body: some View {
        HStack {
            Text(feed.feedFlag)
            Text(feed.feedName)
            Spacer()
            Text(unreadCount > 0 ? "\(unreadCount)": "")
        }
        .frame(height: 40)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(feed.id == selectedFeed?.id ? Color.orange : Color.clear))
        .onTapGesture {
            self.selectedFeed = feed
            NetworkingPipeline.shared.markSourceReadForIndex(feed.id)
        }
    }
}

struct FeedSourcesView_Previews: PreviewProvider {
    static var previews: some View {
        return FeedSourcesView()
    }
}
