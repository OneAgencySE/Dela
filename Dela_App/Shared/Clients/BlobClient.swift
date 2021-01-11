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

    func uploadImge(data: Data, completion: ((Blob_BlobInfo) -> Void)? = nil) {

		var dataRequest = Array(data)
			.chunked(into: 1024)
			.map { chunk in
				Blob_BlobData.with {
					$0.chunkData = Data(chunk)
				}
			}

		let stream = client.upload()

        let infoRequest = Blob_BlobData.with {
			$0.info = Blob_FileInfo.with {
				$0.extension = ".jpeg"
				$0.metaText = "flowa-powa"
                $0.fileName = ""
			}
		}

		dataRequest.append(infoRequest)

		stream.sendMessages(dataRequest, promise: nil)
        stream.sendEnd(promise: nil)

        do {
            let res = try stream.response.wait()
            completion?(res)
        } catch {
        }
    }
}
