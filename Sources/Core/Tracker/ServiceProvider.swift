//
//  SPServiceProvider.swift
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

@objc(SPServiceProvider)
public class ServiceProvider: NSObject, ServiceProviderProtocol {
    public private(set) var namespace: String
    
    public var isTrackerInitialized: Bool { return _tracker != nil }

    // Internal services
    private var _subject: Subject?
    public var subject: Subject {
        if let _subject {
            return _subject
        }
        let subject = makeSubject()
        _subject = subject
        return subject
    }

    private var _emitter: Emitter?
    public var emitter: Emitter {
        if let _emitter {
            return _emitter
        }
        let emitter = makeEmitter()
        _emitter = emitter
        return emitter
    }

    private var _tracker: Tracker?
    public var tracker: Tracker {
        if let _tracker {
            return _tracker
        }
        let tracker = makeTracker()
        _tracker = tracker
        return tracker
    }

    // Controllers

    private var _trackerController: TrackerControllerImpl?
    public var trackerController: TrackerControllerImpl {
        if let _trackerController {
            return _trackerController
        }
        let trackerController = makeTrackerController()
        _trackerController = trackerController
        return trackerController
    }

    private var _sessionController: SessionControllerImpl?
    public var sessionController: SessionControllerImpl {
        if let _sessionController {
            return _sessionController
        }
        let sessionController = makeSessionController()
        _sessionController = sessionController
        return sessionController
    }

    private var _emitterController: EmitterControllerImpl?
    public var emitterController: EmitterControllerImpl {
        if let _emitterController {
            return _emitterController
        }
        let emitterController = makeEmitterController()
        _emitterController = emitterController
        return emitterController
    }

    private var _gdprController: GDPRControllerImpl?
    public var gdprController: GDPRControllerImpl {
        if let _gdprController {
            return _gdprController
        }
        let gdprController = makeGDPRController()
        _gdprController = gdprController
        return gdprController
    }

    private var _globalContextsController: GlobalContextsControllerImpl?
    public var globalContextsController: GlobalContextsControllerImpl {
        if let _globalContextsController {
            return _globalContextsController
        }
        let globalContextsController = makeGlobalContextsController()
        _globalContextsController = globalContextsController
        return globalContextsController
    }

    private var _subjectController: SubjectControllerImpl?
    public var subjectController: SubjectControllerImpl {
        if let _subjectController {
            return _subjectController
        }
        let subjectController = makeSubjectController()
        _subjectController = subjectController
        return subjectController
    }

    private var _networkController: NetworkControllerImpl?
    public var networkController: NetworkControllerImpl {
        if let _networkController {
            return _networkController
        }
        let networkController = makeNetworkController()
        _networkController = networkController
        return networkController
    }

    // Original configurations
    private var globalContextConfiguration: GlobalContextsConfiguration?

    // Configuration updates
    private(set) public var networkConfigurationUpdate = NetworkConfigurationUpdate()
    private(set) public var trackerConfigurationUpdate = TrackerConfigurationUpdate()
    private(set) public var emitterConfigurationUpdate = EmitterConfigurationUpdate()
    private(set) public var subjectConfigurationUpdate = SubjectConfigurationUpdate()
    private(set) public var sessionConfigurationUpdate = SessionConfigurationUpdate()
    private(set) public var gdprConfigurationUpdate = GDPRConfigurationUpdate()
    
    // MARK: - Init

    init(namespace: String, network networkConfiguration: NetworkConfiguration, configurations: [Configuration]) {
        self.namespace = namespace
        super.init()
        
        networkConfigurationUpdate.sourceConfig = networkConfiguration
        processConfigurations(configurations)
        if trackerConfigurationUpdate.sourceConfig == nil {
            trackerConfigurationUpdate.sourceConfig = TrackerConfiguration()
        }
        let _ = tracker // Build tracker to initialize NotificationCenter receivers
    }

    func reset(withConfigurations configurations: [Configuration]) {
        stopServices()
        resetConfigurationUpdates()
        processConfigurations(configurations)
        resetServices()
        let _ = tracker
    }

