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

    public static let `default` = ImageCacheHandler()

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
        ImageCache.default.store(image, forKey: fileName)

        let phoneImage = image.resize(targetSize: CGSize(width: 100.0, height: 200.0))
        let phoneName = "phone_\(fileName)"
        ImageCache.default.store(phoneImage, forKey: phoneName)

        let webImage = image.resize(targetSize: CGSize(width: 200.0, height: 400.0))
        let webName = "web_\(fileName)"
        ImageCache.default.store(webImage, forKey: webName)

        completeion(ImageRef(
                        origninal: URL( string: fileName)!,
                        web: URL( string: webName)!,
                        phone: URL( string: phoneName)!))
    }

    func getImage(name: URL, completion: ((Data) -> Void)?) {
        ImageCache.default.retrieveImage(forKey: name.absoluteString) { res in
            switch res {
                case .success(let image):
                    completion?((image.image?.pngData())!)
                case .failure(let err):
                    print("Failed to retreive image \(err)")
            }
        }
    }
}

extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        let oldSize = self.size
        let widthRatio = targetSize.width / oldSize.width
        let heightRatio = targetSize.height / oldSize.height
        let newSize = widthRatio > heightRatio ?
            CGSize(width: oldSize.width * heightRatio, height: oldSize.height * heightRatio) :
                CGSize(width: oldSize.width * widthRatio, height: oldSize.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!

    }
}
