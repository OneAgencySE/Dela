//
//  BlobClient.swift
//  Dela
//
//  Created by Alexander Herlin on 2020-12-18.
//

import Foundation
import GRPC
import NIO

class BlobClient {
    private let client: Blob_BlobHandlerClient
    private let channel: ClientConnection
    private let group: MultiThreadedEventLoopGroup

    init() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        channel = ClientConnection.insecure(group: group)
            // Set the debug initializer: it will add a handler to each created channel to write a PCAP when
            // the channel is closed.
            // We're connecting to our own server here; we'll disable connection re-establishment.
            .withConnectionReestablishment(enabled: false)
            // Connect!
            .connect(host: InfoKey.apiUrl.value, port: 50051)

        print("Adress: \(InfoKey.apiUrl.value):50051")
        print("Connection Status=>:\(channel.connectivity.state)")

        let callOption = CallOptions()
        client = Blob_BlobHandlerClient(channel: channel, defaultCallOptions: callOption)
    }

    // https://github.com/grpc/grpc-swift/blob/5c20271bc4a63879f17b3e5acab333f230c5b07d/Examples/Google/SpeechToText/Sources/SpeechService.swift
    func uploadImge(data: Data, completion: ((Blob_UploadImageResponse) -> Void)? = nil) {

		var dataRequest = Array(data)
			.chunked(into: 1024)
			.map { chunk in
				Blob_UploadImageRequest.with {
					$0.chunkData = Data(chunk)
				}
			}

		let stream = client.uploadImage()

		let infoRequest = Blob_UploadImageRequest.with {
			$0.info = Blob_ImageInfo.with {
				$0.extension = ".jpeg"
				$0.metaText = "flowa-powa"
			}
		}

		dataRequest.append(infoRequest)

		stream.sendMessages(dataRequest, promise: nil)
        stream.sendEnd(promise: nil)
    }
}
