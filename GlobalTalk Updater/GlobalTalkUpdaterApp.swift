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
    
    init() {
        initApp()
    }
    
    func initApp() {
        self.poller.eventHandler = {
            DispatchQueue.main.async {
                self.updater.getData()
            }
        }
        self.updater.add(fileWriter: self.fileWriter_airConfig)
        self.updater.add(fileWriter: self.fileWriter_jrouter)
    }
    
    var body: some Scene {
        Window("GlobalTalk Updater", id: "settings-window") {
            ContentView(fileWriter_airConfig: self.fileWriter_airConfig, fileWriter_jrouter: self.fileWriter_jrouter, session: self.session, poller: self.poller, updater: self.updater)
                .frame(width: 300, alignment: .center)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .windowResizability(.contentSize)
        
        MenuBarExtra("GlobalTalk Updater", systemImage: "externaldrive.connected.to.line.below") {
            MenuBarExtraView(fileWriter_airConfig: self.fileWriter_airConfig, fileWriter_jrouter: self.fileWriter_jrouter, session: self.session, poller: self.poller, updater: self.updater)
        }
    }
}
