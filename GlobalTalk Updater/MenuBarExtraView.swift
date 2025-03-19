//
//  MenuBarExtra.swift
//  GlobalTalk Updater
//
//  Created by Sam Johnson on 3/17/25.
//

import SwiftUI
import GoogleSignInSwift
import GoogleSignIn
import os.log

struct MenuBarExtraView: View {
    @ObservedObject var fileWriter_airConfig: GTFileWriter
    @ObservedObject var fileWriter_jrouter: GTFileWriter
    @ObservedObject var session: GTSession
    @ObservedObject var poller: Poller
    @ObservedObject var updater: GTUpdater
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        if updater.state == .failed {
            Text("An error occurred during the last update attempt.")
            Text(updater.lastError ?? "Unknown error")
            Divider()
        }
        
        if updater.state == .loading {
            Text("Fetching the latest data...")
            Divider()
        } else if let lastWrite = fileWriter_airConfig.lastWrite {
            Text("Latest update: \(updater.formatDate(lastWrite))")
            Divider()
        } else if let lastWrite = fileWriter_jrouter.lastWrite {
            Text("Latest update: \(updater.formatDate(lastWrite))")
            Divider()
        }
        
        if session.isSignedIn {
            if (poller.state == .suspended) {
                Button("Start Auto Update") {
                    poller.resume()
                }
                .disabled(!(!fileWriter_airConfig.destinationDirectory.isEmpty || !fileWriter_jrouter.destinationDirectory.isEmpty))
            } else {
                Button("Stop Auto Update") {
                    poller.suspend()
                }
            }
            Divider()
        }
        
        Button("Settings...") {
            openWindow(id: "settings-window")
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        Button("Quit GlobalTalk Updater") {
            NSApp.terminate(nil)
        }
    }
}

#Preview {
    MenuBarExtraView(fileWriter_airConfig: GTFileWriter(fileName: "", separator: ";"), fileWriter_jrouter: GTFileWriter(fileName: "", separator: "\n"), session: GTSession(isSignedIn: true), poller: Poller(timeInterval: 99999999999), updater: GTUpdater())
}

#Preview {
    MenuBarExtraView(fileWriter_airConfig: GTFileWriter(fileName: "", separator: ";"), fileWriter_jrouter: GTFileWriter(fileName: "", separator: "\n"), session: GTSession(isSignedIn: false), poller: Poller(timeInterval: 99999999999), updater: GTUpdater())
}
