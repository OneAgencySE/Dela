//
//  FeedClient.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import GRPC
import Combine

private class FeedClient {
    static let client = Feed_FeedHandlerClient(
        channel: RemoteChannel.shared.clientConnection,
        defaultCallOptions: RemoteChannel.shared.defaultCallOptions)
}

class FeedPublisher: Publisher {
    typealias Output = FeedResponse
    typealias Failure = Error

    private let client = FeedClient.client

    private let request: FeedRequest

    init(request: FeedRequest) {
         self.request = request
    }

    func receive<S>(subscriber: S)
        where S: Subscriber, FeedPublisher.Failure == S.Failure, FeedPublisher.Output == S.Input {
        let subscription = FeedSubscription(request: request, sub: subscriber, client: client)
        subscriber.receive(subscription: subscription)
    }
 }

class FeedSubscription<S: Subscriber>: Subscription where S.Input == FeedResponse, S.Failure == Error {
    private var state: State = .idle

    private let client: Feed_FeedHandlerClient
    private let request: FeedRequest
    private var subscriber: S?

    init(request: FeedRequest, sub: S, client: Feed_FeedHandlerClient) {
        self.request = request
        self.subscriber = sub
        self.client = client
        sendRequest()
    }

    enum State {
        case idle
        case streaming(BidirectionalStreamingCall<Feed_SubRequest, Feed_SubResponse>)
    }

    func request(_ demand: Subscribers.Demand) {

    }

    func cancel() {
        switch self.state {
            case .idle:
                return
            case let .streaming(stream):
                stream.sendEnd(promise: nil)
                self.state = .idle
        }
    }

    private func sendRequest() {
        switch state {
            case .idle:
                print("idle")

                var imageBuffer = Data()
                var articleBuffer: FeedArticle?

                let call = self.client.subscribe { [self] response in
                    switch response.value {
                        case .info(let article):
                            articleBuffer = FeedArticle(article)
                           _ = subscriber?.receive(.article(articleBuffer!))
                        case .image(let image):
                            if image.isDone && articleBuffer?.articleId != nil {
                                _ = subscriber?.receive(
                                    .image(FeedImage.init(articleId: articleBuffer!.articleId, image: imageBuffer)))
                            } else {
                                imageBuffer.append(image.chunkData)
                            }
                        case .none:
                            print("Noo")
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
