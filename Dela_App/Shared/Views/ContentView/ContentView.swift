//
//  ContentView.swift
//  Shared
//
//  Created by Alexander Herlin on 2020-12-17.
//

import SwiftUI
import Kingfisher
import PhotosUI

struct ContentView: View {
    let configuration: PHPickerConfiguration
    init() {
        var config = PHPickerConfiguration()
        config.filter = PHPickerFilter.images
        config.selectionLimit = 5
        config.preferredAssetRepresentationMode = .compatible
        configuration = config
    }

    @ObservedObject var viewModel = ContentViewModel()
    @State var openImageSelector = false
    @State var pickedImages: [ImageRef] = Array()

    let imageView = Image("preview.jpeg")
    var body: some View {
		VStack {
			Button("Select image") {
				openImageSelector.toggle()
			}

            Button("Upload images!") {
                viewModel.didPressUpload(pickedImages)
            }.disabled(pickedImages.count == 0)

            ForEach(Array(zip(pickedImages, pickedImages.indices)), id: \.1) { ref, _ in
                KFImage(ref.phone.absoluteURL)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 500)
            }

			viewModel.downloadedImage.map { image in
				LazyVStack {
                    KFImage(source: .provider(RawImageDataProvider(data: image.data, cacheKey: image.fileName )))
						.resizable()
						.frame(height: 200)
						.aspectRatio(contentMode: .fit)
					Text(image.fileName )
				}
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
            PhotoPicker(configuration: configuration, isPresented: $openImageSelector, pickedImages: $pickedImages)
		}

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
