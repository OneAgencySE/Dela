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
//            ScrollView {
//                LazyVStack {
//                    ForEach(viewModel.images, id: \.self) { image in
//                        KFImage(source: .provider(RawImageDataProvider(data: image.image, cacheKey: image.articleId )))
//                            .resizable()
//                            .frame(height: 200)
//                            .aspectRatio(contentMode: .fit).onTapGesture {
//                                viewModel.watchedArticle(watched: image.articleId)
//                            }
//                        Text(image.articleId )
//                    }
//                }
//            }

		}
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
