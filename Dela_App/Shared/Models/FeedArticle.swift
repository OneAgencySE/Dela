//
//  FeedArticle.swift
//  Dela (iOS)
//
//  Created by Joacim Nidén on 2021-01-14.
//

import Foundation

struct FeedArticle: Hashable {
	let articleId: String
	let likes: Int
	let comments: Int
	let image: Data
}

extension FeedArticle {

	init(response: Feed_SubResponse) {
		articleId = response.info.articleID
		likes = Int(response.info.likes)
		comments = Int(response.info.comments)
		image = response.image.chunkData
	}

}
