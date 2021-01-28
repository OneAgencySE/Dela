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
    @State var activeArticleId: String?

    private func isFocused(_ article: FeedArticle) -> Bool {
        self.activeArticleId != nil && self.activeArticleId == article.articleId
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    TopBarView()
                        .padding(.horizontal, 20)
                        .opacity(self.activeArticleId == nil ? 1 : 0)

                        ForEach(viewModel.articles, id: \.articleId) { article in
                                GeometryReader { innerGeo in
                                    FeedCardView(article: article, activeArticleId: self.$activeArticleId)
                                        .offset(y: self.isFocused(article) ? -innerGeo.frame(in: .global).minY : 0)
                                        .padding(.horizontal, self.isFocused(article) ? 0 : 20)
                                        .opacity(
                                            self.activeArticleId == nil ||
                                            self.isFocused(article) ? 1 : 0)
                                        .onTapGesture {
                                            self.activeArticleId = article.articleId
                                        }
                                }
                                .frame(height: self.isFocused(article) ?
                                        geometry.size.height +
                                        geometry.safeAreaInsets.top +
                                        geometry.safeAreaInsets.bottom
                                    : min(1200/3, 500)) // This should reflect image height?
                                .animation(
                                    .interactiveSpring(response: 0.55, dampingFraction: 0.65, blendDuration: 0.1))
                        }

                    }
                .frame(width: geometry.size.width)
            }
        }.onDisappear {
            viewModel.stopStreaming()
        }.onAppear {
            viewModel.getFeed()
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        let view = FeedView()
        view.viewModel.articles.append(FeedArticle(articleId: "TheId", likes: 3, comments: 1, imageUrl: URL(string: "preview.jpeg")!))
        return view
    }
}

struct TopBarView: View {

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading) {
                Text(getCurrentDate().uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Today")
                    .font(.largeTitle)
                    .fontWeight(.heavy)

            }

            Spacer()

            AvatarView(image: "preview.jpeg", width: 40, height: 40)

        }
    }

    func getCurrentDate(with format: String = "EEEE, MMM d") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: Date())
    }
}

struct AvatarView: View {
    let image: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Image(image)
            .resizable()
            .frame(width: width, height: height)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
    }
}
