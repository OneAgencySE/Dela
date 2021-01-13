//
//  BlobClient.swift
//  Dela
//
//  Created by Alexander Herlin on 2020-12-18.
//

import Foundation
import GRPC
import NIO
import Combine

class BlobClient {

    private let client: Blob_BlobHandlerClient
    private let channel: ClientConnection
    private let group: MultiThreadedEventLoopGroup

	static var shared = BlobClient()

    init() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        channel = ClientConnection.insecure(group: group)
            .withConnectionReestablishment(enabled: false)
            .connect(host: InfoKey.apiUrl.value, port: Int(InfoKey.apiPort.value) ?? 0)
        client = Blob_BlobHandlerClient(channel: channel)

        print("Adress: \(InfoKey.apiUrl.value):\(Int(InfoKey.apiPort.value) ?? 0)")
        print("Connection Status=>:\(channel.connectivity.state)")
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
