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

            Stepper(value: $viewModel.count, in: 0...15, step: 1) {
                Text("Count: \(viewModel.count)")
            }

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

                        ForEach(viewModel.articles, id: \.articleId) { article in
                            Divider()

                            if let image = viewModel.images.first { img in
                                img.articleId == article.articleId
                            } {
                                KFImage(source: .provider(
                                            RawImageDataProvider(data: image.image, cacheKey: article.articleId )))
                                    .resizable()
                                    .frame(height: 200)
                                    .aspectRatio(contentMode: .fit).onTapGesture {
                                        viewModel.watchedArticle(watched: article.articleId)
                                    }
                            }

                            Text(article.articleId )
                            Text("\(article.comments)")
                            Text("\(article.likes)" )
                            Divider()
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
