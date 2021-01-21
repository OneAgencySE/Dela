//
//  Feed.swift
//  Dela
//
//  Created by Alexander Herlin on 2021-01-15.
//

import Foundation

enum FeedRequest {
    case fetch(UInt32)
    case watchedArticle(String)
}

extension FeedRequest {
    func intoGen() -> Feed_SubRequest {

        switch self {
            case .fetch(let count):
                return Feed_SubRequest.with {
                    $0.fetch = count
                }
            case .watchedArticle(let watched):
                return Feed_SubRequest.with {
                    $0.watchedArticleID = watched
                }
        }

    }
}
