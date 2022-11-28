//
//  Tracker.swift
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
//  Authors: Jonathan Almeida, Joshua Beemster
//  License: Apache License Version 2.0
//

import Foundation

func uncaughtExceptionHandler(_ exception: NSException?) {
}

/// This class is used for tracking events, and delegates them to other classes responsible for sending, storage, etc.
class Tracker: NSObject {
    private var platformContextSchema: String = ""
    private var dataCollection = true

    private var builderFinished = false


    /// The object used for sessionization, i.e. it characterizes user activity.
    private(set) var session: Session?
    /// Previous screen view state.
    private(set) var previousScreenState: ScreenState?
    /// Current screen view state.
    private(set) var currentScreenState: ScreenState?
    /// List of tags associated to global contexts.
    
    private var trackerData: [String : NSObject]? = nil
    func setTrackerData() {
        var trackerVersion = kSPVersion
        if trackerVersionSuffix.count != 0 {
            var allowedCharSet = CharacterSet.alphanumerics
            allowedCharSet.formUnion(CharacterSet(charactersIn: ".-"))
            let suffix = trackerVersionSuffix.components(separatedBy: allowedCharSet.inverted).joined(separator: "")
            if suffix.count != 0 {
                trackerVersion = "\(trackerVersion) \(suffix)"
            }
        }
        trackerData = [
            kSPTrackerVersion : trackerVersion as NSObject,
            kSPNamespace : trackerNamespace as NSObject,
            kSPAppId : appId as NSObject
        ]
    }

    // MARK: - Setter

    private var _emitter: Emitter
    /// The emitter used to send events.
    var emitter: Emitter {
        get {
            return _emitter
        }
        set(emitter) {
            _emitter = emitter
        }
    }

    /// The subject used to represent the current user and persist user information.
    var subject: Subject?
    
    /// Whether to use Base64 encoding for events.
    var base64Encoded = TrackerDefaults.base64Encoded
    
    /// A unique identifier for an application.
    private var _appId: String
    var appId: String {
        get {
            return _appId
        }
        set(appId) {
            _appId = appId
            if builderFinished && trackerData != nil {
                setTrackerData()
            }
        }
    }
    
    private(set) var _trackerNamespace: String
    /// The identifier for the current tracker.
    var trackerNamespace: String {
        get {
            return _trackerNamespace
        }
        set(trackerNamespace) {
            _trackerNamespace = trackerNamespace
            if builderFinished && trackerData != nil {
                setTrackerData()
            }
        }
    }
    
    /// Version suffix for tracker wrappers.
    private var _trackerVersionSuffix: String = TrackerDefaults.trackerVersionSuffix
    var trackerVersionSuffix: String {
        get {
            return _trackerVersionSuffix
        }
        set(trackerVersionSuffix) {
            _trackerVersionSuffix = trackerVersionSuffix
            if builderFinished && trackerData != nil {
                setTrackerData()
            }
        }
    }
    
    var devicePlatform: DevicePlatform = TrackerDefaults.devicePlatform

    var logLevel: LogLevel {
        get {
            return Logger.logLevel
        }
        set {
            Logger.logLevel = newValue
        }
    }

    var loggerDelegate: LoggerDelegate? {
        get {
            return Logger.delegate
        }
        set(delegate) {
            Logger.delegate = delegate
        }
    }
    
    private var _sessionContext = false
    var sessionContext: Bool {
        get {
            return _sessionContext
        }
        set(sessionContext) {
            _sessionContext = sessionContext
            if session != nil && !sessionContext {
                session?.stopChecker()
                session = nil
            } else if builderFinished && session == nil && sessionContext {
                session = Session(
                    foregroundTimeout: foregroundTimeout,
                    andBackgroundTimeout: backgroundTimeout,
                    andTracker: self)
            }
        }
    }
    
    private var _deepLinkContext = false
    var deepLinkContext: Bool {
        get {
            return _deepLinkContext
        }
        set(deepLinkContext) {
            objc_sync_enter(self)
            _deepLinkContext = deepLinkContext
            if deepLinkContext {
                stateManager.addOrReplaceStateMachine(DeepLinkStateMachine())
            } else {
                _ = stateManager.removeStateMachine(DeepLinkStateMachine.identifier)
            }
            objc_sync_exit(self)
        }
    }
    
