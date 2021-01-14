//
//  FeedView.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-14.
//

import SwiftUI

struct FeedView: View {

	@ObservedObject var viewModel = FeedViewModel()

    var body: some View {
		VStack {
			Button("Get some articles") {
				viewModel.getFeed()
			}
			Button("Stop streaming") {
				viewModel.stopStreaming()
			}
		}
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
