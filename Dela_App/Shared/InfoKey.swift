//
//  InfoKey.swift
//  Dela
//
//  Created by Joacim Nidén on 2020-12-18.
//

import Foundation

enum InfoKey: String {
	case apiUrl = "API_URL"
    case apiPort = "API_PORT"

	var value: String {
        return key(self.rawValue)
	}

	private func key(_ string: String) -> String {
		return (Bundle.main.infoDictionary?[string] as? String) ?? ""
	}

}