    func shutdown() {
        tracker.pauseEventTracking()
        stopServices()
        resetServices()
        resetControllers()
        initializeConfigurationUpdates()
    }

    // MARK: - Private methods

    func processConfigurations(_ configurations: [Configuration]) {
        for configuration in configurations {
            if let configuration = configuration as? NetworkConfiguration {
                networkConfigurationUpdate.sourceConfig = configuration
            } else if let configuration = configuration as? TrackerConfiguration {
                trackerConfigurationUpdate.sourceConfig = configuration
            } else if let configuration = configuration as? SubjectConfiguration {
                subjectConfigurationUpdate.sourceConfig = configuration
            } else if let configuration = configuration as? SessionConfiguration {
                sessionConfigurationUpdate.sourceConfig = configuration
            } else if let configuration = configuration as? EmitterConfiguration {
                emitterConfigurationUpdate.sourceConfig = configuration
            } else if let configuration = configuration as? GDPRConfiguration {
                gdprConfigurationUpdate.sourceConfig = configuration
            } else if let configuration = configuration as? GlobalContextsConfiguration {
                globalContextConfiguration = configuration
            }
        }
    }

    func stopServices() {
        emitter.pauseTimer()
    }

    func resetServices() {
        _emitter = nil
        _subject = nil
        _tracker = nil
    }

    func resetControllers() {
        _trackerController = nil
        _sessionController = nil
        _emitterController = nil
        _gdprController = nil
        _globalContextsController = nil
        _subjectController = nil
        _networkController = nil
    }

    func resetConfigurationUpdates() {
        // Don't reset networkConfiguration as it's needed in case it's not passed in the new configurations.
        // Set a default trackerConfiguration to reset to default if not passed.
        trackerConfigurationUpdate.sourceConfig = TrackerConfiguration()
        emitterConfigurationUpdate.sourceConfig = nil
        subjectConfigurationUpdate.sourceConfig = nil
        sessionConfigurationUpdate.sourceConfig = nil
        gdprConfigurationUpdate.sourceConfig = nil
    }

    func initializeConfigurationUpdates() {
        networkConfigurationUpdate = NetworkConfigurationUpdate()
        trackerConfigurationUpdate = TrackerConfigurationUpdate()
        emitterConfigurationUpdate = EmitterConfigurationUpdate()
        subjectConfigurationUpdate = SubjectConfigurationUpdate()
        sessionConfigurationUpdate = SessionConfigurationUpdate()
        gdprConfigurationUpdate = GDPRConfigurationUpdate()
    }

    // MARK: - Getters

    // MARK: - Factories

    //#pragma clang diagnostic push
    //#pragma clang diagnostic ignored "-Wdeprecated-declarations"

    func makeSubject() -> Subject {
        return Subject(
            platformContext: trackerConfigurationUpdate.platformContext,
            geoLocationContext: trackerConfigurationUpdate.geoLocationContext,
            subjectConfiguration: subjectConfigurationUpdate)
    }

    func makeEmitter() -> Emitter {
        let networkConfig = networkConfigurationUpdate
        let emitterConfig = emitterConfigurationUpdate
        
        let builder = { (emitter: Emitter) in
            emitter.method = networkConfig.method
            emitter.protocol = networkConfig.protocol
            emitter.customPostPath = networkConfig.customPostPath
            emitter.requestHeaders = networkConfig.requestHeaders
            emitter.emitThreadPoolSize = emitterConfig.threadPoolSize
            emitter.byteLimitGet = emitterConfig.byteLimitGet
            emitter.byteLimitPost = emitterConfig.byteLimitPost
            emitter.serverAnonymisation = emitterConfig.serverAnonymisation
            emitter.emitRange = emitterConfig.emitRange
            emitter.bufferOption = emitterConfig.bufferOption
            emitter.eventStore = emitterConfig.eventStore
            emitter.callback = emitterConfig.requestCallback
            emitter.customRetryForStatusCodes = emitterConfig.customRetryForStatusCodes
        }

        let emitter: Emitter
        if let networkConnection = networkConfig.networkConnection {
            emitter = Emitter(networkConnection: networkConnection, builder: builder)
        } else {
            emitter = Emitter(urlEndpoint: networkConfig.endpoint!, builder: builder)
        }
        
        if emitterConfig.isPaused {
            emitter.pauseEmit()
        }
        return emitter
    }

