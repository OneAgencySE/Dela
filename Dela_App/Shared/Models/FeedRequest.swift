//
//  Feed.swift
//  Dela
//
//  Created by Alexander Herlin on 2021-01-15.
//

import Foundation

enum FeedRequest {
    case count(Int)
    case startFresh(Bool)
    case watchedArticle(String)
}

extension FeedRequest {
    func intoGen() -> Feed_SubRequest {

        switch self {
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
