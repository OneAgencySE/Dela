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
import UIKit

final class FeedService: StreamingService {

    class StreamCache {
        var imageCache = [String: Feed_FeedImage]()
        var articleCache = [String: Feed_FeedArticle]()

        func remove(_ aricleId: String) {
            imageCache[aricleId] = nil
            articleCache[aricleId] = nil
        }
    }

    private var streamCache = StreamCache()
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
        guard streamCache.articleCache.keys.contains(aricleId) &&
                streamCache.imageCache.keys.contains(aricleId) &&
                streamCache.imageCache[aricleId]!.isDone else {
            return
        }

        let image = streamCache.imageCache[aricleId]!
        ImageCacheHandler().cacheImage(
            image: image.chunkData, fileName: image.fileName) { [self] imagePath in
            let result = FeedArticle(
                articleId: aricleId,
                likes: Int(streamCache.articleCache[aricleId]!.likes) ,
                comments: Int(streamCache.articleCache[aricleId]!.comments),
                imageUrl: imagePath
            )
            streamCache.remove(aricleId)

            DispatchQueue.main.async {
                feedResponseSubject.send(result)
            }
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
                            streamCache.articleCache[article.articleID] = article
                            sendResponse(article.articleID)
                        case .image(let image):
                            if image.isDone {
                                streamCache.imageCache[image.articleID]?.isDone = true
                                sendResponse(image.articleID)
                            } else {
                                if !streamCache.imageCache.keys.contains(image.articleID) {
                                    streamCache.imageCache[image.articleID] = Feed_FeedImage.with({
                                        $0.articleID = image.articleID
                                        $0.fileExt = image.fileExt
                                        $0.fileName = image.fileName
                                    })
                                }

                                streamCache.imageCache[image.articleID]?.chunkData.append(image.chunkData)
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
