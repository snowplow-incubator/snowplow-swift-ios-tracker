//
//  SPConfigurationCache.swift
//  Snowplow
//
//  Copyright (c) 2013-2022 Snowplow Analytics Ltd. All rights reserved.
//
//  This program is licensed to you under the Apache License Version 2.0,
//  and you may not use this file except in compliance with the Apache License
//  Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
//  http://www.apache.org/licenses/LICENSE-2.0.
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the Apache License Version 2.0 is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
//  express or implied. See the Apache License Version 2.0 for the specific
//  language governing permissions and limitations there under.
//
//  Authors: Alex Benini
//  License: Apache License Version 2.0
//

import Foundation

class ConfigurationCache: NSObject {
    private var cacheFileUrl: URL?
    private var configuration: FetchedConfigurationBundle?

    init(remoteConfiguration: RemoteConfiguration) {
        super.init()
        #if !(TARGET_OS_TV) && !(TARGET_OS_WATCH)
        createCachePath(with: remoteConfiguration)
        #endif
    }

    func read() -> FetchedConfigurationBundle? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        #if !(TARGET_OS_TV) && !(TARGET_OS_WATCH)
        if let configuration {
            return configuration
        }
        load()
        #endif
        return configuration
    }

    func write(_ configuration: FetchedConfigurationBundle) {
        objc_sync_enter(self)
        self.configuration = configuration
        #if !(TARGET_OS_TV) && !(TARGET_OS_WATCH)
        store()
        #endif
        objc_sync_exit(self)
    }

    func clear() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        configuration = nil
        #if !(TARGET_OS_TV) && !(TARGET_OS_WATCH)
        if let cacheFileUrl {
            do {
                try FileManager.default.removeItem(at: cacheFileUrl)
            } catch let e {
                //            SPLogError("Error on clearing configuration from cache: %@", error.localizedDescription)
            }
        }
        #endif
    }

    // Private method

    func load() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        guard let cacheFileUrl,
              let data = try? Data(contentsOf: cacheFileUrl) else { return }
        do {
            if #available(iOS 12, tvOS 12, watchOS 5, macOS 10.14, *) {
                configuration = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? FetchedConfigurationBundle
            } else {
                var unarchiver = NSKeyedUnarchiver(forReadingWith: data)
                configuration = unarchiver.decodeObject() as? FetchedConfigurationBundle
                unarchiver.finishDecoding()
            }
        } catch let e {
//          SPLogError("Exception on getting configuration from cache: %@", exception.reason)
            configuration = nil
        }
    }

    func store() {
        DispatchQueue.global(qos: .default)
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard let configuration, let cacheFileUrl else { return }
        
        do {
            var data = Data()
            var archiver: NSKeyedArchiver?
            
            if #available(iOS 12, tvOS 12, watchOS 5, macOS 10.14, *) {
                archiver = NSKeyedArchiver(requiringSecureCoding: true)
                archiver?.encode(configuration, forKey: "root")
                if let encodedData = archiver?.encodedData {
                    data = encodedData
                }
            } else {
                archiver = NSKeyedArchiver(forWritingWith: data as! NSMutableData)
                archiver?.encode(configuration)
                archiver?.finishEncoding()
            }
            try data.write(to: cacheFileUrl, options: .atomic)
        } catch let e {
            //     SPLogError("Error on caching configuration: %@", error.localizedDescription)
        }
    }

    func createCachePath(with remoteConfiguration: RemoteConfiguration) {
        let fm = FileManager.default
        var url = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).last
        url = url?.appendingPathComponent("snowplow-cache")
        do {
            if let url {
                try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
        }
        let fileName = String(format: "remoteConfig-%lu.data", UInt((remoteConfiguration.endpoint).hash))
        url = url?.appendingPathComponent(fileName, isDirectory: false)
        if let url {
            cacheFileUrl = url
        }
    }
}
