import SwiftUI
import Cocoa
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var patchButtonLabel = "Patch Fortnite IPA"
    @State private var patch2ButtonLabel = "Patch embedded.mobileprovision"
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
                showIPADownloadSavePanel()
            }) {
                Text(patchButtonLabel)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                print("Patch 2 button tapped")
                showAppBundleSelectionPanel()
            }) {
                Text(patch2ButtonLabel)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
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
    
    func showIPADownloadSavePanel() {
        let savePanel = NSSavePanel()
        savePanel.title = "Choose Save Location for Fortnite IPA"
        savePanel.nameFieldStringValue = "FortniteV31.10.ipa" // Default filename
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = [.data] // Allow .ipa file types
        
        savePanel.begin { response in
            if response == .OK, let saveURL = savePanel.url {
                downloadFortniteIPA(to: saveURL)
            }
        }
    }
    
    func downloadFortniteIPA(to destinationURL: URL) {
        let ipaURLString = "https://download1530.mediafire.com/dpcqzfytq11g5DWbw-LH9fvu4pwwrTI_rUe1HSxawRP4CQQfijMJ0AgKg4Xxb8df4LmXkhJ-d8hzYXBXnxYbRg_1x9i7F7XbMAdu3ve3eL3To8CwjI6Gd7Wqst021ooNjtz_301GDSoIH-EKwtQ5-L1pX98v_QexXz1SByLpWaw/tpay1hzcgneqxx6/Fortnite31101FullScreen.ipa"
        guard let ipaURL = URL(string: ipaURLString) else {
            alertMessage = "Invalid Fortnite IPA URL"
            showAlert = true
            return
        }
        
        let session = URLSession(configuration: .default, delegate: DownloadDelegate(destinationURL: destinationURL, progressCallback: { progress in
            DispatchQueue.main.async {
                self.downloadProgress = progress
            }
        }, completionCallback: { success in
            DispatchQueue.main.async {
                if success {
                    self.alertMessage = "Fortnite IPA downloaded successfully. Sideload this IPA with Sideloadly, then press Patch 2."
                    self.isDownloading = false
                    self.showAlert = true
                } else {
                    self.alertMessage = "Download failed."
                    self.isDownloading = false
                    self.showAlert = true
                }
            }
        }), delegateQueue: nil)
        
        let downloadTask = session.downloadTask(with: ipaURL)
        isDownloading = true
        downloadTask.resume()
    }
    
    func showAppBundleSelectionPanel() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select the Fortnite .app Bundle"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.treatsFilePackagesAsDirectories = true
        
        openPanel.begin { response in
            if response == .OK, let selectedAppBundle = openPanel.url {
                let destinationPath = selectedAppBundle.appendingPathComponent("embedded.mobileprovision")
                downloadAndSaveEmbeddedMobileProvision(to: destinationPath)
            }
        }
    }
    
    func downloadAndSaveEmbeddedMobileProvision(to destinationURL: URL) {
        let provisionURLString = "https://github.com/Drohy/FortniteMAC/raw/04890b0778751d20afd5330d4346972e99b9c1f5/FILES/embedded.mobileprovision"
        guard let downloadURL = URL(string: provisionURLString) else {
            alertMessage = "Invalid embedded.mobileprovision URL"
            showAlert = true
            return
        }
        
        let session = URLSession(configuration: .default, delegate: DownloadDelegate(destinationURL: destinationURL, progressCallback: { progress in
            DispatchQueue.main.async {
                self.downloadProgress = progress
            }
        }, completionCallback: { success in
            DispatchQueue.main.async {
                if success {
                    self.alertMessage = "embedded.mobileprovision downloaded successfully to \(destinationURL.path)."
                    self.showAlert = true
                } else {
                    self.alertMessage = "Download failed."
                    self.showAlert = true
                }
            }
        }), delegateQueue: nil)
        
        let downloadTask = session.downloadTask(with: downloadURL)
        isDownloading = true
        downloadTask.resume()
    }
}

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let destinationURL: URL
    let progressCallback: (Float) -> Void
    let completionCallback: (Bool) -> Void
    
    init(destinationURL: URL, progressCallback: @escaping (Float) -> Void, completionCallback: @escaping (Bool) -> Void) {
        self.destinationURL = destinationURL
        self.progressCallback = progressCallback
        self.completionCallback = completionCallback
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(atPath: destinationURL.path)
            }
            
            try FileManager.default.moveItem(at: location, to: destinationURL)
            completionCallback(true)
        } catch {
            completionCallback(false)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        progressCallback(progress)
    }
}
