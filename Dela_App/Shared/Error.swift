//
//  Error.swift
//  Dela
//
//  Created by Alexander Herlin on 2021-01-12.
//

import Foundation

enum UserInfoError: Error {
    case communication(String)
    case other(String)
}

extension UserInfoError {
    static var defaultComMsg: String { return "Something went wrong at the headquarters😱, we're working on it 🥸" }
}
