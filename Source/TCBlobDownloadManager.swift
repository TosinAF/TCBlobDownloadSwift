//
//  TCBlobDownloadManager.swift
//  TCBlobDownloadSwift
//
//  Created by Thibault Charbonnier on 30/12/14.
//  Copyright (c) 2014 thibaultcha. All rights reserved.
//

import Foundation

public let kTCBlobDownloadSessionIdentifier = "tcblobdownloadmanager_downloads"

public let kTCBlobDownloadErrorDomain = "com.tcblobdownloadswift.error"
public let kTCBlobDownloadErrorDescriptionKey = "TCBlobDownloadErrorDescriptionKey"
public let kTCBlobDownloadErrorHTTPStatusKey = "TCBlobDownloadErrorHTTPStatusKey"
public let kTCBlobDownloadErrorFailingURLKey = "TCBlobDownloadFailingURLKey"


public enum TCBlobDownloadError: Int {
    case TCBlobDownloadHTTPError = 1
}

public class TCBlobDownloadManager {
    /**
        A shared instance of `TCBlobDownloadManager`.
    */
    public static let sharedInstance = TCBlobDownloadManager()

    /// Instance of the underlying class implementing `NSURLSessionDownloadDelegate`.
    public var delegate: DownloadDelegate

    /// If `true`, downloads will start immediatly after being created. `true` by default.
    public var startImmediatly = true

    /// The underlying `NSURLSession`.
    public var session: NSURLSession

    /**
        Custom `NSURLSessionConfiguration` init.

        - parameter config: The configuration used to manage the underlying session.
    */
    public init(config: NSURLSessionConfiguration) {
        self.delegate = DownloadDelegate()
        self.session = NSURLSession(configuration: config, delegate: self.delegate, delegateQueue: nil)
        self.session.sessionDescription = "TCBlobDownloadManger session"

        // Reconnect any background downloads that may still be in progress as a result of the app quitting unexpectedly
        self.delegate.restoreDownloadsForSession(self.session)
    }

    /**
        Default `NSURLSessionConfiguration` init.
    */
    public convenience init() {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        //config.HTTPMaximumConnectionsPerHost = 1
        self.init(config: config)
    }

    /**
        Base method to start a download, called by other download methods.
    
        - parameter download: Download to start.
    */
    private func downloadWithDownload(download: TCBlobDownload) -> TCBlobDownload {
        self.delegate.downloads[download.downloadTask.taskIdentifier] = download
        download.save()

        if self.startImmediatly {
            download.downloadTask.resume()
        }

        return download
    }

    /**
        Start downloading the file at the given URL.
    
        - parameter url: NSURL of the file to download.
        - parameter directory: Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
        - parameter name: Name to give to the file once the download is completed.
        - parameter delegate: An eventual delegate for this download.

        :return: A `TCBlobDownload` instance.
    */
    public func downloadFileAtURL(url: NSURL, toDirectory directory: NSURL?, withName name: String?, andDelegate delegate: TCBlobDownloadDelegate?) -> TCBlobDownload {
        let downloadTask = self.session.downloadTaskWithURL(url)
        let download = TCBlobDownload(downloadTask: downloadTask, toDirectory: directory, fileName: name, delegate: delegate, sessionConfigurationIdentifier: self.session.configuration.identifier!)

        return self.downloadWithDownload(download)
    }

    /**
     Start downloading the file using the given NSURLRequest.

     - parameter request: NSURLRequest to use for the file download.
     - parameter directory: Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
     - parameter name: Name to give to the file once the download is completed.
     - parameter delegate: An eventual delegate for this download.

     :return: A `TCBlobDownload` instance.
     */
    public func downloadFileWithRequest(request: NSURLRequest, toDirectory directory: NSURL?, withName name: String?, andDelegate delegate: TCBlobDownloadDelegate?) -> TCBlobDownload {
        let downloadTask = self.session.downloadTaskWithRequest(request)
        let download = TCBlobDownload(downloadTask: downloadTask, toDirectory: directory, fileName: name, delegate: delegate, sessionConfigurationIdentifier: self.session.configuration.identifier!)

        return self.downloadWithDownload(download)
    }

