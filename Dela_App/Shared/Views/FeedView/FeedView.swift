//
//  FeedView.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import SwiftUI
import Kingfisher

struct FeedView: View {

	@ObservedObject var viewModel = FeedViewModel()

    var body: some View {
		VStack {

            HStack {
                Spacer()
                Button("Get some articles") {
                    viewModel.getFeed()
                }
                Spacer()
                Button("Stop streaming") {
                    viewModel.stopStreaming()
                }
                Spacer()
            }
            ScrollView {
                LazyVStack {
                    ForEach(Array(viewModel.images), id: \.self) { article in

                        if article.image != nil {
                            KFImage(source: .provider(RawImageDataProvider(data: article.image!, cacheKey: article.articleId )))
                                .resizable()
                                .frame(height: 200)
                                .aspectRatio(contentMode: .fit).onTapGesture {
                                    viewModel.watchedArticle(watched: article.articleId)
                                }
                        }
                        Text(article.articleId )
                    }
                }
            }

		}
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
