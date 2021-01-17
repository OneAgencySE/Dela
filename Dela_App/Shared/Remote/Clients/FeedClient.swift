//
//  FeedClient.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import GRPC
import Combine

class FeedClient {

	enum State {
		case idle
		case streaming(BidirectionalStreamingCall<Feed_SubRequest, Feed_SubResponse>)
	}

    private var client: Feed_FeedHandlerClient

	// Track if we are streaming or not
	private var state: State = .idle

	static var shared = FeedClient()
    private let queue = DispatchQueue(label: "thread-streaming")

     init() {
        let remote = RemoteChannel.shared

        client = Feed_FeedHandlerClient(channel: remote.clientConnection, defaultCallOptions: remote.defaultCallOptions)
	}

	func stream(_ req: FeedRequest) -> AnyPublisher<FeedArticle, UserInfoError> {

		Future<FeedArticle, UserInfoError> { [unowned self] promise in
			switch self.state {
				case .idle:
					var feedResponse = Feed_SubResponse()
					let call = self.client.subscribe { response in
						switch response.value {
							case .info(let article):
								feedResponse.info.articleID = article.articleID
								feedResponse.info.comments = article.comments
								feedResponse.info.likes = article.likes

							case .image(let image):

								if image.isDone {
									let article = FeedArticle(response: feedResponse)
                                    print("done")
									return promise(.success(article))
								} else {
									feedResponse.image.chunkData += image.chunkData
								}

							default:
								break
						}
                    }

					self.state = .streaming(call)
					call.sendMessage(buildRequest(req), promise: nil)

				case .streaming(let call):
					call.sendMessage(buildRequest(req), promise: nil)

			}
		}.eraseToAnyPublisher()
	}

    func streamTest(_ req: FeedRequest, completion: ((FeedArticle) -> Void)? = nil) {
        queue.async { [self] in

            switch self.state {
                case .idle:
                    var feedResponse = Feed_SubResponse()
                    let call = self.client.subscribe { response in
                        switch response.value {
                            case .info(let article):
                                feedResponse.info.articleID = article.articleID
                                feedResponse.info.comments = article.comments
                                feedResponse.info.likes = article.likes

                            case .image(let image):
                                if image.isDone {
                                    let article = FeedArticle(response: feedResponse)
                                    completion?(article)
                                } else {
                                    feedResponse.image.chunkData += image.chunkData
                                }
                            case .none:
                                print("Noo")
                        }
                    }

                    self.state = .streaming(call)
                    call.sendMessage(buildRequest(req), promise: nil)

                case .streaming(let call):
                    call.sendMessage(buildRequest(req), promise: nil)
            }

        }
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

    private func buildRequest(_ req: FeedRequest) -> Feed_SubRequest {

        switch req {
            case .count(let count):
                return Feed_SubRequest.with {
                    $0.count = Int32(count)
                }
            case .startFresh(let isRefreshing):
                return Feed_SubRequest.with {
                    $0.startFresh = isRefreshing
                }
            case .watchedArticle(let watched):
                return Feed_SubRequest.with {
                    $0.watchedArticleID = watched
                }
        }

    }
}
