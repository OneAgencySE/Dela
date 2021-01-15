//
//  BlobClient.swift
//  Dela
//
//  Created by Alexander Herlin on 2020-12-18.
//

import Foundation
import GRPC
import Combine

class BlobClient {

    private let client: Blob_BlobHandlerClient

	static var shared = BlobClient()

    init() {
        let remote = RemoteChannel.shared
        client = Blob_BlobHandlerClient(channel: remote.clientConnection, defaultCallOptions: remote.defaultCallOptions)
    }

    func uploadImge(data: Data) -> AnyPublisher<BlobInfo, UserInfoError> {
        Future<BlobInfo, UserInfoError> { promise in
            let upload = self.client.upload()

            let chunks = Array(data)
                .chunked(into: 1024)
                .map { chunk in
                    Blob_BlobData.with {
                        $0.chunkData = Data(chunk)
                    }
                }
            upload.sendMessages(chunks, promise: nil)

            let imageInfo = Blob_BlobData.with {
                $0.info = Blob_FileInfo.with {
                    $0.extension = ".jpeg"
                    $0.metaText = "flowa-powa"
                    $0.fileName = ""
                }
            }
            upload.sendMessage(imageInfo, promise: nil)

            do {
                upload.sendEnd(promise: nil)
                let response = try upload.response.wait()
                promise(.success(BlobInfo(blobId: response.blobID)))
            } catch {
                promise(.failure(.communication(error.localizedDescription)))
            }

        }.eraseToAnyPublisher()
    }

    func downBlobPub(blobId: String) -> AnyPublisher<DownloadedBlob, UserInfoError> {
        Future<DownloadedBlob, UserInfoError> { promise in
            let request = Blob_BlobInfo.with {
                $0.blobID = blobId
            }

            var data = Data()
            _ = self.client.download(request) { blob in
                data.append(blob.chunkData)

                if !blob.info.fileName.isEmpty {
                    return promise(
                        .success(DownloadedBlob(data: data,
                                                fileName: blob.info.fileName,
                                                fileExt: blob.info.extension)))
                }
            }
        }.eraseToAnyPublisher()
    }
}
