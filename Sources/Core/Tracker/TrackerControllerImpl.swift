//
//  SPTrackerController.h
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

//
//  SPTrackerController.m
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

@objc(SPTrackerControllerImpl)
public class TrackerControllerImpl: Controller, TrackerController {
    
    // MARK: - Controllers

    public var network: NetworkController? {
        return serviceProvider.networkController()
    }

    public var emitter: EmitterController? {
        return serviceProvider.emitterController()
    }

    public var gdpr: GDPRController? {
        return serviceProvider.gdprController()
    }

    public var globalContexts: GlobalContextsController? {
        return serviceProvider.globalContextsController()
    }

    public var subject: SubjectController? {
        return serviceProvider.subjectController()
    }

    public var sessionController: SessionControllerImpl {
        return serviceProvider.sessionController()
    }

    public var session: SessionController? {
        let sessionController = serviceProvider.sessionController()
        return sessionController.isEnabled ? sessionController : nil
    }

    // MARK: - Control methods

    public func pause() {
        dirtyConfig.isPaused = true
        tracker.pauseEventTracking()
    }

    public func resume() {
        dirtyConfig.isPaused = false
        tracker.resumeEventTracking()
    }

    public func track(_ event: Event) -> UUID? {
        return tracker.track(event)
    }

    // MARK: - Properties' setters and getters

    public var appId: String {
        get {
            return tracker.appId
        }
        set {
            dirtyConfig.appId = newValue
            dirtyConfig.appIdUpdated = true
            tracker.setAppId(newValue)
        }
    }

    public var namespace: String {
        return (tracker).trackerNamespace
    }

    public var devicePlatform: DevicePlatform {
        get {
            return DevicePlatform(rawValue: tracker.getDevicePlatformRawValue()) ?? .mobile
        }
        set {
            dirtyConfig.devicePlatform = newValue
            dirtyConfig.devicePlatformUpdated = true
            tracker.setDevicePlatformRawValue(newValue.rawValue)
        }
    }

    public var base64Encoding: Bool {
        get {
            return tracker.base64Encoded
        }
        set {
            dirtyConfig.base64Encoding = newValue
            dirtyConfig.base64EncodingUpdated = true
            tracker.setBase64Encoded(newValue)
        }
    }

    public var logLevel: LogLevel {
        get {
            return LogLevel(rawValue: Logger.logLevelRawValue()) ?? .off
        }
        set {
            dirtyConfig.logLevel = newValue
            dirtyConfig.logLevelUpdated = true
            Logger.setLogLevelRawValue(newValue.rawValue)
        }
    }

    public var loggerDelegate: LoggerDelegate? {
        get {
            return Logger.delegate
        }
        set {
            Logger.delegate = newValue
        }
    }

    public var applicationContext: Bool {
        get {
            return tracker.applicationContext()
        }
        set {
            dirtyConfig.applicationContext = newValue
            dirtyConfig.applicationContextUpdated = true
            tracker.setApplicationContext(newValue)
        }
    }

    public var platformContext: Bool {
        get {
            return tracker.subject?.platformContext ?? false
        }
        set {
            dirtyConfig.platformContext = newValue
            dirtyConfig.platformContextUpdated = true
            tracker.subject?.platformContext = newValue
        }
    }

    func setGeoLocationContext(_ geoLocationContext: Bool) {
    }

    public var geoLocationContext: Bool {
        get {
            return tracker.subject?.geoLocationContext ?? false
        }
        set {
            dirtyConfig.geoLocationContext = newValue
            dirtyConfig.geoLocationContextUpdated = true
            tracker.subject?.geoLocationContext = newValue
        }
    }

    public var diagnosticAutotracking: Bool {
        get {
            return tracker.trackerDiagnostic()
        }
        set {
            dirtyConfig.diagnosticAutotracking = newValue
            dirtyConfig.diagnosticAutotrackingUpdated = true
            tracker.setTrackerDiagnostic(newValue)
        }
    }

    public var exceptionAutotracking: Bool {
        get {
            return tracker.exceptionEvents()
        }
        set {
            dirtyConfig.exceptionAutotracking = newValue
            dirtyConfig.exceptionAutotrackingUpdated = true
            tracker.setExceptionEvents(newValue)
        }
    }

    public var installAutotracking: Bool {
        get {
            return tracker.installEvent()
        }
        set {
            dirtyConfig.installAutotracking = newValue
            dirtyConfig.installAutotrackingUpdated = true
            tracker.setInstallEvent(newValue)
        }
    }

    public var lifecycleAutotracking: Bool {
        get {
            return tracker.getLifecycleEvents()
        }
        set {
            dirtyConfig.lifecycleAutotracking = newValue
            dirtyConfig.lifecycleAutotrackingUpdated = true
            tracker.setLifecycleEvents(newValue)
        }
    }

    public var deepLinkContext: Bool {
        get {
            return tracker.deepLinkContext()
        }
        set {
            dirtyConfig.deepLinkContext = newValue
            dirtyConfig.deepLinkContextUpdated = true
            tracker.setDeepLinkContext(newValue)
        }
    }

    public var screenContext: Bool {
        get {
            return tracker.screenContext()
        }
        set {
            dirtyConfig.screenContext = newValue
            dirtyConfig.screenContextUpdated = true
            tracker.setScreenContext(newValue)
        }
    }

    public var screenViewAutotracking: Bool {
        get {
            return tracker.autoTrackScreenView()
        }
        set {
            dirtyConfig.screenViewAutotracking = newValue
            dirtyConfig.screenViewAutotrackingUpdated = true
            tracker.setAutotrackScreenViews(newValue)
        }
    }

    public var trackerVersionSuffix: String? {
        get {
            return tracker.trackerVersionSuffix
        }
        set {
            dirtyConfig.trackerVersionSuffix = newValue
            dirtyConfig.trackerVersionSuffixUpdated = true
            if let value = newValue {
                tracker.setTrackerVersionSuffix(value)
            }
        }
    }

    public var sessionContext: Bool {
        get {
            return tracker.sessionContext()
        }
        set {
            dirtyConfig.sessionContext = newValue
            dirtyConfig.sessionContextUpdated = true
            tracker.setSessionContext(newValue)
        }
    }
    
    public var userAnonymisation: Bool {
        get {
            return tracker.userAnonymisation()
        }
        set {
            dirtyConfig.userAnonymisation = newValue
            dirtyConfig.userAnonymisationUpdated = true
            tracker.setUserAnonymisation(newValue)
        }
    }

    public var isTracking: Bool {
        return tracker.getIsTracking()
    }

    public var version: String {
        return kSPVersion
    }

    // MARK: - Private methods

    private var tracker: Tracker {
        return serviceProvider.tracker()
    }

    private var dirtyConfig: TrackerConfigurationUpdate {
        return serviceProvider.trackerConfigurationUpdate()
    }
}
