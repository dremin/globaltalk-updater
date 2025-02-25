//
//  GlobalTalkUpdaterApp.swift
//  GlobalTalk Updater
//
//  Created by Sam Johnson on 3/19/24.
//

import SwiftUI
import GoogleSignIn
import os.log
import AsyncDNSResolver

@main
struct GlobalTalkUpdaterApp: App {
    @ObservedObject var fileWriter_airConfig = GTFileWriter(fileName: "GlobalTalk IP List.txt", separator: ";")
    @ObservedObject var fileWriter_jrouter = GTFileWriter(fileName: "GlobalTalk_jrouter.txt", separator: "\n")
    @ObservedObject var session = GTSession()
    @ObservedObject var poller = Poller(timeInterval: 600)
    @ObservedObject var updater = GTUpdater()
    
    var body: some Scene {
        WindowGroup {
            ContentView(fileWriter_airConfig: self.fileWriter_airConfig, fileWriter_jrouter: self.fileWriter_jrouter, session: self.session, poller: self.poller, updater: self.updater)
                .frame(width: 300, alignment: .center)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .onAppear {
                self.poller.eventHandler = {
                    DispatchQueue.main.async {
                        self.updater.getData()
                    }
                }
                self.updater.add(fileWriter: self.fileWriter_airConfig)
                self.updater.add(fileWriter: self.fileWriter_jrouter)
                GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                    guard let user = user else { return }
                    guard error == nil else { return }
                    session.handlePreviousSession(user)
                }
            }
        }
        .windowResizability(.contentSize)
    }
}
