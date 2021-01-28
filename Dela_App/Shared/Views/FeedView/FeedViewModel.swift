//
//  FeedViewModel.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import Combine

class FeedViewModel: ObservableObject {

    @Published var articles: [FeedArticle] = Array()

    private let count: UInt32 = 10 // Standard, could be something else
    private let feedService = FeedService.shared
    private var cancellableFeed: AnyCancellable?

    init() {
        initCancellableFeed()
    }

    private func initCancellableFeed() {
        cancellableFeed =
            feedService.feedResponseSubject
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { comletion in
                switch comletion {
                    case .finished:
                        print("End of stream")
                    case .failure(let err):
                        print("Error: ", err)
                }
            } receiveValue: { [self] article in
                if !articles.contains(where: { art in art.articleId == article.articleId }) {
                    articles.append(article)
                }
            }
    }

	func getFeed() {
        print("Calling for articles")
        feedService.sendRequest(.fetch(count))
	}

    func watchedArticle(watched: String) {
        feedService.sendRequest(.watchedArticle(watched))
    }

	func stopStreaming() {
		feedService.stopStreaming()
	}
}
