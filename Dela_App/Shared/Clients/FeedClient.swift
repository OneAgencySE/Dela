//
//  FeedClient.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import GRPC
import NIO
import Combine

class FeedClient {

	enum State {
		case idle
		case streaming(BidirectionalStreamingCall<Feed_SubRequest, Feed_SubResponse>)
	}

	private let client: Feed_FeedHandlerClient
	private let channel: ClientConnection
	private let group: MultiThreadedEventLoopGroup

	// Track if we are streaming or not
	private var state: State = .idle

	static var shared = FeedClient()

	init() {
		group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		channel = ClientConnection.insecure(group: group)
			.withConnectionReestablishment(enabled: false)
			.connect(host: InfoKey.apiUrl.value, port: Int(InfoKey.apiPort.value) ?? 0)
		client = Feed_FeedHandlerClient(channel: channel)

		print("Adress: \(InfoKey.apiUrl.value):\(Int(InfoKey.apiPort.value) ?? 0)")
		print("Connection Status=>:\(channel.connectivity.state)")
	}

	func stream(startFresh: Bool = true) -> AnyPublisher<FeedArticle, UserInfoError> {

		Future<FeedArticle, UserInfoError> { [unowned self] promise in
			switch self.state {
				case .idle:
					var feedResponse = Feed_SubResponse()
					let call = self.client.subscribe { response in
						switch response.value {
							case .info(let article):
								print(article)
								feedResponse.info.articleID = article.articleID
								feedResponse.info.comments = article.comments
								feedResponse.info.likes = article.likes

							case .image(let image):
								print("image: ", image)
								if feedResponse.image.isDone {
									let article = FeedArticle(response: feedResponse)
									return promise(.success(article))
								} else {
									feedResponse.image.chunkData += image.chunkData
								}

							default:
								break
						}
					}

					self.state = .streaming(call)

					let request = Feed_SubRequest.with {
						$0.startFresh = startFresh
					}

					call.sendMessage(request, promise: nil)

				case .streaming(let call):

					// If returning from idle, send...

					let request = Feed_SubRequest.with {
						$0.startFresh = startFresh
					}

					call.sendMessage(request, promise: nil)

			}
		}.eraseToAnyPublisher()
	}

	func stopStreaming() {
		// Send end message to the stream
		switch self.state {
		case .idle:
		  return
		case let .streaming(stream):
		  stream.sendEnd(promise: nil)
		  self.state = .idle
		}
	  }

	func getFeed() -> AnyPublisher<FeedArticle, UserInfoError> {

		return Future<FeedArticle, UserInfoError> { [unowned self] promise in

			let request = Feed_SubRequest.with {
				$0.startFresh = true
			}

			var feedResponse = Feed_SubResponse()

			let bidirectionalStreaming = self.client.subscribe { response in

				switch response.value {
					case .info(let article):
						feedResponse.info.articleID = article.articleID
						feedResponse.info.comments = article.comments
						feedResponse.info.likes = article.likes

					case .image(let image):
						if feedResponse.image.isDone {
							// TODO: Show in UI
							let article = FeedArticle(response: feedResponse)
							return promise(.success(article))
						} else {
							feedResponse.image.chunkData += image.chunkData
						}

					default:
						break
				}
			}

			bidirectionalStreaming.sendMessage(request, promise: nil)

		}.eraseToAnyPublisher()

	}
}
