//
//  GTFileWriter.swift
//  GlobalTalk Updater
//
//  Created by Sam Johnson on 3/20/24.
//

import AppKit
import GoogleSignIn
import os.log

class GTFileWriter: ObservableObject {
    let separator = ";"
    
    @Published var destinationDirectory = ""
    @Published var lastWrite: Date?
    var fileName: String
    
    init(fileName: String) {
        self.fileName = fileName
    }
    
    func setDestination(_ directory: String) {
        self.destinationDirectory = directory
    }
    
    func write(ipList: [String]) {
        if self.destinationDirectory.isEmpty {
            os_log("A directory must be set before writing a file!")
            return
        }
        
        let data = Data(ipList.joined(separator: self.separator).utf8)
        let url = URL(fileURLWithPath: destinationDirectory).appending(path: fileName)
        
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            let contents = try String(contentsOf: url)
            self.lastWrite = .now
            os_log("Successfully wrote file contents: \(contents)")
        } catch {
            os_log("Error writing file: \(error.localizedDescription)")
        }
    }
}
