//
//  FeedViewModel.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import Combine

class FeedViewModel: ObservableObject {

    @Published var images: Set<FeedArticle> = Set<FeedArticle>()
	// private let feedClient = FeedClient.shared

    private let feedPublisher = PassthroughSubject<FeedRequest, Never>()

    private var cancellable: AnyCancellable?
    private let publisher = FeedPublisher(request: .startFresh(false))

	init() {
        cancellable = publisher
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                switch completion {
                    case .finished:
                        print("Finnished with the feed-stream")
                    case .failure(let fail):
                        print("Failure in feed: ", fail)

                }
            } receiveValue: { (feedResponse) in
                print("Sinked: ", feedResponse)
            }
	}

	func getFeed() {
        print("Already doing that")
	}

    func watchedArticle(watched: String) {
        
        feedPublisher.send(.watchedArticle(watched))
    }

    func setCount(count: Int) {
        feedPublisher.send(.count(count))
    }

	func stopStreaming() {
        cancellable?.cancel()
	}
}
