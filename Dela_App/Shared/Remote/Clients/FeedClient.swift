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

    private var state: State = .idle

    private static let client = Feed_FeedHandlerClient(
        channel: RemoteChannel.shared.clientConnection,
        defaultCallOptions: RemoteChannel.shared.defaultCallOptions)

    static let shared = FeedClient()

    init() {}

    func stopStreaming() {
        switch self.state {
            case .idle:
                return
            case let .streaming(stream):
                stream.sendEnd(promise: nil)
                self.state = .idle
        }
    }

    func stream(_ request: FeedRequest, completion: ((FeedResponse) -> Void)? = nil) {
            switch state {
                case .idle:
                    print("idle")

                    var imageBuffer = Data()
                    var articleBuffer: FeedArticle?

                    let call = FeedClient.client.subscribe { response in
                        switch response.value {
                            case .info(let article):
                                articleBuffer = FeedArticle(article)
                                completion?(FeedResponse.article(articleBuffer!))

                            case .image(let image):
                                if image.isDone && articleBuffer?.articleId != nil {
                                    completion?(
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
