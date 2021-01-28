//
//  ImageCacheService.swift
//  Dela
//
//  Created by Alexander Herlin on 2021-01-26.
//

import Foundation
import Kingfisher
import SwiftUI

struct ImageRef {
    let origninal: URL
    let web: URL
    let phone: URL
}

struct ImageCacheHandler {

    let processor = DownsamplingImageProcessor(
        size: .init(width: CGFloat(3840), height: CGFloat(2160)))

    /// Cache the image for later use
    func cacheImage(image: Data, fileName: String, completeion: @escaping (URL) -> Void) {
        ImageCache.default.store(UIImage(data: image)!,
                                 original: image,
                                 forKey: fileName,
                                 options: KingfisherParsedOptionsInfo(nil))
        completeion(URL(string: fileName)!)
    }

    /// Store the originl and create one phone version and one Ipad/full screen version
    func prepareImage(image: KFCrossPlatformImage, fileName: String, completeion: @escaping (ImageRef) -> Void) {
        
            /// Make 3 versions of the image!
            /// cache them, and return
            let info = KingfisherParsedOptionsInfo(nil)

            // info.cacheSerializer = DefaultCacheSerializer.default

            ImageCache.default.store(image,
                                     forKey: fileName,
                                     options: info)

        completeion(ImageRef(origninal: URL( string: "sss")!, web: URL( string: "sss")!, phone: URL( string: "sss")!))
    }
}
