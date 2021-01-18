//
//  FeedArticle.swift
//  Dela (iOS)
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation

enum FeedResponse {
    case article(FeedArticle)
    case image(FeedImage)
}

struct FeedArticle: Hashable {
	let articleId: String
	let likes: Int
	let comments: Int
}

struct FeedImage {
    let articleId: String
    let image: Data
}

extension FeedArticle {

    init(_ response: Feed_FeedArticle) {
        articleId = response.articleID
        likes = Int(response.likes)
        comments = Int(response.comments)
    }
}
