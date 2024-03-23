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
    @ObservedObject var fileWriter = GTFileWriter(fileName: "GlobalTalk IP List.txt")
    @ObservedObject var session = GTSession()
    @ObservedObject var poller = Poller(timeInterval: 600)
    @ObservedObject var updater = GTUpdater()
    
    var body: some Scene {
        WindowGroup {
            ContentView(fileWriter: self.fileWriter, session: self.session, poller: self.poller, updater: self.updater)
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
                self.updater.set(fileWriter: self.fileWriter)
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
