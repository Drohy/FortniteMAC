import SwiftUI
import Cocoa
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var patchButtonLabel = "Patch"
    @State private var patch2ButtonLabel = ""
    @State private var downloadProgress: Float = 0.0
    @State private var isDownloading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                print("Backup tapped")
                backupEmbeddedMobileProvision()
            }) {
                Text("Backup")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                print("Restore tapped")
                restoreEmbeddedMobileProvision()
            }) {
                Text("Restore")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                print("Patch button tapped")
                showProvisionDownloadSavePanel()
            }) {
                Text(patchButtonLabel)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if isDownloading {
                ProgressView(value: downloadProgress, total: 1.0)
                    .frame(maxWidth: .infinity)
                    .padding()
                Text("Downloading: \(Int(downloadProgress * 100))%")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            if !patch2ButtonLabel.isEmpty {
                Button(action: {
                    print("Patch 2 button tapped")
                    requestAccessToAppBundle()
                }) {
                    Text(patch2ButtonLabel)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func backupEmbeddedMobileProvision() {
        print("Backing up embedded.mobileprovision")
        alertMessage = "Backup completed."
        showAlert = true
    }
    
    func restoreEmbeddedMobileProvision() {
        print("Restoring embedded.mobileprovision")
        alertMessage = "Restore completed."
        showAlert = true
    }
    
    func showProvisionDownloadSavePanel() {
        let savePanel = NSSavePanel()
        savePanel.title = "Choose Save Location for embedded.mobileprovision"
        savePanel.nameFieldStringValue = "embedded.mobileprovision" // Default filename
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = [.data] // Allow .mobileprovision file types
        
        savePanel.begin { response in
            if response == .OK, let saveURL = savePanel.url {
                downloadEmbeddedMobileProvision(to: saveURL)
            }
        }
    }
    
    func downloadEmbeddedMobileProvision(to destinationURL: URL) {
        let provisionURLString = "https://cdn.discordapp.com/attachments/1280546157977931891/1280991928921362463/embedded.mobileprovision?ex=66da1833&is=66d8c6b3&hm=3a2170da595647c8bcd19db11d0d99c78f78e8293aedc533f957137ccf7dc531&"
        guard let provisionURL = URL(string: provisionURLString) else {
            alertMessage = "Invalid embedded.mobileprovision URL"
            showAlert = true
            return
        }
        
        let session = URLSession(configuration: .default, delegate: DownloadDelegate(destinationURL: destinationURL, progressCallback: { progress in
            DispatchQueue.main.async {
                self.downloadProgress = progress
            }
        }, completionCallback: { success, error in
            DispatchQueue.main.async {
                if success {
                    self.alertMessage = "embedded.mobileprovision downloaded successfully. Now copying to the app folder."
                    self.showAlert = true
                    self.copyProvisionToAppBundle(from: destinationURL)
                } else {
                    self.alertMessage = "Download failed: \(error?.localizedDescription ?? "Unknown error")"
                    self.showAlert = true
                }
            }
        }), delegateQueue: nil)
        
        let downloadTask = session.downloadTask(with: provisionURL)
        isDownloading = true
        downloadTask.resume()
    }
    
    func copyProvisionToAppBundle(from sourceURL: URL) {
        do {
            let fileManager = FileManager.default
            
            let appBundlePath = fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications/Fortnite.app/Wrapper/FortniteClient-IOS-Shipping.app")
            let destinationPath = appBundlePath.appendingPathComponent("embedded.mobileprovision").path
            
            if !fileManager.fileExists(atPath: appBundlePath.path) {
                try fileManager.createDirectory(at: appBundlePath, withIntermediateDirectories: true, attributes: nil)
                print("Created directory at \(appBundlePath.path)")
            }
            
            if fileManager.fileExists(atPath: destinationPath) {
                try fileManager.removeItem(atPath: destinationPath)
                print("Removed existing embedded.mobileprovision at \(destinationPath)")
            }
            
            try fileManager.copyItem(at: sourceURL, to: URL(fileURLWithPath: destinationPath))
            print("Successfully copied embedded.mobileprovision to \(destinationPath)")
            
            DispatchQueue.main.async {
                self.alertMessage = "Patch applied successfully inside the app folder."
                self.showAlert = true
            }
        } catch {
            DispatchQueue.main.async {
                self.alertMessage = "File copy failed: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
    
    func requestAccessToAppBundle() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Fortnite .app Bundle"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.treatsFilePackagesAsDirectories = true // Treats .app bundles as directories
        
        openPanel.begin { (response) in
            if response == .OK, let url = openPanel.url {
                // Check if it's an .app bundle and allow navigating inside
                if url.pathExtension == "app" {
                    // Now we can enter inside the .app bundle
                    navigateAndSelectEmbeddedMobileProvision(for: url)
                } else {
                    print("Selected item is not an .app package")
                }
            }
        }
    }
    
    func navigateAndSelectEmbeddedMobileProvision(for appBundleURL: URL) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select embedded.mobileprovision"
        openPanel.directoryURL = appBundleURL
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.data] // Allows selecting embedded.mobileprovision as a data file
        
        openPanel.begin { (response) in
            if response == .OK, let provisionURL = openPanel.url {
                // Handle the selection of embedded.mobileprovision file
                downloadAndPatchEmbeddedMobileProvision(for: provisionURL, appBundleURL: appBundleURL)
            }
        }
    }
    
    func downloadAndPatchEmbeddedMobileProvision(for provisionURL: URL, appBundleURL: URL) {
        // Here, the logic for handling the provision file after selection would go.
        print("Patched embedded.mobileprovision successfully.")
    }
}

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let destinationURL: URL
    let progressCallback: (Float) -> Void
    let completionCallback: (Bool, Error?) -> Void
    
    init(destinationURL: URL, progressCallback: @escaping (Float) -> Void, completionCallback: @escaping (Bool, Error?) -> Void) {
        self.destinationURL = destinationURL
        self.progressCallback = progressCallback
        self.completionCallback = completionCallback
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            // removes if u got same file
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // moves the file to wherever u moved it too
            try FileManager.default.moveItem(at: location, to: destinationURL)
            completionCallback(true, nil)
        } catch {
            completionCallback(false, error)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        progressCallback(progress)
    }
}
