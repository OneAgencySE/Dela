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
			.connect(host: "http://192.168.1.108", port: 50051)
		
		client = Helloworld_GreeterClient(channel: channel)
		
	}
	
	func hello(_ message: String) -> Result<String, Error> {
		var request = Helloworld_HelloRequest()
		request.name = message
		
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
