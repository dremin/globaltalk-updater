//
//  GTUpdater.swift
//  GlobalTalk Updater
//
//  Created by Sam Johnson on 3/22/24.
//

import Foundation
import os.log
import AsyncDNSResolver

@MainActor class GTUpdater: ObservableObject {
    let spreadsheetId = "1_fgMgcAveaxkT1AQYSA4CHf6Mz3sB6CjgTpJQPXG4fw"
    let spreadsheetRange = "JustTheFacts!A2:A"
    let invalidChars = [":", ";", ",", "/", " "]
    
    var fileWriters: [GTFileWriter] = []
    @Published var state: UpdaterState = .idle
    @Published var lastError: String?
    
    enum UpdaterState {
        case idle
        case loading
        case failed
    }
    
    func add(fileWriter: GTFileWriter) {
        self.fileWriters.append(fileWriter)
    }
    
    func getData() {
        let sheet = GTSheetReader()
        let letters = NSCharacterSet.letters
        
        self.state = .loading
        
        sheet.queryData(spreadsheetId: self.spreadsheetId, range: self.spreadsheetRange) { rows in
            guard let rows = rows else {
                // Nil rows indicates an error occurred
                self.lastError = "Unable to access the Google Sheet."
                self.state = .failed
                return
            }
            var resolverOptions = CAresDNSResolver.Options.default
            resolverOptions.timeoutMillis = 1000
            resolverOptions.attempts = 2
            var resolver: AsyncDNSResolver?
            do {
                resolver = try AsyncDNSResolver(options: resolverOptions)
            } catch {
                os_log("Error initializing DNS resolver: \(error)")
            }
            
            Task {
                var ipList: [String] = []
                for row in rows {
                    guard !row.isEmpty else {
                        os_log("Skipping empty row")
                        continue
                    }
                    
                    var ip = row[0]
                    if self.invalidChars.contains(where: ip.contains) {
                        // Filter out rows with invalid characters
                        continue
                    }
                    let range = ip.rangeOfCharacter(from: letters)
                    if let _ = range, let resolver = resolver {
                        // Letters were found; attempt to convert to an IP address
                        do {
                            let aRecords = try await resolver.queryA(name: ip)
                            if aRecords.count > 0 {
                                ip = aRecords[0].address.address
                            } else {
                                // MacTCP DNR is flaky; if we can't resolve this then it's unlikely MacTCP DNR can
                                continue
                            }
                        } catch {
                            os_log("Error thrown while resolving hostname \(ip): \(error)")
                            continue
                        }
                    }
                    
                    ipList.append(ip)
                }
                
                if ipList.count < 1 {
                    // Something is wrong if we get here; stop to prevent writing an empty file
                    self.lastError = "No rows were returned from the Google Sheet query."
                    self.state = .failed
                    return
                }
                
                for fileWriter in self.fileWriters {
                    fileWriter.write(ipList: ipList)
                }
                
                self.state = .idle
                self.lastError = nil
            }
        }
    }
}
