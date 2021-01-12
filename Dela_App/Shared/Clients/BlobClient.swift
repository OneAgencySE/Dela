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
import CombineGRPC

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

    func uploadImge(data: Data) -> AnyPublisher<Blob_BlobInfo, UserInfoError> {
        
		var request = Array(data)
			.chunked(into: 1024)
			.map { chunk in
				Blob_BlobData.with {
					$0.chunkData = Data(chunk)
				}
			}

        request.append(Blob_BlobData.with {
            $0.info = Blob_FileInfo.with {
                $0.extension = ".jpeg"
                $0.metaText = "flowa-powa"
                $0.fileName = ""
            }
        })

        let callOptions = CurrentValueSubject<CallOptions, Never>(CallOptions())
        let requestStream: AnyPublisher<Blob_BlobData, Error> =
            Publishers.Sequence(sequence: request).eraseToAnyPublisher()

        let grpc = GRPCExecutor(
            callOptions: callOptions.eraseToAnyPublisher(),
            retry: .failedCall(
                upTo: 1,
                when: { error in
                    error.status.code == .cancelled
                },
                delayUntilNext: { _, _ in
                    return Just(()).eraseToAnyPublisher()
                },
                didGiveUp: {
                    print("Upload failed")
                }
            ))
		
		/*return Future<Blob_BlobInfo, UserInfoError> { promise in
			return promise(.success(Blob_BlobInfo.with { $0.blobID = "" }))
		}.eraseToAnyPublisher()*/

       return grpc.call(client.upload)(requestStream).mapError { (_) -> UserInfoError in
            .communication(UserInfoError.defaultComMsg)
        }.eraseToAnyPublisher()
    }

    func downloadPublisher(blobId: String) -> AnyPublisher<Blob_BlobData, UserInfoError> {
		let request = Blob_BlobInfo.with {
			$0.blobID = blobId
		}

        let grpc = GRPCExecutor()

        return grpc.call(client.download)(request)
            .mapError { (_) -> UserInfoError in
                .communication(UserInfoError.defaultComMsg)
            }.eraseToAnyPublisher()
	}
}
