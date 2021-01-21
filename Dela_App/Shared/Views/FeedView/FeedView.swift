//
//  FeedView.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import SwiftUI
import Kingfisher

struct FeedView: View {
	@State var viewModel = FeedViewModel()
    @State var activeIndex: Int?

    enum ContentMode: Equatable {
        case list
        case content(Int)
    }

    private func isFocused(_ index: Int) -> Bool {
        self.activeIndex != nil && self.activeIndex == index
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    TopBarView()
                        .padding(.horizontal, 20)
                        .opacity(self.activeIndex == nil ? 1 : 0)

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

                    LazyVStack {

                        ForEach(viewModel.articles.indices) { index in
                            GeometryReader { innerGeo in
                                FeedCardView(article: viewModel.articles[index],
                                             index: index,
                                             activeIndex: self.$activeIndex)
                                    .offset(y: self.isFocused(index) ? -innerGeo.frame(in: .global).minY : 0)
                                    .padding(.horizontal, self.isFocused(index) ? 0 : 20)
                                    .opacity(self.isFocused(index) ? 0 : 1)
                                    .onTapGesture {
                                        self.activeIndex = index
                                    }
                            }
                            .frame(height: self.isFocused(index) ?
                                        geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
                                : min(self.viewModel.articles[index].image.size.height/3, 500))
                            .animation(.interactiveSpring(response: 0.55, dampingFraction: 0.65, blendDuration: 0.1))
                        }
                    }
                }
                .frame(width: geometry.size.width)
            }
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        let view = FeedView()
        let image = UIImage(named: "preview.jpeg")!
        view.viewModel.articles.append(FeedArticle(articleId: "TheId", likes: 3, comments: 1, image: image))
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
