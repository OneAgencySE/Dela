//
//  PhotoPicker.swift
//  Dela (iOS)
//
//  Created by Alexander Herlin on 2021-01-23.
//

import Foundation
import SwiftUI
import UIKit
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    let configuration: PHPickerConfiguration

    @Binding var isPresented: Bool
    @Binding var pickedImages: [ImageRef]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller

    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: PHPickerViewControllerDelegate {

        private let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            DispatchQueue.global().async {
                for result in results {
                    let item = result.itemProvider

                    if item.canLoadObject(ofClass: UIImage.self) {
                        item.loadObject(ofClass: UIImage.self) { (value, err) in
                            guard err == nil, let image = value as? UIImage else {
                                return
                            }

                            let fileName = "\(item.suggestedName ?? UUID().uuidString).jpeg"
                            ImageCacheHandler().prepareImage(image: image,
                                                             fileName: fileName ) { ref in

                                DispatchQueue.main.async {

                                    self.parent.pickedImages.append(ref)

                                }
                            }

                        }
                    }
                }
            }
            parent.isPresented = false
        }
    }

}
