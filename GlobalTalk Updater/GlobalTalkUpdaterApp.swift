//
//  GlobalTalkUpdaterApp.swift
//  GlobalTalk Updater
//
//  Created by Sam Johnson on 3/19/24.
//

import SwiftUI
import GoogleSignIn
import os.log

@main
struct GlobalTalkUpdaterApp: App {
    let spreadsheetId = "1_fgMgcAveaxkT1AQYSA4CHf6Mz3sB6CjgTpJQPXG4fw"
    let spreadsheetRange = "JustTheFacts!A2:A"
    let invalidChars = [":", ";", ",", "/", " "]
    
    @ObservedObject var fileWriter = GTFileWriter(fileName: "GlobalTalk IP List.txt")
    @ObservedObject var session = GTSession()
    @ObservedObject var poller = Poller(timeInterval: 600)
    
    var body: some Scene {
        WindowGroup {
            ContentView(fileWriter: self.fileWriter, session: self.session, poller: self.poller)
                .frame(width: 300, alignment: .center)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .onAppear {
                self.poller.eventHandler = {
                    getData()
                }
                GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                    guard let user = user else { return }
                    guard error == nil else { return }
                    session.handlePreviousSession(user)
                }
            }
        }
        .windowResizability(.contentSize)
    }
    
    func getData() {
        let sheet = GTSheetReader()
        sheet.queryData(spreadsheetId: self.spreadsheetId, range: self.spreadsheetRange) { rows in
            guard let rows = rows else {
                // Nil rows indicates an error occurred; stop polling
                self.poller.suspend()
                return
            }
            var ipList: [String] = []
            
            for row in rows {
                let ip = row[0]
                if self.invalidChars.contains(where: ip.contains) {
                    // Filter out rows with invalid characters
                    continue
                }
                ipList.append(ip)
            }
            
            if ipList.count < 1 {
                // Something is wrong if we get here; stop to prevent writing an empty file
                self.poller.suspend()
                return
            }
            
            fileWriter.write(ipList: ipList)
        }
    }
}
