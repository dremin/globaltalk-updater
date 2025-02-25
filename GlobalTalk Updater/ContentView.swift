//
//  ContentView.swift
//  GlobalTalk Updater
//
//  Created by Sam Johnson on 3/19/24.
//

import SwiftUI
import GoogleSignInSwift
import GoogleSignIn
import os.log

struct ContentView: View {
    @ObservedObject var fileWriter_airConfig: GTFileWriter
    @ObservedObject var fileWriter_jrouter: GTFileWriter
    @ObservedObject var session: GTSession
    @ObservedObject var poller: Poller
    @ObservedObject var updater: GTUpdater
    
    var body: some View {
        VStack(spacing: 15) {
            GroupBox("Google Account") {
                VStack(alignment: .leading) {
                    if session.isSignedIn {
                        Text("Logged in as: \(session.user?.profile?.name ?? "Unknown")")
                            .bold()
                        Button("Sign Out") {
                            poller.suspend()
                            session.signOut()
                        }
                    } else {
                        VStack(spacing: 20) {
                            Text("Sign in with your Google Account to begin.")
                                .multilineTextAlignment(.center)
                            GoogleSignInButton {
                                session.signIn()
                            }
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            if session.isSignedIn {
                GroupBox("AIRConfig File Destination") {
                    VStack(alignment: .leading) {
                        if fileWriter_airConfig.destinationDirectory.isEmpty {
                            Text("Select a destination to begin.")
                        } else {
                            Text("Selected destination:")
                                .bold()
                            Text(fileWriter_airConfig.destinationDirectory.replacingOccurrences(of: "file://", with: ""))
                        }
                        Button("Select Destination") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false
                            if panel.runModal() == .OK {
                                fileWriter_airConfig.setDestination(panel.url?.absoluteString ?? "")
                            }
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                GroupBox("jrouter File Destination") {
                    VStack(alignment: .leading) {
                        if fileWriter_jrouter.destinationDirectory.isEmpty {
                            Text("Select a destination to begin.")
                        } else {
                            Text("Selected destination:")
                                .bold()
                            Text(fileWriter_jrouter.destinationDirectory.replacingOccurrences(of: "file://", with: ""))
                        }
                        Button("Select Destination") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false
                            if panel.runModal() == .OK {
                                fileWriter_jrouter.setDestination(panel.url?.absoluteString ?? "")
                            }
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                
                VStack {
                    if (poller.state == .suspended) {
                        Button("Start Auto Update", systemImage: "play.fill") {
                            poller.resume()
                        }
                        .disabled(!(!fileWriter_airConfig.destinationDirectory.isEmpty || !fileWriter_jrouter.destinationDirectory.isEmpty))
                    } else {
                        Button("Stop Auto Update", systemImage: "stop.fill") {
                            poller.suspend()
                        }
                    }
                    VStack(spacing: 10) {
                        if updater.state == .loading {
                            HStack(spacing: 4) {
                                ProgressView().controlSize(.small)
                                Text("Fetching the latest data...")
                            }
                        } else if let lastWrite = fileWriter_airConfig.lastWrite {
                            Text("Latest update: \(formatDate(lastWrite))")
                        } else if let lastWrite = fileWriter_jrouter.lastWrite {
                            Text("Latest update: \(formatDate(lastWrite))")
                        }
                        
                        if updater.state == .failed {
                            Label("An error occurred during the last update attempt.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .help(updater.lastError ?? "Unknown error")
                        }
                    }
                    .font(.footnote)
                }
                .controlSize(.large)
                .buttonStyle(BorderedProminentButtonStyle())
            }
        }
        .padding()
    }
    
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .long
        
        return dateFormatter.string(from: date)
    }
}

#Preview {
    ContentView(fileWriter_airConfig: GTFileWriter(fileName: "", separator: ";"), fileWriter_jrouter: GTFileWriter(fileName: "", separator: "\n"), session: GTSession(isSignedIn: true), poller: Poller(timeInterval: 99999999999), updater: GTUpdater())
}

#Preview {
    ContentView(fileWriter_airConfig: GTFileWriter(fileName: "", separator: ";"), fileWriter_jrouter: GTFileWriter(fileName: "", separator: "\n"), session: GTSession(isSignedIn: false), poller: Poller(timeInterval: 99999999999), updater: GTUpdater())
}