    private var _screenContext = false
    var screenContext: Bool {
        get {
            return _screenContext
        }
        set(screenContext) {
            objc_sync_enter(self)
            _screenContext = screenContext
            if screenContext {
                stateManager.addOrReplaceStateMachine(ScreenStateMachine())
            } else {
                _ = stateManager.removeStateMachine(ScreenStateMachine.identifier)
            }
            objc_sync_exit(self)
        }
    }
    
    var applicationContext = TrackerDefaults.applicationContext
    
    var autotrackScreenViews = TrackerDefaults.autotrackScreenViews
    
    private var _foregroundTimeout = TrackerDefaults.foregroundTimeout
    var foregroundTimeout: Int {
        get {
            return _foregroundTimeout
        }
        set(foregroundTimeout) {
            _foregroundTimeout = foregroundTimeout
            if builderFinished && session != nil {
                session?.foregroundTimeout = foregroundTimeout
            }
        }
    }
    
    private var _backgroundTimeout = TrackerDefaults.backgroundTimeout
    var backgroundTimeout: Int {
        get {
            return _backgroundTimeout
        }
        set(backgroundTimeout) {
            _backgroundTimeout = backgroundTimeout
            if builderFinished && session != nil {
                session?.backgroundTimeout = backgroundTimeout
            }
        }
    }
    
    private var _lifecycleEvents = false
    /// Returns whether lifecyle events is enabled.
    /// - Returns: Whether background and foreground events are sent.
    var lifecycleEvents: Bool {
        get {
            return _lifecycleEvents
        }
        set(lifecycleEvents) {
            objc_sync_enter(self)
            _lifecycleEvents = lifecycleEvents
            if lifecycleEvents {
                stateManager.addOrReplaceStateMachine(LifecycleStateMachine())
            } else {
                _ = stateManager.removeStateMachine(LifecycleStateMachine.identifier)
            }
            objc_sync_exit(self)
        }
    }
    
    var exceptionEvents = TrackerDefaults.exceptionEvents
    var installEvent = TrackerDefaults.installEvent
    var trackerDiagnostic = TrackerDefaults.trackerDiagnostic
    
    private var _userAnonymisation = TrackerDefaults.userAnonymisation
    var userAnonymisation: Bool {
        get {
            return _userAnonymisation
        }
        set(userAnonymisation) {
            if _userAnonymisation != userAnonymisation {
                _userAnonymisation = userAnonymisation
                if let session = session { session.startNewSession() }
            }
        }
    }

    var globalContextTags: [String] {
        return Array(globalContextGenerators.keys)
    }
    /// Dictionary of global contexts generators.
    var globalContextGenerators: [String : GlobalContext] = [:]

    /// GDPR context
    /// You can enable or disable the context by setting this property
    var gdprContext: GDPRContext?
    
    private var stateManager = StateManager()

    var inBackground: Bool {
        return session?.inBackground ?? false
    }

    var isTracking: Bool {
        return dataCollection
    }

    init(trackerNamespace: String,
         appId: String?,
         emitter: Emitter,
         builder: ((Tracker) -> (Void))) {
        self._emitter = emitter
        self._appId = appId ?? ""
        self._trackerNamespace = trackerNamespace
        
        super.init()
        builder(self)
        
        #if os(iOS)
        platformContextSchema = kSPMobileContextSchema
        #else
        platformContextSchema = kSPDesktopContextSchema
        #endif
        
        setup()
        checkInstall()
    }