    /**
        Start downloading the file at the given URL.

        - parameter url: NSURL of the file to download.
        - parameter directory: Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
        - parameter name: Name to give to the file once the download is completed.
        - parameter progression: A closure executed periodically when a chunk of data is received.
        - parameter completion: A closure executed when the download has been completed.

        :return: A `TCBlobDownload` instance.
    */
    public func downloadFileAtURL(url: NSURL, toDirectory directory: NSURL?, withName name: String?, progression: progressionHandler?, completion: completionHandler?) -> TCBlobDownload {
        let downloadTask = self.session.downloadTaskWithURL(url)
        let download = TCBlobDownload(downloadTask: downloadTask, toDirectory: directory, fileName: name, sessionConfigurationIdentifier: self.session.configuration.identifier!, progression: progression, completion: completion)

        return self.downloadWithDownload(download)
    }

    /**
     Start downloading the file using the given NSURLRequest.

     - parameter request: NSURLRequest to use for the file download.
     - parameter directory: Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
     - parameter name: Name to give to the file once the download is completed.
     - parameter progression: A closure executed periodically when a chunk of data is received.
     - parameter completion: A closure executed when the download has been completed.

     :return: A `TCBlobDownload` instance.
     */
    public func downloadFileWithRequest(request: NSURLRequest, toDirectory directory: NSURL?, withName name: String?, progression: progressionHandler?, completion: completionHandler?) -> TCBlobDownload {
        let downloadTask = self.session.downloadTaskWithRequest(request)
        let download = TCBlobDownload(downloadTask: downloadTask, toDirectory: directory, fileName: name, sessionConfigurationIdentifier: self.session.configuration.identifier!, progression: progression, completion: completion)

        return self.downloadWithDownload(download)
    }

    /**
        Resume a download with previously acquired resume data.
    
        :see: `TCBlobDownload -cancelWithResumeData:` to produce this data.

        - parameter resumeData: Data blob produced by a previous download cancellation.
        - parameter directory: Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
        - parameter name: Name to give to the file once the download is completed.
        - parameter delegate: An eventual delegate for this download.
    
        :return: A `TCBlobDownload` instance.
    */
    public func downloadFileWithResumeData(resumeData: NSData, toDirectory directory: NSURL?, withName name: String?, andDelegate delegate: TCBlobDownloadDelegate?) -> TCBlobDownload {
        let downloadTask = self.session.downloadTaskWithResumeData(resumeData)
        let download = TCBlobDownload(downloadTask: downloadTask, toDirectory: directory, fileName: name, delegate: delegate, sessionConfigurationIdentifier: self.session.configuration.identifier!)

        return self.downloadWithDownload(download)
    }

    /**
        Gets the downloads in a given state currently being processed by the instance of `TCBlobDownloadManager`.
    
        - parameter state: The state by which to filter the current downloads.
        
        :return: An `Array` of all current downloads with the given state.
    */
    public func currentDownloadsFilteredByState(state: NSURLSessionTaskState?) -> [TCBlobDownload] {
        return self.delegate.downloads.values.filter { state == nil || $0.downloadTask.state == state }
    }
}

extension TCBlobDownloadManager {
    
    class func taskQueueForSessionConfigurationIdentifier(configurationIdentifier: String) -> [String: TCBlobDownloadArchivable]? {
        let data = NSUserDefaults.standardUserDefaults().dataForKey(configurationIdentifier)

        if let d = data {
            return NSKeyedUnarchiver.unarchiveObjectWithData(d)  as? [String : TCBlobDownloadArchivable]
        }
        return nil
    }
}

public class DownloadDelegate: NSObject, NSURLSessionDownloadDelegate {

    public var backgroundTransferCompletionHandler: (() -> Void)? = {}

