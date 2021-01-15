//
//  ChannelBuilder.swift
//  Dela
//
//  Created by Alexander Herlin on 2021-01-15.
//

import Foundation
import GRPC
import Logging
import NIOHPACK
import NIO

struct RemoteChannel {

    let clientConnection: ClientConnection
    let clientConfiguration: ClientConnection.Configuration
    let defaultCallOptions: CallOptions

    static var shared = RemoteChannel()

    init() {
        clientConfiguration = ClientConnection.Configuration(
            target: .hostAndPort(InfoKey.apiUrl.value, Int(InfoKey.apiPort.value) ?? 0),
            eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: 1),
            connectivityStateDelegate: ConnectivityHandler())
        clientConnection = ClientConnection(configuration: clientConfiguration)
        print("Adress: \(InfoKey.apiUrl.value):\(Int(InfoKey.apiPort.value) ?? 0)")
        print("Connection Status=>:\(clientConnection.connectivity.state)")

        defaultCallOptions = CallOptions(
            customMetadata: HPACKHeaders([("x-user", "Carl")]),
            timeLimit: .none,
            messageEncoding: .disabled,
            requestIDProvider: CallOptions.RequestIDProvider.autogenerated,
            requestIDHeader: UUID().uuidString,
            cacheable: false,
            logger: Logger(label: "io.grpc", factory: { _ in SwiftLogNoOpLogHandler() }))

    }
}