    private func setup() {
        emitter.namespace = trackerNamespace // Needed to correctly send events to the right EventStore
        setTrackerData()
        
        if sessionContext {
            session = Session(
                foregroundTimeout: foregroundTimeout,
                andBackgroundTimeout: backgroundTimeout,
                andTracker: self)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveScreenViewNotification(_:)),
            name: NSNotification.Name("ScreenViewDidAppear"),
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveDiagnosticNotification(_:)),
            name: NSNotification.Name("TrackerDiagnostic"),
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveCrashReporting(_:)),
            name: NSNotification.Name("CrashReporting"),
            object: nil)

        if exceptionEvents {
            NSSetUncaughtExceptionHandler(uncaughtExceptionHandler)
        }

        builderFinished = true
    }

    private func checkInstall() {
        if installEvent {
            let installTracker = InstallTracker()
            let previousTimestamp = installTracker.previousInstallTimestamp
            installTracker.clearPreviousInstallTimestamp()
            if !installTracker.isNewInstall && previousTimestamp == nil {
                return
            }
            let data: [String: NSObject] = [:]
            let installEvent = SelfDescribingJson(schema: kSPApplicationInstallSchema, andDictionary: data)
            let event = SelfDescribing(eventData: installEvent)
            event.trueTimestamp = previousTimestamp // it can be nil
            let _ = track(event)
        }
    }
    

    /// Add new generator for global contexts associated with a string tag.
    /// If the string tag has been already set the new global context is not assigned.
    /// - Parameters:
    ///   - generator: The global context generator.
    ///   - tag: The tag associated to the global context.
    /// - Returns: Weather the global context has been added.
    func add(_ generator: GlobalContext, tag: String) -> Bool {
        if (globalContextGenerators)[tag] != nil {
            return false
        }
        (globalContextGenerators)[tag] = generator
        return true
    }

    /// Remove the global context associated with the string tag.
    /// If the string tag exist it returns the global context generator associated with.
    /// - Parameter tag: The tag associated to the global context.
    /// - Returns: The global context associated with the tag or `nil` in case of any entry with that string tag.
    func removeGlobalContext(_ tag: String) -> GlobalContext? {
        let toDelete = (globalContextGenerators)[tag]
        if toDelete != nil {
            globalContextGenerators.removeValue(forKey: tag)
        }
        return toDelete
    }

    /// Pauses all event tracking, storage and session checking.

    // MARK: - Extra Functions

    func pauseEventTracking() {
        dataCollection = false
        emitter.pauseTimer()
        session?.stopChecker()
    }

    func resumeEventTracking() {
        dataCollection = true
        emitter.resumeTimer()
        session?.startChecker()
    }

    /// Returns whether the application is in the background or foreground.
    /// - Returns: Whether application is suspended.

    // MARK: - Notifications management

    @objc func receiveScreenViewNotification(_ notification: Notification) {
        guard let name = notification.userInfo?["name"] as? String else { return }
        
        var type: String?
        if let typeId = (notification.userInfo?["type"] as? NSNumber)?.intValue,
           let screenType = ScreenType(rawValue: typeId) {
            type = ScreenView.stringWithScreenType(screenType)
        }
        
        let topViewControllerClassName = notification.userInfo?["topViewControllerClassName"] as? String
        let viewControllerClassName = notification.userInfo?["viewControllerClassName"] as? String

        if autotrackScreenViews {
            let event = ScreenView(name: name, screenId: nil)
            event.type = type
            event.viewControllerClassName = viewControllerClassName
            event.topViewControllerClassName = topViewControllerClassName
            let _ = track(event)
        }
    }

    @objc func receiveDiagnosticNotification(_ notification: Notification) {
        let userInfo = notification.userInfo
        guard let tag = userInfo?["tag"] as? String,
              let message = userInfo?["message"] as? String else { return }
        let error = userInfo?["error"] as? Error
        let exception = userInfo?["exception"] as? NSException

        if trackerDiagnostic {
            let event = TrackerError(source: tag, message: message, error: error, exception: exception)
            let _ = track(event)
        }
    }

    @objc func receiveCrashReporting(_ notification: Notification) {
        let userInfo = notification.userInfo
        guard let message = userInfo?["message"] as? String else { return }
        let stacktrace = userInfo?["stacktrace"] as? String

        if exceptionEvents {
            let event = SNOWError(message: message)
            event.stackTrace = stacktrace
            let _ = track(event)
        }
    }

    // MARK: - Events tracking methods

    /// Tracks an event despite its specific type.
    /// - Parameter event: The event to track
    /// - Returns: The event ID or nil in case tracking is paused

    // MARK: - Event Tracking Functions

    func track(_ event: Event) -> UUID? {
        if !dataCollection {
            return nil
        }
        event.beginProcessing(withTracker: self)
        let eventId = processEvent(event)
        event.endProcessing(withTracker: self)
        return eventId
    }

    // MARK: - Event Decoration

    func processEvent(_ event: Event) -> UUID {
        objc_sync_enter(self)
        let stateSnapshot = stateManager.trackerState(forProcessedEvent: event)
        objc_sync_exit(self)
        let trackerEvent = TrackerEvent(event: event, state: stateSnapshot)
        transformEvent(trackerEvent)
        let payload = self.payload(with: trackerEvent)
        emitter.addPayload(toBuffer: payload)
        return trackerEvent.eventId
    }

    func transformEvent(_ event: TrackerEvent) {
        // Application_install event needs the timestamp to the real installation event.
        if (event.schema == kSPApplicationInstallSchema) {
            if let trueTimestamp = event.trueTimestamp {
                event.timestamp = Int64(trueTimestamp.timeIntervalSince1970 * 1000)
                event.trueTimestamp = nil
            }
        }
        // Payload can be optionally updated with values based on internal state
        let _ = stateManager.addPayloadValues(to: event)
    }

    func payload(with event: TrackerEvent) -> Payload {
        let payload = Payload()
        payload.allowDiagnostic = !event.isService

        addBasicProperties(to: payload, event: event)
        if event.isPrimitive {
            addPrimitiveProperties(to: payload, event: event)
        } else {
            addSelfDescribingProperties(to: payload, event: event)
        }
        var contexts = event.contexts
        addBasicContexts(toContexts: &contexts, event: event)
        addGlobalContexts(toContexts: &contexts, event: event)
        addStateMachineEntities(toContexts: &contexts, event: event)
        wrapContexts(contexts, to: payload)
        if !event.isPrimitive {
            // TODO: To remove when Atomic table refactoring is finished
            workaround(forCampaignAttributionEnrichment: payload, event: event, contexts: &contexts)
        }
        return payload
    }

    func addBasicProperties(to payload: Payload, event: TrackerEvent) {
        payload.addValueToPayload(event.eventId.uuidString, forKey: kSPEid)
        payload.addValueToPayload(String(format: "%lld", event.timestamp), forKey: kSPTimestamp)
        if let trueTimestamp = event.trueTimestamp {
            let ttInMilliSeconds = Int64(trueTimestamp.timeIntervalSince1970 * 1000)
            payload.addValueToPayload(String(format: "%lld", ttInMilliSeconds), forKey: kSPTrueTimestamp)
        }
        payload.addDictionaryToPayload(trackerData)
        if let subjectDict = subject?.getStandardDict(withUserAnonymisation: userAnonymisation)?.dictionary {
            payload.addDictionaryToPayload(subjectDict)
        }
        payload.addValueToPayload(devicePlatformToString(devicePlatform), forKey: kSPPlatform)
    }

    func addPrimitiveProperties(to payload: Payload, event: TrackerEvent) {
        payload.addValueToPayload(event.eventName, forKey: kSPEvent)
        payload.addDictionaryToPayload(event.payload)
    }

    func addSelfDescribingProperties(to payload: Payload, event: TrackerEvent) {
        payload.addValueToPayload(kSPEventUnstructured, forKey: kSPEvent)

        if let schema = event.schema {
            let eventPayload = event.payload
            let data = SelfDescribingJson(schema: schema, andData: eventPayload as NSObject)
            if let data = data.dictionary as NSObject? {
                let unstructuredEventPayload: [String : NSObject] = [
                    kSPSchema: kSPUnstructSchema as NSObject,
                    kSPData: data
                ]
                payload.addDictionaryToPayload(
                    unstructuredEventPayload,
                    base64Encoded: base64Encoded,
                    typeWhenEncoded: kSPUnstructuredEncoded,
                    typeWhenNotEncoded: kSPUnstructured)
            }
        }
    }

    /*
     This is needed because the campaign-attribution-enrichment (in the pipeline) is able to parse
     the `url` and `referrer` only if they are part of a PageView event.
     The PageView event is an atomic event but the DeepLinkReceived and ScreenView are SelfDescribing events.
     For this reason we copy these two fields in the atomic fields in order to let the enrichment
     to process correctly the fields even if the event is not a PageView and it's a SelfDescribing event.
     This is a hack that should be removed once the atomic event table is dismissed and all the events
     will be SelfDescribing.
     */
    func workaround(forCampaignAttributionEnrichment payload: Payload, event: TrackerEvent, contexts: inout [SelfDescribingJson]) {
        var url: String?
        var referrer: String?

        if event.schema == DeepLinkReceived.schema {
            url = event.payload[DeepLinkReceived.paramUrl] as? String
            referrer = event.payload[DeepLinkReceived.paramReferrer] as? String
        } else if event.schema == kSPScreenViewSchema {
            for entity in contexts {
                if entity.schema == DeepLinkEntity.schema {
                    let data = entity.data as? [AnyHashable : Any]
                    url = data?[DeepLinkEntity.paramUrl] as? String
                    referrer = data?[DeepLinkEntity.paramReferrer] as? String
                    break
                }
            }
        }

        if let url = url {
            payload.addValueToPayload(url, forKey: kSPPageUrl)
        }
        if let referrer = referrer {
            payload.addValueToPayload(referrer, forKey: kSPPageRefr)
        }
    }

    func addBasicContexts(toContexts contexts: inout [SelfDescribingJson], event: TrackerEvent) {
        addBasicContexts(toContexts: &contexts, eventId: event.eventId.uuidString, eventTimestamp: event.timestamp, isService: event.isService)
    }

    func addBasicContexts(toContexts contexts: inout [SelfDescribingJson], eventId: String, eventTimestamp: Int64, isService: Bool) {
        if subject != nil {
            if let platformDict = subject?.getPlatformDict(withUserAnonymisation: userAnonymisation)?.dictionary {
                contexts.append(SelfDescribingJson(schema: platformContextSchema, andDictionary: platformDict))
            }
            if let geoLocationDict = subject?.getGeoLocationDict() {
                contexts.append(SelfDescribingJson(schema: kSPGeoContextSchema, andDictionary: geoLocationDict))
            }
        }

        if applicationContext {
            if let contextJson = Utilities.applicationContext {
                contexts.append(contextJson)
            }
        }

        if isService {
            return
        }

        // Add session
        if let session = session {
            if let sessionDict = session.getDictWithEventId(eventId, eventTimestamp: eventTimestamp, userAnonymisation: userAnonymisation) {
                contexts.append(SelfDescribingJson(schema: kSPSessionContextSchema, andDictionary: sessionDict))
            } else {
                logDiagnostic(message: String(format: "Unable to get session context for eventId: %@", eventId))
            }
        }

        // Add GDPR context
        if let gdprContext = gdprContext?.context {
            contexts.append(gdprContext)
        }
    }

    func addGlobalContexts(toContexts contexts: inout [SelfDescribingJson], event: InspectableEvent) {
        for (_, generator) in globalContextGenerators {
            contexts.append(contentsOf: generator.contexts(from: event))
        }
    }

    func addStateMachineEntities(toContexts contexts: inout [SelfDescribingJson], event: InspectableEvent) {
        let stateManagerEntities = stateManager.entities(forProcessedEvent: event)
        contexts.append(contentsOf: stateManagerEntities)
    }

    func wrapContexts(_ contexts: [SelfDescribingJson], to payload: Payload) {
        if contexts.count == 0 {
            return
        }
        var data: [[String : NSObject]] = []
        for context in contexts {
            if let dict = context.dictionary {
                data.append(dict)
            }
        }

        let finalContext = SelfDescribingJson(schema: kSPContextSchema, andData: data as NSObject)
        if let dict = finalContext.dictionary {
            payload.addDictionaryToPayload(
                dict,
                base64Encoded: base64Encoded,
                typeWhenEncoded: kSPContextEncoded,
                typeWhenNotEncoded: kSPContext)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
