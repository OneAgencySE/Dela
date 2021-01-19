//
//  FeedClient.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import GRPC
import Combine

class FeedService {
    enum State {
        case idle
        case streaming(BidirectionalStreamingCall<Feed_SubRequest, Feed_SubResponse>)
    }

    private var state: State = .idle

    private var imageCache = [String: Data]()

    private static let client = Feed_FeedHandlerClient(
        channel: RemoteChannel.shared.clientConnection,
        defaultCallOptions: RemoteChannel.shared.defaultCallOptions)

    let subject = PassthroughSubject<FeedResponse, UserInfoError>()

    init() {
        print("New FeedService!!")
        _ = subject.handleEvents(receiveCancel: {
            self.stopStreaming()
        })
    }

    func sendRequest(_ req: FeedRequest) {
        self.stream(req)
    }

    private func stopStreaming() {
        switch self.state {
            case .idle:
                return
            case let .streaming(stream):
                stream.sendEnd(promise: nil)
                self.state = .idle
        }
    }

    private func stream(_ request: FeedRequest) {
        switch state {
            case .idle:
                print("idle")

                let call = FeedService.client.subscribe { [self] response in
                    switch response.value {
                        case .info(let article):
                            subject.send((.article(FeedArticle(article))))
                        case .image(let image):
                            if image.isDone {
                                if let img = imageCache[image.articleID] {
                                    subject.send((.image(FeedImage(articleId: image.articleID, image: img))))
                                    imageCache[image.articleID] = nil
                                }
                            } else {
                                if !imageCache.keys.contains(image.articleID) {
                                    imageCache[image.articleID] = Data()
                                }
                                imageCache[image.articleID]?.append(image.chunkData)
                            }
                        case .none:
                            print("No data")
                    }
                }

                state = .streaming(call)

                call.sendMessage(request.intoGen(), promise: nil)

            case .streaming(let call):
                print("Streaming")
                call.sendMessage(request.intoGen(), promise: nil)
        }
    }

}
