//
//  ContentView.swift
//  Shared
//
//  Created by Alexander Herlin on 2020-12-17.
//

import SwiftUI

struct ContentView: View {
	
	@ObservedObject var viewModel = ContentViewModel()
	
    var body: some View {
		
		VStack {
			Button("Tap GRPC") {
				viewModel.send()
			}
			
			Text(viewModel.greeting ?? "")
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
