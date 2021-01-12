//
//  GreeterClient.swift
//  Dela
//
//  Created by Joacim Nidén on 2020-12-17.
//

import Foundation
import GRPC
import NIO

class GreeterClient {
    private let client: Helloworld_GreeterClient
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
            .connect(host: InfoKey.apiUrl.value, port: Int(InfoKey.apiPort.value) ?? 0)

        print("Adress: \(InfoKey.apiUrl.value):\(Int(InfoKey.apiPort.value) ?? 0)")
        print("Connection Status=>:\(channel.connectivity.state)")

        client = Helloworld_GreeterClient(channel: channel)
    }

    func hello(_ message: String) -> Result<String, Error> {
        let request = Helloworld_HelloRequest.with {
            $0.name = message
        }

        do {
            let hello = client.sayHello(request)
            let response = try hello.response.wait()
            print("Greeter received: \(response.message)")
            return Result.success(response.message)

        } catch {
            print("Greeter failed: \(error)")
            return Result.failure(error)
        }
    }
}