    func makeTracker() -> Tracker {
        let emitter = self.emitter
        let subject = self.subject
        
        let trackerConfig = trackerConfigurationUpdate
        let sessionConfig = sessionConfigurationUpdate
        let gcConfig = globalContextConfiguration
        let gdprConfig = gdprConfigurationUpdate
        
        let tracker = Tracker(
            trackerNamespace: namespace,
            appId: trackerConfig.appId,
            emitter: emitter
        ) { tracker in
            if let suffix = trackerConfig.trackerVersionSuffix {
                tracker.trackerVersionSuffix = suffix
            }
            tracker.sessionContext = trackerConfig.sessionContext
            tracker.foregroundTimeout = sessionConfig.foregroundTimeoutInSeconds
            tracker.backgroundTimeout = sessionConfig.backgroundTimeoutInSeconds
            tracker.exceptionEvents = trackerConfig.exceptionAutotracking
            tracker.subject = subject
            tracker.base64Encoded = trackerConfig.base64Encoding
            tracker.logLevel = trackerConfig.logLevel
            tracker.loggerDelegate = trackerConfig.loggerDelegate
            tracker.devicePlatform = trackerConfig.devicePlatform
            tracker.applicationContext = trackerConfig.applicationContext
            tracker.deepLinkContext = trackerConfig.deepLinkContext
            tracker.screenContext = trackerConfig.screenContext
            tracker.autotrackScreenViews = trackerConfig.screenViewAutotracking
            tracker.lifecycleEvents = trackerConfig.lifecycleAutotracking
            tracker.installEvent = trackerConfig.installAutotracking
            tracker.trackerDiagnostic = trackerConfig.diagnosticAutotracking
            tracker.userAnonymisation = trackerConfig.userAnonymisation
            if let gcConfig {
                tracker.globalContextGenerators = gcConfig.contextGenerators
            }
            if gdprConfig.sourceConfig != nil {
                tracker.gdprContext = GDPRContext(
                    basis: gdprConfig.basisForProcessing,
                    documentId: gdprConfig.documentId,
                    documentVersion: gdprConfig.documentVersion,
                    documentDescription: gdprConfig.documentDescription)
            }
        }
        
        if trackerConfigurationUpdate.isPaused {
            tracker.pauseEventTracking()
        }
        if let session = tracker.session {
            if sessionConfigurationUpdate.isPaused {
                session.stopChecker()
            }
            if let callback = sessionConfigurationUpdate.onSessionStateUpdate {
                session.onSessionStateUpdate = callback
            }
        }
        return tracker
    }

    func makeTrackerController() -> TrackerControllerImpl {
        return TrackerControllerImpl(serviceProvider: self)
    }

    func makeSessionController() -> SessionControllerImpl {
        return SessionControllerImpl(serviceProvider: self)
    }

    func makeEmitterController() -> EmitterControllerImpl {
        return EmitterControllerImpl(serviceProvider: self)
    }

    func makeGDPRController() -> GDPRControllerImpl {
        let controller = GDPRControllerImpl(serviceProvider: self)
        if let gdpr = tracker.gdprContext {
            controller.reset(basis: gdpr.basis, documentId: gdpr.documentId, documentVersion: gdpr.documentVersion, documentDescription: gdpr.documentDescription)
        }
        return controller
    }

    func makeGlobalContextsController() -> GlobalContextsControllerImpl {
        return GlobalContextsControllerImpl(serviceProvider: self)
    }

    func makeSubjectController() -> SubjectControllerImpl {
        return SubjectControllerImpl(serviceProvider: self)
    }

    func makeNetworkController() -> NetworkControllerImpl {
        return NetworkControllerImpl(serviceProvider: self)
    }
}
