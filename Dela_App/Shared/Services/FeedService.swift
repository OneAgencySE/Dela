//
//  FeedClient.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation
import GRPC
import Combine
import SwiftUI

final class FeedService: StreamingService {

    private var imageCache = [String: Data]()
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

    fileprivate func sendResponse(_ image: (Feed_FeedImage)) {
        let img =  imageCache[image.articleID]!
        let art = articleCache[image.articleID]!

        let result = FeedArticle(
            articleId: art.articleID,
            likes: Int(art.likes) ,
            comments: Int(art.comments),
            image: UIImage(data: img)!)

        feedResponseSubject.send(result)

        // Keep is clean in here
        imageCache[image.articleID] = nil
        articleCache[image.articleID] = nil
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
                            if !articleCache.keys.contains(article.articleID) {
                                articleCache[article.articleID] = article
                            } else {
                                print("Invalid Contract: Duplicate articles")
                            }
                        case .image(let image):
                            if image.isDone {
                                guard articleCache.keys.contains(image.articleID) &&
                                        imageCache.keys.contains(image.articleID) else {
                                    print("Invalid Contract: Image done before Article")
                                    return
                                }

                                sendResponse(image)
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
