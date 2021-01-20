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
    @Published var images: [FeedImage] = Array()
    @Published var count: UInt32 = 5

    private let feedService = FeedService()
    private var cancellableFeed: AnyCancellable?

    init() {
        initCancellableFeed()
    }

    private func initCancellableFeed() {
        cancellableFeed =
            feedService.subject
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { comletion in
                switch comletion {
                    case .finished:
                        print("End of stream")
                    case .failure(let err):
                        print("Error: ", err)
                }
            } receiveValue: { [self] response in
                switch response {
                    case .article(let article):
                        print("Article")
                        articles.append(article)
                    case .image(let image):
                        print("Image")
                        images.append(image)
                }
            }
    }

	func getFeed() {
        feedService.sendRequest(.fetch(count))
	}

    func watchedArticle(watched: String) {
        feedService.sendRequest(.watchedArticle(watched))
    }

	func stopStreaming() {
		feedService.stopStreaming()
	}
}
