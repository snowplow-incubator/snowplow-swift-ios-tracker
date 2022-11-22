//
//  PlatformContext.swift
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
//  Authors: Matus Tomlein
//  License: Apache License Version 2.0
//

import Foundation
import UIKit

/// @class PlatformContext
/// Manages a dictionary (Payload) with platform context. Some properties for mobile platforms are updated on fetch in set intervals.
class PlatformContext {
    private var platformDict: Payload = Payload()
    private var mobileDictUpdateFrequency: TimeInterval = 0.0
    private var networkDictUpdateFrequency: TimeInterval = 0.0
    private var lastUpdatedEphemeralMobileDict: TimeInterval = 0.0
    private var lastUpdatedEphemeralNetworkDict: TimeInterval = 0.0

    /// Initializes a newly allocated PlatformContext object with default update frequency
    /// - Returns: a PlatformContext object
    convenience init() {
        self.init(mobileDictUpdateFrequency: 0.1, networkDictUpdateFrequency: 10.0)
    }

    /// Initializes a newly allocated PlatformContext object with custom update frequency for mobile and network properties
    /// - Parameters:
    ///   - mobileDictUpdateFrequency: Minimal gap between subsequent updates of mobile platform information
    ///   - networkDictUpdateFrequency: Minimal gap between subsequent updates of network platform information
    /// - Returns: a PlatformContext object
    convenience init(mobileDictUpdateFrequency: TimeInterval, networkDictUpdateFrequency: TimeInterval) {
        self.init(mobileDictUpdateFrequency: mobileDictUpdateFrequency, networkDictUpdateFrequency: networkDictUpdateFrequency)
    }

    /// Initializes a newly allocated PlatformContext object with custom update frequency for mobile and network properties and a custom device info monitor
    /// - Parameters:
    ///   - mobileDictUpdateFrequency: Minimal gap between subsequent updates of mobile platform information
    ///   - networkDictUpdateFrequency: Minimal gap between subsequent updates of network platform information
    ///   - deviceInfoMonitor: Device monitor for fetching platform information
    /// - Returns: a PlatformContext object
    init(mobileDictUpdateFrequency: TimeInterval, networkDictUpdateFrequency: TimeInterval, deviceInfoMonitor: DeviceInfoMonitor) {
        self.mobileDictUpdateFrequency = mobileDictUpdateFrequency
        self.networkDictUpdateFrequency = networkDictUpdateFrequency
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif
        setPlatformDict()
    }

    /// Updates and returns payload dictionary with device context information.
    /// - Parameter userAnonymisation: Whether to anonymise user identifiers (IDFA values)
    func fetchPlatformDict(withUserAnonymisation userAnonymisation: Bool) -> Payload {
        #if os(iOS)
        objc_sync_enter(self)
        let now = Date().timeIntervalSince1970
        if now - lastUpdatedEphemeralMobileDict >= mobileDictUpdateFrequency {
            setEphemeralMobileDict()
        }
        if now - lastUpdatedEphemeralNetworkDict >= networkDictUpdateFrequency {
            setEphemeralNetworkDict()
        }
        objc_sync_exit(self)
        #endif
        if userAnonymisation {
            // mask user identifiers
            let copy = Payload(dictionary: platformDict.getAsDictionary() ?? [:])
            copy.addValueToPayload(nil, forKey: kSPMobileAppleIdfa)
            copy.addValueToPayload(nil, forKey: kSPMobileAppleIdfv)
            return copy
        } else {
            return platformDict
        }
    }

    // MARK: - Private methods

    func setPlatformDict() {
        platformDict = Payload()
        platformDict.addValueToPayload(DeviceInfoMonitor.osType, forKey: kSPPlatformOsType)
        platformDict.addValueToPayload(DeviceInfoMonitor.osVersion, forKey: kSPPlatformOsVersion)
        platformDict.addValueToPayload(DeviceInfoMonitor.deviceVendor, forKey: kSPPlatformDeviceManu)
        platformDict.addValueToPayload(DeviceInfoMonitor.deviceModel, forKey: kSPPlatformDeviceModel)

        #if os(iOS)
        setMobileDict()
        #endif
    }

    func setMobileDict() {
        platformDict.addValueToPayload(DeviceInfoMonitor.carrierName, forKey: kSPMobileCarrier)
        if let totalStorage = DeviceInfoMonitor.totalStorage {
            platformDict.addNumericValueToPayload(NSNumber(value: totalStorage), forKey: kSPMobileTotalStorage)
        }
        platformDict.addNumericValueToPayload(NSNumber(value: DeviceInfoMonitor.physicalMemory), forKey: kSPMobilePhysicalMemory)
        
        setEphemeralMobileDict()
        setEphemeralNetworkDict()
    }

    func setEphemeralMobileDict() {
        lastUpdatedEphemeralMobileDict = Date().timeIntervalSince1970

        if let currentDict = platformDict.getAsDictionary() {
            if currentDict[kSPMobileAppleIdfa] == nil {
                platformDict.addValueToPayload(DeviceInfoMonitor.appleIdfa, forKey: kSPMobileAppleIdfa)
            }
            if currentDict[kSPMobileAppleIdfv] == nil {
                platformDict.addValueToPayload(DeviceInfoMonitor.appleIdfv, forKey: kSPMobileAppleIdfv)
            }
            
            if let batteryLevel = DeviceInfoMonitor.batteryLevel {
                platformDict.addNumericValueToPayload(NSNumber(value: batteryLevel), forKey: kSPMobileBatteryLevel)
            }
            platformDict.addValueToPayload(DeviceInfoMonitor.batteryState, forKey: kSPMobileBatteryState)
            if let isLowPowerModeEnabled = DeviceInfoMonitor.isLowPowerModeEnabled {
                platformDict.addNumericValueToPayload(NSNumber(value: isLowPowerModeEnabled), forKey: kSPMobileLowPowerMode)
            }
            if let availableStorage = DeviceInfoMonitor.availableStorage {
                platformDict.addNumericValueToPayload(NSNumber(value: availableStorage), forKey: kSPMobileAvailableStorage)
            }
            if let appAvailableMemory = DeviceInfoMonitor.appAvailableMemory {
                platformDict.addNumericValueToPayload(NSNumber(value: appAvailableMemory), forKey: kSPMobileAppAvailableMemory)
            }
        }
    }

    func setEphemeralNetworkDict() {
        lastUpdatedEphemeralNetworkDict = Date().timeIntervalSince1970

        platformDict.addValueToPayload(DeviceInfoMonitor.networkTechnology, forKey: kSPMobileNetworkTech)
        platformDict.addValueToPayload(DeviceInfoMonitor.networkType, forKey: kSPMobileNetworkType)
    }
}
