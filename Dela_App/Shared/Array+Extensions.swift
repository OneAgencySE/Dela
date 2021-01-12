//
//  Array+Extensions.swift
//  Dela
//
//  Created by Joacim Nidén on 2021-01-11.
//

import Foundation

extension Array {
	func chunked(into size: Int) -> [[Element]] {
		return stride(from: 0, to: count, by: size).map {
			Array(self[$0 ..< Swift.min($0 + size, count)])
		}
	}
}
