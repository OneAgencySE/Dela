//
//  FeedViewModel.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import Combine

class FeedViewModel: ObservableObject {

	private let feedClient = FeedClient.shared

	private var startFreshCancellable: AnyCancellable?
	private let startFresh = PassthroughSubject<Bool, Never>()

	init() {
		initFeedPublisher()
	}

	func initFeedPublisher() {
		startFreshCancellable = startFresh
		.subscribe(on: DispatchQueue.global())
		.flatMap { [unowned self] value in
			feedClient.stream(startFresh: value)
		}
		.receive(on: DispatchQueue.main)
		.sink(receiveCompletion: { _ in }, receiveValue: { [unowned self] _ in
			self.startFresh.send(false)
		})
	}

	func getFeed() {
		startFresh.send(true)
		startFresh.send(false)
	}

	func stopStreaming() {
		feedClient.stopStreaming()
	}
}
