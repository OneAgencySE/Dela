//
//  ContentView.swift
//  Shared
//
//  Created by Alexander Herlin on 2020-12-17.
//

import SwiftUI

struct ContentView: View {
	@ObservedObject var viewModel = ContentViewModel()
	@State var image: UIImage?
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
			
			viewModel.image.map {
				Image(uiImage: $0)
					.resizable()
					.frame(height: 200)
					.aspectRatio(contentMode: .fit)
			}

			image.map {
				Image(uiImage: $0).resizable()
					.frame(height: 200)
					.aspectRatio(contentMode: .fit)
			}
		}.sheet(isPresented: $openImageSelector) {
			ImagePickerView(sourceType: .photoLibrary) { image in
				self.image = image
				viewModel.sendImage(image?.jpegData(compressionQuality: 0.5))
				openImageSelector.toggle()
			}
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
