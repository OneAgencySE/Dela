//
//  BlobClient.swift
//  Dela
//
//  Created by Alexander Herlin on 2020-12-18.
//

import Foundation
import GRPC
import Combine

final class BlobService: StreamingService {
    var client: Blob_BlobHandlerClient?

    private var cancellableDownload: ServerStreamingCall<Blob_BlobInfo, Blob_BlobData>?
    private var cancellableUpload: ClientStreamingCall<Blob_BlobData, Blob_BlobInfo>?

    init() {
        self.initClientStateHandler()
    }

    func renewClient(_ remoteChannel: RemoteChannel) {
        client = Blob_BlobHandlerClient(
            channel: remoteChannel.clientConnection,
            defaultCallOptions: remoteChannel.defaultCallOptions)
    }

    func stopStreaming() {
        self.cancellableDownload?.cancel(promise: nil)
        self.cancellableUpload?.cancel(promise: nil)
    }

    func disconnect() {
        self.cancellableDownload?.cancel(promise: nil)
        self.cancellableUpload?.cancel(promise: nil)
    }

    func uploadImge(data: Data) -> AnyPublisher<BlobInfo, UserInfoError> {
        Future<BlobInfo, UserInfoError> { [self] promise in

            guard client != nil else {
                return
            }

            cancellableUpload = client!.upload()

            let chunks = Array(data)
                .chunked(into: 1024)
                .map { chunk in
                    Blob_BlobData.with {
                        $0.chunkData = Data(chunk)
                    }
                }
            cancellableUpload?.sendMessages(chunks, promise: nil)

            let imageInfo = Blob_BlobData.with {
                $0.info = Blob_FileInfo.with {
                    $0.extension = ".jpeg"
                    $0.metaText = "flowa-powa"
                    $0.fileName = ""
                }
            }
            cancellableUpload?.sendMessage(imageInfo, promise: nil)

            do {
                cancellableUpload?.sendEnd(promise: nil)

                if let response = try cancellableUpload?.response.wait() {
                    promise(.success(BlobInfo(blobId: response.blobID)))
                } else {
                    promise(.failure(UserInfoError.communication(UserInfoError.defaultComMsg)))
                }
            } catch {
                promise(.failure(.communication(error.localizedDescription)))
            }

        }.eraseToAnyPublisher()
    }

    func downBlobPub(blobId: String) -> AnyPublisher<DownloadedBlob, UserInfoError> {
        Future<DownloadedBlob, UserInfoError> { [self] promise in

            guard client != nil else {
                return
            }

            let request = Blob_BlobInfo.with {
                $0.blobID = blobId
            }

            var data = Data()
            cancellableDownload = client!.download(request) { blob in
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