    var downloads: [Int: TCBlobDownload] = [:]
    let acceptableStatusCodes: Range<Int> = 200...299


    func validateResponse(response: NSHTTPURLResponse) -> Bool {
        return self.acceptableStatusCodes.contains(response.statusCode)
    }

    func restoreDownloadsForSession(session: NSURLSession) {
        self.downloadsForURLSession(session, completion: { [unowned self] (downloads) -> Void in
            self.downloads = downloads
        })
    }

    func existingArchivableDownloadForTask(task: NSURLSessionDownloadTask, session: NSURLSession) -> TCBlobDownloadArchivable? {
        if let downloads = TCBlobDownloadManager.taskQueueForSessionConfigurationIdentifier(session.configuration.identifier!) {
            return downloads[String(task.taskIdentifier)]
        }
        return nil
    }

    func downloadsForURLSession(session: NSURLSession, completion: ([Int : TCBlobDownload]) -> Void) {

        var downloads: [Int : TCBlobDownload] = [:]

        session.getTasksWithCompletionHandler { (data, uploadTasks, downloadTasks) -> Void in

            for t in downloadTasks {
                let task = t
                let download = self.existingArchivableDownloadForTask(task, session: session)
                if let d = download {
                    downloads[task.taskIdentifier] = d.downloadForTask(task)
                }
            }
            completion(downloads)
        }
    }
    // MARK: NSURLSessionDownloadDelegate

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("Resume at offset: \(fileOffset) total expected: \(expectedTotalBytes)")
    }

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let download = self.downloads[downloadTask.taskIdentifier]!

        let progress = totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown ? -1 : Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        download.progress = progress

        dispatch_async(dispatch_get_main_queue()) {
            download.delegate?.download(download, didProgress: progress, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            download.progression?(progress: progress, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            return
        }
    }

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let download = self.downloads[downloadTask.taskIdentifier]!
        var fileError: NSError?
        var resultingURL: NSURL?

        do {
            try NSFileManager.defaultManager().replaceItemAtURL(download.destinationURL, withItemAtURL: location, backupItemName: nil, options: [], resultingItemURL: &resultingURL)
            download.resultingURL = resultingURL
        } catch let error1 as NSError {
            fileError = error1
            download.error = fileError
        }
    }

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError sessionError: NSError?) {

        if let download = self.downloads[task.taskIdentifier] {

            var error: NSError? = sessionError ?? download.error
            // Handle possible HTTP errors
            if let response = task.response as? NSHTTPURLResponse {
                // NSURLErrorDomain errors are not supposed to be reported by this delegate
                // according to https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/NSURLSessionConcepts/NSURLSessionConcepts.html
                // so let's ignore them as they sometimes appear there for now. (But WTF?)
                if !validateResponse(response) && (error == nil || error!.domain == NSURLErrorDomain) {
                    error = NSError(domain: kTCBlobDownloadErrorDomain,
                        code: TCBlobDownloadError.TCBlobDownloadHTTPError.rawValue,
                        userInfo: [kTCBlobDownloadErrorDescriptionKey: "Erroneous HTTP status code: \(response.statusCode)",
                                   kTCBlobDownloadErrorFailingURLKey: task.originalRequest!.URL!,
                                   kTCBlobDownloadErrorHTTPStatusKey: response.statusCode])
                }
            }

            // Remove the reference to the download
            self.downloads.removeValueForKey(task.taskIdentifier)
            download.delete()

            dispatch_async(dispatch_get_main_queue()) {
                download.delegate?.download(download, didFinishWithError: error, atLocation: download.resultingURL)
                download.completion?(download: download, error: error, location: download.resultingURL)
                return
            }
        }
    }

    public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in

            if downloadTasks.count == 0 {
                
                if let completionHandler = self.backgroundTransferCompletionHandler {

                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        [unowned self] in

                        completionHandler()
                        self.backgroundTransferCompletionHandler = nil
                    })
                }
            }
        }
    }
}
