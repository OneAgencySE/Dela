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
