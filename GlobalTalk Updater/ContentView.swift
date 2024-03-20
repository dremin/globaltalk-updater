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
    @ObservedObject var fileWriter: GTFileWriter
    @ObservedObject var session: GTSession
    @ObservedObject var poller: Poller
    
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
                GroupBox("File Destination") {
                    VStack(alignment: .leading) {
                        if fileWriter.destinationDirectory.isEmpty {
                            Text("Select a destination to begin.")
                        } else {
                            Text("Selected destination:")
                                .bold()
                            Text(fileWriter.destinationDirectory.replacingOccurrences(of: "file://", with: ""))
                        }
                        Button("Select Destination") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false
                            if panel.runModal() == .OK {
                                fileWriter.setDestination(panel.url?.absoluteString ?? "")
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
                        .disabled(fileWriter.destinationDirectory.isEmpty)
                    } else {
                        Button("Stop Auto Update", systemImage: "stop.fill") {
                            poller.suspend()
                        }
                    }
                    if let lastWrite = fileWriter.lastWrite {
                        Text("Latest update: \(formatDate(lastWrite))")
                            .font(.footnote)
                    }
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
    ContentView(fileWriter: GTFileWriter(fileName: ""), session: GTSession(isSignedIn: true), poller: Poller(timeInterval: 99999999999))
}

#Preview {
    ContentView(fileWriter: GTFileWriter(fileName: ""), session: GTSession(isSignedIn: false), poller: Poller(timeInterval: 99999999999))
}
