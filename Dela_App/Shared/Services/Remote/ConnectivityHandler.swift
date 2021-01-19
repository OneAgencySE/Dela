//
//  ConnectivityHandler.swift
//  Dela
//
//  Created by Alexander Herlin on 2021-01-15.
//

import Foundation
import GRPC

class ConnectivityHandler: ConnectivityStateDelegate {
	var onChange: ((ConnectivityState) -> Void)?
    func connectivityStateDidChange(from oldState: ConnectivityState, to newState: ConnectivityState) {
        print("Connection state changed from \(oldState) to \(newState)")
		onChange?(newState)
    }
}
