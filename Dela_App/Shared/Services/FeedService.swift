//
//  FeedClient.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import GRPC
import Combine
import Kingfisher

final class FeedService: StreamingService {

    private var imageCache = [String: (data: Data, isDone: Bool)]()
    private var articleCache = [String: Feed_FeedArticle]()

    private var state: State = .idle
    internal var client: Feed_FeedHandlerClient?
    let feedResponseSubject = PassthroughSubject<FeedArticle, UserInfoError>()

    static let shared = FeedService()

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

    fileprivate func sendResponse(_ aricleId: String) {

        guard articleCache.keys.contains(aricleId) &&
                imageCache.keys.contains(aricleId) &&
                imageCache[aricleId]!.isDone else {
            return
        }

        ImageCache.default.storeToDisk(imageCache[aricleId]!.data,
                                       forKey: aricleId,
                          processorIdentifier: "FeedServiceCaching",
                          expiration: StorageExpiration.seconds(3600),
                          callbackQueue: .mainCurrentOrAsync) { [self] _ in

            let result = FeedArticle(
                articleId: aricleId,
                likes: Int(self.articleCache[aricleId]!.likes) ,
                comments: Int(self.articleCache[aricleId]!.comments),
                image: aricleId
            )

            feedResponseSubject.send(result)
            imageCache[aricleId] = nil
            articleCache[aricleId] = nil
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
                            articleCache[article.articleID] = article
                            sendResponse(article.articleID)
                        case .image(let image):
                            if image.isDone {
                                imageCache[image.articleID]?.isDone = true
                                sendResponse(image.articleID)
                            } else {
                                if !imageCache.keys.contains(image.articleID) {
                                    imageCache[image.articleID] = (Data(), false)
                                }

                                imageCache[image.articleID]?.data.append(image.chunkData)
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
