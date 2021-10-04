//
//  FeedSourcesView.swift
//  Cheapiez
//
//  Created by Tianran Ding on 19/09/21.
//

import SwiftUI
import Combine

struct FeedSourcesView: View {
    @StateObject var viewModel = FeedSourceViewModel()
    @State var selectedFeed: FeedSource?
    
    var body: some View {
        List {
            Section(header: Text("Feed / Sources")) {
                ForEach(viewModel.feeds) { feed in
                    FeedCell(feed: feed, selectedFeed: $selectedFeed)
                }
            }
        }.onAppear {
            selectedFeed = viewModel.feeds.first
        }
        .listStyle(GroupedListStyle())
        .ignoresSafeArea()
    }
}

struct FeedCell: View {
    let feed: FeedSource
    @Binding var selectedFeed: FeedSource?

    var body: some View {
        HStack {
            Text(feed.feedFlag)
            Text(feed.feedName)
            Spacer()
            Text(feed.unread > 0 ? "\(feed.unread)": "").foregroundColor(.secondary)
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
