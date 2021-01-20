//
//  FeedClient.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import GRPC
import Combine

final class FeedService: StreamingService {

    private var imageCache = [String: Data]()
    private var state: State = .idle
    internal var client: Feed_FeedHandlerClient?
    let feedResponseSubject = PassthroughSubject<FeedResponse, UserInfoError>()

    init() {
        self.initClientStateHandler()
    }

    enum State {
        case idle
        case streaming(BidirectionalStreamingCall<Feed_SubRequest, Feed_SubResponse>)
    }

    func renewClient(_ remoteChannel: RemoteChannel) {
        self.client = Feed_FeedHandlerClient(
            channel: RemoteChannel.shared.clientConnection,
            defaultCallOptions: RemoteChannel.shared.defaultCallOptions)
    }

    func disconnect() {
        self.state = .idle
    }

    func sendRequest(_ req: FeedRequest) {
        self.stream(req)
    }

    func stopStreaming() {
        switch self.state {
            case .idle:
                return
            case let .streaming(stream):

                stream.sendEnd(promise: nil)
				stream.cancel(promise: nil)
                self.state = .idle
        }
    }

    private func stream(_ request: FeedRequest) {
        switch state {
            case .idle:
                print("idle")

                guard self.client != nil else {
                    return
                }

                let call = client!.subscribe { [self] response in
                    switch response.value {
                        case .info(let article):
                            feedResponseSubject.send((.article(FeedArticle(article))))
                        case .image(let image):
                            if image.isDone {
                                if let img = imageCache[image.articleID] {
                                    feedResponseSubject.send(
                                        .image(FeedImage(articleId: image.articleID, image: img)))
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
