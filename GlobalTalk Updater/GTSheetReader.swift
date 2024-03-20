//
//  GTSheetReader.swift
//  GlobalTalk Updater
//
//  Created by Sam Johnson on 3/19/24.
//

import Foundation
import GTMSessionFetcherCore
import GoogleAPIClientForREST_Sheets
import GoogleSignIn
import os.log

class GTSheetReader {
    let sheetService = GTLRSheetsService()
    
    func authorize(completionHandler: @escaping (Bool) -> Void) {
        let user = GIDSignIn.sharedInstance.currentUser
        
        guard let user = user else {
            completionHandler(false)
            return
        }
        
        user.refreshTokensIfNeeded { refreshedUser, error in
            if let error = error {
                os_log("Unable to refresh user token: \(error.localizedDescription)")
                completionHandler(false)
                return
            }
            guard let refreshedUser = refreshedUser else {
                os_log("Unable to refresh user token: No user")
                completionHandler(false)
                return
            }
            
            self.sheetService.authorizer = refreshedUser.fetcherAuthorizer
            completionHandler(true)
        }
    }
    
    func queryData(spreadsheetId: String, range: String, completionHandler: @escaping ([[String]]?) -> Void) {
        authorize { success in
            if !success {
                completionHandler(nil)
            }
            
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: spreadsheetId, range: range)
            
            self.sheetService.executeQuery(query) { ticket, result, error in
                if let error = error {
                    os_log("Sheet query error: \(error.localizedDescription)")
                    completionHandler(nil)
                    return
                }
                guard let result = result as? GTLRSheets_ValueRange else {
                    os_log("Sheet query error: No result")
                    return
                }
                
                let rows = result.values!
                let stringRows = rows as! [[String]]
                
                if rows.isEmpty {
                    os_log("Sheet query error: No rows")
                    // Treat no data as a failure
                    completionHandler(nil)
                    return
                }
                
                completionHandler(stringRows)
            }
        }
    }
}
