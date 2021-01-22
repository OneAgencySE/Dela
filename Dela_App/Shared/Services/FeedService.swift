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

    // TODO: This should not be an memory based item, it should store to disk
    // Perhaps use kingfisher for it
    private var imageCache: (String, Data)?
    private var articleCache: Feed_FeedArticle?

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

    fileprivate func sendResponse() {
        guard articleCache != nil || imageCache != nil else {
            return
        }

        ImageCache.default.storeToDisk(self.imageCache!.1,
                                       forKey: self.articleCache!.articleID,
                          processorIdentifier: "FeedServiceCaching",
                          expiration: StorageExpiration.seconds(3600),
                          callbackQueue: .mainCurrentOrAsync) { [self] _ in

            let result = FeedArticle(
                articleId: self.articleCache!.articleID,
                likes: Int(self.articleCache!.likes) ,
                comments: Int(self.articleCache!.comments)
            )

            feedResponseSubject.send(result)

            // Keep is clean in here
            imageCache = nil
            articleCache = nil
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
                            articleCache = article
                        case .image(let image):
                            if image.isDone {
                                guard articleCache != nil else {
                                    print("Invalid Contract: Image done before Article")
                                    return
                                }

                                sendResponse()
                            } else {
                                if imageCache == nil {
                                    imageCache = (image.articleID, Data())
                                }
                                imageCache!.1.append(image.chunkData)
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
