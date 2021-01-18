//
//  FeedViewModel.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import Combine

class FeedViewModel: ObservableObject {

    @Published var images: Set<IHaveNoNameForThis> = Set<IHaveNoNameForThis>()

	private let feedClient = FeedClient.shared
    private let feedPublisher = PassthroughSubject<FeedRequest, UserInfoError>()
    private var cancellableFeed: AnyCancellable?

	init() {
//        cancellableFeed = feedPublisher
//            .subscribe(on: DispatchQueue.global())
//            .receive(on: DispatchQueue.main)
//            .flatMap { [unowned self] value in
//
//                // feedClient.stream(value, )
//            }
//            .sink { (completion) in
//                switch completion {
//                    case .finished:
//                        print("Finnished with the feed-stream")
//                    case .failure(let fail):
//                        print("Failure in feed: ", fail)
//
//                }
//            } receiveValue: { (feedResponse) in
//                print("Sinked: ", feedResponse)
//            }
	}

	func getFeed() {
        feedClient.stream(.startFresh(true)) { [self] res in
            DispatchQueue.main.async {

                switch res {
                    case .article(let article):

                        images.insert(IHaveNoNameForThis(articleId: article.articleId, likes: article.likes, comments: article.comments, image: nil))
                    case .image(let image):
                        let found = images.first {value in
                            value.articleId == image.articleId
                        }

                        if let article = found {
                            images.insert(IHaveNoNameForThis(articleId: article.articleId, likes: article.likes, comments: article.comments, image: image.image))

                        }
                }
            }
            print("res: ", res)
        }

	}

    func watchedArticle(watched: String) {
        feedPublisher.send(.watchedArticle(watched))
    }

    func setCount(count: Int) {
        feedPublisher.send(.count(count))
    }

	func stopStreaming() {
        cancellableFeed?.cancel()
	}
}
