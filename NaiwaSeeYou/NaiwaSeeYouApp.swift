//
//  NaiwaSeeYouApp.swift
//  NaiwaSeeYou
//
//  Created by Serac on 2026/5/24.
//

import SwiftUI
import AVFoundation

@main
struct NaiwaSeeYouApp: App {
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
