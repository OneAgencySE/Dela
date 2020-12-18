//
//  ContentViewModel.swift
//  Dela
//
//  Created by Joacim Nidén on 2020-12-17.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject {
	
	@Published var greeting: String?
	private let client = GreeterClient()
	
	func send() {
		switch client.hello("I said Hi") {
			case .success(let message):
				greeting = message
			case .failure(let failure):
				greeting = failure.localizedDescription
		}
	}
	
	
}
