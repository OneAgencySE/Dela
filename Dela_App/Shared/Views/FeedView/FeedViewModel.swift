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
	private let feedClient = FeedClient.shared

	private var startFreshCancellable: AnyCancellable?
	private let feedPublisher = PassthroughSubject<FeedRequest, Never>()

	init() {
		initFeedPublisher()
	}

	func initFeedPublisher() {
		startFreshCancellable = feedPublisher
		.subscribe(on: DispatchQueue.global())
		.flatMap { [unowned self] value in
            feedClient.stream(value)
		}
		.receive(on: DispatchQueue.main)
		.sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    print("The stream is closed")
                case .failure(let error):
                    print("Fatal: ", error)
            }
        }, receiveValue: { [unowned self] value in
            print("Got to recieve a value!!", value)
            images.insert(value)
		})
	}

	func getFeed() {
        // feedPublisher.send(.startFresh(false))
        self.feedClient.streamTest(.startFresh(false)) {[weak self] value in
            guard let self = self else { return }
            print("Got to recieve a value!!", value)
            DispatchQueue.main.async {
                self.images.insert(value)
            }
        }
	}

    func watchedArticle(watched: String) {
        feedPublisher.send(.watchedArticle(watched))
    }

    func setCount(count: Int) {
        feedPublisher.send(.count(count))
    }

	func stopStreaming() {
		feedClient.stopStreaming()
	}
}
