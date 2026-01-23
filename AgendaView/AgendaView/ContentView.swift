//
//  ContentView.swift
//  AgendaView
//
//  Created by Cody Arnold on 1/19/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = GoogleAuthService()
    @StateObject private var dataManager: CalendarDataManager

    init() {
        let auth = GoogleAuthService()
        _authService = StateObject(wrappedValue: auth)
        _dataManager = StateObject(wrappedValue: CalendarDataManager(authService: auth))
    }

    var body: some View {
        Group {
            if authService.isAuthenticated {
                AgendaListView(authService: authService, dataManager: dataManager)
            } else {
                SignInView(authService: authService)
            }
        }
    }
}

#Preview {
    ContentView()
}
