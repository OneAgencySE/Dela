//
//  ServiceBase.swift
//  Dela
//
//  Created by Alexander Herlin on 2021-01-20.
//

import Foundation

/// Define basig methods for the clients to handle server connectivity gracefully
/// Don't forget to initialize using the initClientStateHandler() in the init method of you service
protocol StreamingService {
    /// Your GRPC client type
    associatedtype Client

    /// Your GRPC client
    var client: Self.Client? { get }

    /// Whenever the connection to the server is restored this will be called to reset the client
    /// It is up you how that is done,
    func renewClient(_ remoteChannel: RemoteChannel)

    /// Whenever we need to stop streaming, this is where it should happen
    func stopStreaming()

    /// This will be called when you can't talk to the server anymore due to connectivity issues,
    /// renewClient will be called when when connectivity is stable again
    func disconnect()

}

extension StreamingService {
    func initClientStateHandler() {
        renewClient(RemoteChannel.shared)
        _ = RemoteChannel.shared.connectivitySubject
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.global())
            .sink { [self] changeState in
                switch changeState {
                    case .ready, .idle:
                        renewClient(RemoteChannel.shared)

                    case .shutdown:
                        disconnect()

                    case .connecting: break

                    case .transientFailure:
                        stopStreaming()
                }
            }
    }
}
