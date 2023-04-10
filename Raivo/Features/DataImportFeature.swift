//
// Raivo OTP
//
// Copyright (c) 2022 Tijme Gommers. All rights reserved. 
//
// View the license that applies to the Raivo OTP source 
// code and published services to learn how you can use
// Raivo OTP.
//
// https://raivo-otp.com/license/.

import ZipArchive
import RealmSwift

class DataImportFeature {
    
    private struct PasswordJson: Decodable {
        let pinned: String
        let iconValue: String
        let secret: String
        let issuer: String
        let counter: String
        let account: String
        let iconType: String
        let algorithm: String
        let kind: String
        let digits: String
        let timer: String
    }
    
    private func deleteFile(_ file: URL) {
        try? FileManager.default.removeItem(at: file)
    }
    
    private func deleteFolder(_ folder: URL) {
        try? FileManager.default.removeItem(atPath: folder.absoluteString)
    }
    
    // Attempts to read a file from a zip; returns its data on success, nil otherwise
    private func readFileFromZip(atPath zipPath: String, fileName: String, password: String) -> Data? {
        guard var destinationPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            log.error("Could not get cache directory")
            return nil
        }
        
        destinationPath = destinationPath.appendingPathComponent("raivo-otp-export")
    
        do {
            try SSZipArchive.unzipFile(
                atPath: zipPath,
                toDestination: destinationPath.path,
                overwrite: true,
                password: password
            )
        } catch let error {
            log.error("Could not unzip given ZIP archive with given password")
            log.error(error.localizedDescription)
            return nil
        }
        
        let filePath = destinationPath.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            log.error("Target file does not exist in extracted ZIP archive")
            return nil
        }
        
        var data: Data? = nil
        
        do {
            data = try Data(contentsOf: filePath)
        } catch let error {
            log.error("Could not unzip given ZIP archive with given password")
            log.error(error.localizedDescription)
            return nil
        }
    
        deleteFolder(destinationPath.absoluteURL)
        
        return data
    }
    
    private func importNewPasswords(_ data: Data) -> String? {
        let decoder = JSONDecoder()
        var jsonData: [PasswordJson]? = nil
        
        do {
            jsonData = try decoder.decode([PasswordJson].self, from: data)
        } catch let error {
            log.error("Could not decode given JSON data")
            log.error(error.localizedDescription)
            return "Could not parse JSON data"
        }
            
        if jsonData!.isEmpty {
            return "Given JSON data is empty"
        }
            
        for item in jsonData! {
            let password = Password()
            password.id = password.getNewPrimaryKey()
            password.issuer = item.issuer
            password.account = item.account
            password.iconType = item.iconType
            password.iconValue = item.iconValue
            password.secret = item.secret
            password.algorithm = item.algorithm
            password.digits = Int(item.digits) ?? 0
            password.kind = item.kind
            password.timer = Int(item.timer) ?? 0
            password.counter = Int(item.counter) ?? 0
            password.syncing = true
            password.synced = false
            password.pinned = Bool(item.pinned) ?? false
                        
            autoreleasepool {
                if let realm = RealmHelper.shared.getRealm() {
                    try! realm.write {
                        realm.add(password)
                    }
                }
            }
        }
        
        return nil
    }
    
    public func importArchive(archiveFileURL: URL, withPassword password: String) -> String? {
        // Password validation
        if SSZipArchive.isPasswordValidForArchive(atPath: archiveFileURL.path, password: password, error: nil) == false {
            return "Password incorrect"
        }
        
        // Load file from zip
        guard let data = readFileFromZip(atPath: archiveFileURL.path, fileName: "raivo-otp-export.json", password: password) else {
            return "Not a Raivo OTP export archive"
        }
        
        // Import new passwords
        if let result = importNewPasswords(data) {
            return result
        }
        
        return nil
    }
}
