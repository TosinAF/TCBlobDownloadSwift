//
//  TCBlobBackgroundDownloadManager.swift
//  CapillaryMVP
//
//  Created by Jeremy Bone on 6/26/15.
//  Copyright (c) 2015 Allogy Interactive. All rights reserved.
//

public class TCBlobBackgroundDownloadManager: TCBlobDownloadManager {

    public static let sharedBackground = TCBlobBackgroundDownloadManager()

    convenience init() {
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("tcblobdownloadmanager.background.session")
        self.init(config: config)
    }
}
