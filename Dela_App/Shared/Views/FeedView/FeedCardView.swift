//
//  FeedCardView.swift
//  Dela
//
//  Created by Alexander Herlin on 2021-01-21.
//

import Foundation
import Combine
import SwiftUI

struct FeedCardView: View {
    let article: FeedArticle
    let index: Int
    @Binding var activeIndex: Int?
    @State private var dragOffset = CGSize.zero

    private func isFocused() -> Bool {
        activeIndex != nil && activeIndex == index
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    VStack(alignment: .leading) {
                        Image(uiImage: self.article.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: self.isFocused() ?
                                    geometry.size.height * 0.7 :
                                    min(self.article.image.size.height/3, 500))
                            .border(Color(.sRGB,
                                          red: 150/255, green: 150/255,
                                          blue: 150/255, opacity: 0.1),
                                    width: self.isFocused() ? 0 : 1)
                            .cornerRadius(self.isFocused() ? 0 + self.dragOffset.height * 0.1 : 15)
                            .overlay(
                                ArticleExcerptView(
                                    comments: self.article.comments,
                                    likes: self.article.likes,
                                    userName: "Carl",
                                    isShowContent: self.isFocused()
                                )
                                .cornerRadius(self.isFocused() ? 0 : 15)
                            )

                        if self.isFocused() {
                            Text("This should be the body!")
                                .foregroundColor(Color(.darkGray))
                                .font(.system(.body, design: .rounded))
                                .padding(.horizontal)
                                .padding(.bottom, 50)
                                .transition(.move(edge: .top))
                                .animation(.linear)
                        }
                    }
                }
                .shadow(
                    color: Color(.sRGB, red: 64/255, green: 64/255, blue: 64/255, opacity: 0.3),
                    radius: self.isFocused() ? 0 : 15)
                .gesture(self.isFocused() ?
                            DragGesture()
                            .onChanged({ value in
                                self.dragOffset = value.translation

                                if value.translation.height > 20 || value.translation.width > 20 {
                                    self.activeIndex = nil
                                    self.dragOffset = .zero
                                }
                            })
                            .onEnded({ (_) in
                                self.dragOffset = .zero
                            })
                    : nil)

                if self.isFocused() {
                    HStack {
                        Spacer()

                        Button(action: { self.activeIndex = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                                .opacity(0.7)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.trailing)
                }

            }
        }
        .scaleEffect(1-self.dragOffset.height * 0.0018)
    }
}

struct ArticleExcerptView: View {

    let comments: Int
    let likes: Int
    let userName: String

    let isShowContent: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()

            Rectangle()
                .frame(minHeight: 100, maxHeight: 150)
                .overlay(
                    HStack {
                        VStack(alignment: .leading) {
                            Text(self.userName)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)

                            Text("<3 x \(self.likes)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.1)
                                .lineLimit(2)
                                .padding(.bottom, 5)

                            if !self.isShowContent {
                                // swiftlint:disable line_length
                                Text("'I wish it need not have happened in my time' said Frodo.\n'So do I' said Gandalf.\n'And so do all who lives to see such times. But that is not for them do decide.\nAll we have to decide is what to do with the time that is given us")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.1)
                                    .lineLimit(3)

                            }
                        }
                        .padding()

                        Spacer()
                    }
                )
        }
        .foregroundColor(.white)

    }
}

struct FeedCardView_Previews: PreviewProvider {
    static var previews: some View {
        let article = FeedArticle(articleId: "theID", likes: 6, comments: 7, image: UIImage(named: "preview.jpeg")!)
        Group {
            FeedCardView(article: article, index: 1, activeIndex: .constant(1))

            FeedCardView(article: article, index: 2, activeIndex: .constant(1))

            FeedCardView(article: article, index: 3, activeIndex: .constant(1))
        }
    }
}
