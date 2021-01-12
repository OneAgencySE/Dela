//
//  ContentView.swift
//  Shared
//
//  Created by Alexander Herlin on 2020-12-17.
//

import SwiftUI
import Kingfisher

struct ContentView: View {
	
	@ObservedObject var viewModel = ContentViewModel()
	@State var openImageSelector = false

    var body: some View {
		VStack {
            Button("Test Connection") {
                viewModel.send()
            }
            if let greeting = viewModel.greeting {
                Text("\(greeting)")
            }
			Button("Select image") {
				openImageSelector.toggle()
			}

            Button("Download") {
                viewModel.didPressDownload()
            }

			viewModel.downloadedImage.map {
				Image(uiImage: $0)
					.resizable()
					.frame(height: 200)
					.aspectRatio(contentMode: .fit)
			}
			
			viewModel.uploadedImage.map { image in
				
				LazyVStack {
					KFImage(source: .provider(RawImageDataProvider(data: image.0, cacheKey: image.1 )))
						.resizable()
						.frame(height: 200)
						.aspectRatio(contentMode: .fit)
					Text(image.1 )
				}
			}
			
			

		}.sheet(isPresented: $openImageSelector) {
			ImagePickerView(sourceType: .photoLibrary) { image in
				viewModel.didPressUpload(data: image.jpegData(compressionQuality: 0.5))
			}
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
