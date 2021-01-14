//
//  DelaApp.swift
//  Shared
//
//  Created by Alexander Herlin on 2020-12-17.
//

import SwiftUI

@main
struct DelaApp: App {
    var body: some Scene {
        WindowGroup {
			TabView {
				FeedView().tabItem {
					Image(systemName: "1.circle.fill")
					Text("Feed")
				}

				ContentView().tabItem {
					Image(systemName: "1.square.fill")
					Text("Content")
				}
			}
        }
    }
}
