//
//  SPTracker.m
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

#import "SPTrackerConstants.h"
#import "SPTracker.h"
#import "SPEmitter.h"
#import "SPSubject.h"
#import "SPUtilities.h"
#import "SPSession.h"
#import "SPInstallTracker.h"
#import "SPGlobalContext.h"

#import "SPLogger.h"

#import "SPServiceProvider.h"
#import "SPEmitterEventProcessing.h"

#import "SPStateManager.h"
#import "SPScreenStateMachine.h"
#import "SPDeepLinkStateMachine.h"
#import "SPLifecycleStateMachine.h"

#import <SnowplowTracker/SnowplowTracker-Swift.h>

/** A class extension that makes the screen view states mutable internally. */
@interface SPTracker ()

@property (nonatomic) SPGdprContext *gdpr;

@property (nonatomic) SPStateManager *stateManager;

/*!
 @brief This method is called to send an auto-tracked screen view event.

 @param notification The notification raised by a UIViewController
 */
- (void) receiveScreenViewNotification:(NSNotification *)notification;

@end

void uncaughtExceptionHandler(NSException *exception) {
    NSArray* symbols = exception.callStackSymbols;
    NSString * stacktrace = [NSString stringWithFormat:@"Stacktrace:\n%@", symbols];
    NSString * message = exception.reason;
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (message == nil || message.length == 0) {
            return;
        }

        // Construct userInfo
        NSMutableDictionary<NSString *, NSObject *> *userInfo = [NSMutableDictionary new];
        userInfo[@"message"] = message;
        userInfo[@"stacktrace"] = stacktrace;

        // Send notification to tracker
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"SPCrashReporting"
         object:nil
         userInfo:userInfo];

        [NSThread sleepForTimeInterval:2.0f];
    });
}

#pragma mark - SPTracker implementation

@implementation SPTracker {
    NSMutableDictionary *  _trackerData;
    NSString *             _platformContextSchema;
    BOOL                   _dataCollection;
    SPSession *            _session;
    BOOL                   _sessionContext;
    BOOL                   _deepLinkContext;
    BOOL                   _screenContext;
    BOOL                   _applicationContext;
    BOOL                   _autotrackScreenViews;
    BOOL                   _lifecycleEvents;
    NSInteger              _foregroundTimeout;
    NSInteger              _backgroundTimeout;
    BOOL                   _builderFinished;
    BOOL                   _exceptionEvents;
    BOOL                   _installEvent;
    BOOL                   _trackerDiagnostic;
    BOOL                   _userAnonymisation;
    NSString *             _trackerVersionSuffix;
}

// MARK: - Added property methods

- (BOOL)applicationContext {
    return _applicationContext;
}

- (BOOL)exceptionEvents {
    return _exceptionEvents;
}

- (BOOL)installEvent {
    return _installEvent;
}

- (BOOL)deepLinkContext {
    return _deepLinkContext;
}

- (BOOL)screenContext {
    return _screenContext;
}

- (BOOL)autoTrackScreenView {
    return _autotrackScreenViews;
}

- (BOOL)sessionContext {
    return _sessionContext;
}

- (BOOL)trackerDiagnostic {
    return _trackerDiagnostic;
}

- (BOOL)userAnonymisation {
    return _userAnonymisation;
}

// MARK: - Methods

+ (instancetype) build:(void(^)(id<SPTrackerBuilder>builder))buildBlock {
    SPTracker *tracker = [[SPTracker alloc] initWithDefaultValues];
    if (buildBlock) {
        buildBlock(tracker);
    }
    [tracker setup];
    [tracker checkInstall];
    return tracker;
}

- (instancetype) initWithDefaultValues {
    self = [super init];
    if (self) {
        _trackerNamespace = nil;
        _appId = nil;
        _trackerVersionSuffix = nil;
        _devicePlatform = [SPUtilities getPlatform];
        _base64Encoded = YES;
        _dataCollection = YES;
        _sessionContext = NO;
        _applicationContext = NO;
        _screenContext = NO;
        _lifecycleEvents = NO;
        _autotrackScreenViews = NO;
        _foregroundTimeout = 1800;
        _backgroundTimeout = 1800;
        _builderFinished = NO;
        self.globalContextGenerators = [NSMutableDictionary dictionary];
        self.stateManager = [SPStateManager new];
        _exceptionEvents = NO;
        _installEvent = NO;
        _trackerDiagnostic = NO;
        _userAnonymisation = NO;
#if SNOWPLOW_TARGET_IOS
        _platformContextSchema = kSPMobileContextSchema;
#else
        _platformContextSchema = kSPDesktopContextSchema;
#endif
    }
    return self;
}

- (void) setup {
    [SPUtilities checkArgument:(_emitter != nil) withMessage:@"Emitter cannot be nil."];
    _trackerNamespace = _trackerNamespace ?: @"default";
    [_emitter setNamespace:_trackerNamespace]; // Needed to correctly send events to the right EventStore

    [self setTrackerData];
    if (_sessionContext) {
        _session = [[SPSession alloc] initWithForegroundTimeout:_foregroundTimeout
                                           andBackgroundTimeout:_backgroundTimeout
                                                     andTracker:self];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveScreenViewNotification:)
                                                 name:@"SPScreenViewDidAppear"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveDiagnosticNotification:)
                                                 name:@"SPTrackerDiagnostic"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveCrashReportingNotification:)
                                                 name:@"SPCrashReporting"
                                               object:nil];

    if (_exceptionEvents) {
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    }

    _builderFinished = YES;
}

- (void)checkInstall {
    if (_installEvent) {
        SPInstallTracker * installTracker = [[SPInstallTracker alloc] init];
        NSDate *previousTimestamp = installTracker.previousInstallTimestamp;
        [installTracker clearPreviousInstallTimestamp];
        if (!installTracker.isNewInstall && previousTimestamp == nil) {
            return;
        }
        SPSelfDescribingJson *installEvent = [[SPSelfDescribingJson alloc] initWithSchema:kSPApplicationInstallSchema andData:@{}];
        SPSelfDescribing *event = [[SPSelfDescribing alloc] initWithEventData:installEvent];
        event.trueTimestamp = previousTimestamp; // it can be nil
        [self track:event];
    }
}

- (void) setTrackerData {
    NSString *trackerVersion = kSPVersion;
    if (_trackerVersionSuffix.length) {
        NSMutableCharacterSet *allowedCharSet = [NSMutableCharacterSet alphanumericCharacterSet];
        [allowedCharSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@".-"]];
        NSString *suffix = [[_trackerVersionSuffix componentsSeparatedByCharactersInSet:allowedCharSet.invertedSet] componentsJoinedByString:@""];
        if (suffix.length) {
            trackerVersion = [NSString stringWithFormat:@"%@ %@", trackerVersion, suffix];
        }
    }
    _trackerData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    trackerVersion, kSPTrackerVersion,
                    _trackerNamespace, kSPNamespace,
                    _appId != nil ? _appId : [NSNull null], kSPAppId, nil];
}

#pragma mark - Setter

- (void) setEmitter:(SPEmitter *)emitter {
    if (emitter != nil) {
        _emitter = emitter;
    }
}

- (void) setSubject:(SPSubject *)subject {
    _subject = subject;
}

- (void) setBase64Encoded:(BOOL)encoded {
    _base64Encoded = encoded;
}

- (void) setAppId:(NSString *)appId {
    _appId = appId;
    if (_builderFinished && _trackerData != nil) {
        [self setTrackerData];
    }
}

- (void) setTrackerNamespace:(NSString *)trackerNamespace {
    _trackerNamespace = trackerNamespace;
    if (_builderFinished && _trackerData != nil) {
        [self setTrackerData];
    }
}

- (void) setTrackerVersionSuffix:(NSString *)trackerVersionSuffix {
    _trackerVersionSuffix = trackerVersionSuffix;
    if (_builderFinished && _trackerData != nil) {
        [self setTrackerData];
    }
}

- (void) setDevicePlatform:(SPDevicePlatform)devicePlatform {
    _devicePlatform = devicePlatform;
}

- (void) setDevicePlatformRawValue:(NSInteger)devicePlatform {
    [self setDevicePlatform:(SPDevicePlatform)devicePlatform];
}

- (void)setLogLevel:(SPLogLevel)logLevel {
    [SPLogger setLogLevel:logLevel];
}

- (void)setLoggerDelegate:(id<SPLoggerDelegate>)delegate {
    [SPLogger setDelegate:delegate];
}

- (void) setSessionContext:(BOOL)sessionContext {
    _sessionContext = sessionContext;
    if (_session != nil && !sessionContext) {
        [_session stopChecker];
        _session = nil;
    } else if (_builderFinished && _session == nil && sessionContext) {
        _session = [[SPSession alloc] initWithForegroundTimeout:_foregroundTimeout
                                           andBackgroundTimeout:_backgroundTimeout
                                                     andTracker:self];
    }
}

- (void) setDeepLinkContext:(BOOL)deepLinkContext {
    @synchronized (self) {
        _deepLinkContext = deepLinkContext;
        if (deepLinkContext) {
            [self.stateManager addOrReplaceStateMachine:[SPDeepLinkStateMachine new] identifier:@"SPDeepLinkContext"];
        } else {
            [self.stateManager removeStateMachine:@"SPDeepLinkContext"];
        }
    }
}

- (void) setScreenContext:(BOOL)screenContext {
    @synchronized (self) {
        _screenContext = screenContext;
        if (screenContext) {
            [self.stateManager addOrReplaceStateMachine:[SPScreenStateMachine new] identifier:@"SPScreenContext"];
        } else {
            [self.stateManager removeStateMachine:@"SPScreenContext"];
        }
    }
}

- (void) setApplicationContext:(BOOL)applicationContext {
    _applicationContext = applicationContext;
}

- (void) setAutotrackScreenViews:(BOOL)autotrackScreenViews {
    _autotrackScreenViews = autotrackScreenViews;
}

- (void) setForegroundTimeout:(NSInteger)foregroundTimeout {
    _foregroundTimeout = foregroundTimeout;
    if (_builderFinished && _session != nil) {
        [_session setForegroundTimeout:foregroundTimeout];
    }
}

- (void) setBackgroundTimeout:(NSInteger)backgroundTimeout {
    _backgroundTimeout = backgroundTimeout;
    if (_builderFinished && _session != nil) {
        [_session setBackgroundTimeout:backgroundTimeout];
    }
}

- (void) setLifecycleEvents:(BOOL)lifecycleEvents {
    @synchronized (self) {
        _lifecycleEvents = lifecycleEvents;
        if (lifecycleEvents) {
            [self.stateManager addOrReplaceStateMachine:[SPLifecycleStateMachine new] identifier:@"SPLifecycle"];
        } else {
            [self.stateManager removeStateMachine:@"SPLifecycle"];
        }
    }
}

- (void) setExceptionEvents:(BOOL)exceptionEvents {
    _exceptionEvents = exceptionEvents;
}

- (void) setInstallEvent:(BOOL)installEvent {
    _installEvent = installEvent;
}

- (void)setTrackerDiagnostic:(BOOL)trackerDiagnostic {
    _trackerDiagnostic = trackerDiagnostic;
}

- (void)setUserAnonymisation:(BOOL)userAnonymisation {
    if (_userAnonymisation != userAnonymisation) {
        _userAnonymisation = userAnonymisation;
        if (_session != nil) {
            [_session startNewSession];
        }
    }
}

#pragma mark - Global Contexts methods

- (void)setGlobalContextGenerators:(NSDictionary<NSString *, SPGlobalContext *> *)globalContexts {
    _globalContextGenerators = globalContexts.mutableCopy ?: [NSMutableDictionary dictionary];
}

- (BOOL)addGlobalContext:(SPGlobalContext *)generator tag:(NSString *)tag {
    if ((self.globalContextGenerators)[tag]) {
        return NO;
    }
    (self.globalContextGenerators)[tag] = generator;
    return YES;
}

- (SPGlobalContext *)removeGlobalContext:(NSString *)tag {
    SPGlobalContext *toDelete = (self.globalContextGenerators)[tag];
    if (toDelete) {
        [self.globalContextGenerators removeObjectForKey:tag];
    }
    return toDelete;
}

#pragma mark - GDPR methods

- (void)setGdprContextWithBasis:(int)basisForProcessing
                     documentId:(NSString *)documentId
                documentVersion:(NSString *)documentVersion
            documentDescription:(NSString *)documentDescription
{
    self.gdpr = [[SPGdprContext alloc] initWithBasis:(SPGdprProcessingBasis)basisForProcessing
                                          documentId:documentId
                                     documentVersion:documentVersion
                                 documentDescription:documentDescription];
}

- (void)enableGdprContextWithBasis:(int)basisForProcessing
                        documentId:(NSString *)documentId
                   documentVersion:(NSString *)documentVersion
               documentDescription:(NSString *)documentDescription
{
    self.gdpr = [[SPGdprContext alloc] initWithBasis:(SPGdprProcessingBasis)basisForProcessing
                                          documentId:documentId
                                     documentVersion:documentVersion
                                 documentDescription:documentDescription];
}

- (void)disableGdprContext {
    self.gdpr = nil;
}

- (SPGdprContext *)gdprContext {
    return self.gdpr;
}

#pragma mark - Extra Functions

- (void) pauseEventTracking {
    _dataCollection = NO;
    [_emitter pauseTimer];
    [_session stopChecker];
}

- (void) resumeEventTracking {
    _dataCollection = YES;
    [_emitter resumeTimer];
    [_session startChecker];
}

#pragma mark - Getters

- (BOOL) getInBackground {
    return [_session getInBackground];
}

- (BOOL) getIsTracking {
    return _dataCollection;
}

- (BOOL) getLifecycleEvents {
    return _lifecycleEvents;
}

- (NSInteger) getDevicePlatformRawValue {
    return (NSInteger)_devicePlatform;
}

- (NSArray<NSString *> *)globalContextTags {
    return self.globalContextGenerators.allKeys;
}

#pragma mark - Notifications management

- (void) receiveScreenViewNotification:(NSNotification *)notification {
    NSString *name = notification.userInfo[@"name"];
    NSString *type = [SPScreenView stringWithScreenType:[notification.userInfo[@"type"] integerValue]];
    NSString *topViewControllerClassName = notification.userInfo[@"topViewControllerClassName"];
    NSString *viewControllerClassName = notification.userInfo[@"viewControllerClassName"];

    if (_autotrackScreenViews) {
        SPScreenView *event = [[SPScreenView alloc] initWithName:name screenId:nil];
        event.type = type;
        event.viewControllerClassName = viewControllerClassName;
        event.topViewControllerClassName = topViewControllerClassName;
        [self track:event];
    }
}

- (void)receiveDiagnosticNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *tag = userInfo[@"tag"];
    NSString *message = userInfo[@"message"];
    NSError *error = userInfo[@"error"];
    NSException *exception = userInfo[@"exception"];

    if (_trackerDiagnostic) {
        SPTrackerError *event = [[SPTrackerError alloc] initWithSource:tag message:message error:error exception:exception];
        [self track:event];
    }
}

- (void)receiveCrashReportingNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *message = userInfo[@"message"];
    NSString *stacktrace = userInfo[@"stacktrace"];


    if (_exceptionEvents) {
        SNOWError *event = [[SNOWError alloc] initWithMessage:message];
        event.stackTrace = stacktrace;
        [self track:event];
    }
}

#pragma mark - Event Tracking Functions

- (NSUUID *)track:(SPEvent *)event {
    if (!event || !_dataCollection) return nil;
    [event beginProcessingWithTracker:self];
    NSUUID *eventId = [self processEvent:event];
    [event endProcessingWithTracker:self];
    return eventId;
}

#pragma mark - Event Decoration

- (NSUUID *)processEvent:(SPEvent *)event {
    SPTrackerState *stateSnapshot;
    @synchronized (self) {
        stateSnapshot = [self.stateManager trackerStateForProcessedEvent:event];
    }
    SPTrackerEvent *trackerEvent = [[SPTrackerEvent alloc] initWithEvent:event state:stateSnapshot];
    [self transformEvent:trackerEvent];
    SPPayload *payload = [self payloadWithEvent:trackerEvent];
    [_emitter addPayloadToBuffer:payload];
    return trackerEvent.eventId;
}

- (void)transformEvent:(SPTrackerEvent *)event {
    // Application_install event needs the timestamp to the real installation event.
    if ([event.schema isEqualToString:kSPApplicationInstallSchema] && event.trueTimestamp) {
        event.timestamp = event.trueTimestamp.timeIntervalSince1970 * 1000;
        event.trueTimestamp = nil;
    }
    // Payload can be optionally updated with values based on internal state
    [self.stateManager addPayloadValuesToEvent:event];
}

- (SPPayload *)payloadWithEvent:(SPTrackerEvent *)event {
    SPPayload *payload = [SPPayload new];
    payload.allowDiagnostic = !event.isService;

    [self addBasicPropertiesToPayload:payload event:event];
    if (event.isPrimitive) {
        [self addPrimitivePropertiesToPayload:payload event:event];
    } else {
        [self addSelfDescribingPropertiesToPayload:payload event:event];
    }
    NSMutableArray<SPSelfDescribingJson *> *contexts = event.contexts;
    [self addBasicContextsToContexts:contexts event:event];
    [self addGlobalContextsToContexts:contexts event:event];
    [self addStateMachineEntitiesToContexts:contexts event:event];
    [self wrapContexts:contexts toPayload:payload];
    if (!event.isPrimitive) {
        // TODO: To remove when Atomic table refactoring is finished
        [self workaroundForCampaignAttributionEnrichment:payload event:event contexts:contexts];
    }
    return payload;
}

- (void)addBasicPropertiesToPayload:(SPPayload *)payload event:(SPTrackerEvent *)event {
    [payload addValueToPayload:event.eventId.UUIDString forKey:kSPEid];
    [payload addValueToPayload:[NSString stringWithFormat:@"%lld", event.timestamp] forKey:kSPTimestamp];
    if (event.trueTimestamp) {
        long long ttInMilliSeconds = event.trueTimestamp.timeIntervalSince1970 * 1000;
        [payload addValueToPayload:[NSString stringWithFormat:@"%lld", ttInMilliSeconds] forKey:kSPTrueTimestamp];
    }
    [payload addDictionaryToPayload:_trackerData];
    if (_subject != nil) {
        [payload addDictionaryToPayload:[[_subject getStandardDictWithUserAnonymisation:self.userAnonymisation] getAsDictionary]];
    }
    [payload addValueToPayload:SPDevicePlatformToString(_devicePlatform) forKey:kSPPlatform];
}

- (void)addPrimitivePropertiesToPayload:(SPPayload *)payload event:(SPTrackerEvent *)event {
    [payload addValueToPayload:event.eventName forKey:kSPEvent];
    [payload addDictionaryToPayload:event.payload];
}

- (void)addSelfDescribingPropertiesToPayload:(SPPayload *)payload event:(SPTrackerEvent *)event {
    [payload addValueToPayload:kSPEventUnstructured forKey:kSPEvent];

    SPSelfDescribingJson *data = [[SPSelfDescribingJson alloc] initWithSchema:event.schema andData:event.payload];
    NSDictionary *unstructuredEventPayload = @{
        kSPSchema: kSPUnstructSchema,
        kSPData: [data getAsDictionary],
    };
    [payload addDictionaryToPayload:unstructuredEventPayload
                      base64Encoded:_base64Encoded
                    typeWhenEncoded:kSPUnstructuredEncoded
                 typeWhenNotEncoded:kSPUnstructured];
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
- (void)workaroundForCampaignAttributionEnrichment:(SPPayload *)payload event:(SPTrackerEvent *)event contexts:(NSMutableArray<SPSelfDescribingJson *> *)contexts {
    NSString *url = nil;
    NSString *referrer = nil;
    
    if ([event.schema isEqualToString:[SPDeepLinkReceived schema]]) {
        url = (NSString *)[event.payload objectForKey:[SPDeepLinkReceived paramUrl]];
        referrer = (NSString *)[event.payload objectForKey:[SPDeepLinkReceived paramReferrer]];
    } else if ([event.schema isEqualToString:kSPScreenViewSchema]) {
        for (SPSelfDescribingJson *entity in contexts) {
            if ([[entity schema] isEqualToString:[SPDeepLinkEntity schema]]) {
                NSDictionary *data = (NSDictionary *)[entity data];
                url = (NSString *)[data valueForKey:[SPDeepLinkEntity paramUrl]];
                referrer = (NSString *)[data valueForKey:[SPDeepLinkEntity paramReferrer]];
                break;
            }
        }
    }
    
    if (url != nil) {
        [payload addValueToPayload:url forKey:kSPPageUrl];
    }
    if (referrer != nil) {
        [payload addValueToPayload:referrer forKey:kSPPageRefr];
    }
}

- (void)addBasicContextsToContexts:(NSMutableArray<SPSelfDescribingJson *> *)contexts event:(SPTrackerEvent *)event {
    [self addBasicContextsToContexts:contexts eventId:event.eventId.UUIDString eventTimestamp:event.timestamp isService:event.isService];
}

- (void)addBasicContextsToContexts:(NSMutableArray<SPSelfDescribingJson *> *)contexts eventId:(NSString *)eventId eventTimestamp:(long long)eventTimestamp isService:(BOOL)isService {
    if (_subject) {
        NSDictionary * platformDict = [[_subject getPlatformDictWithUserAnonymisation:self.userAnonymisation] getAsDictionary];
        if (platformDict != nil) {
            [contexts addObject:[[SPSelfDescribingJson alloc] initWithSchema:_platformContextSchema andData:platformDict]];
        }
        NSDictionary * geoLocationDict = [_subject getGeoLocationDict];
        if (geoLocationDict != nil) {
            [contexts addObject:[[SPSelfDescribingJson alloc] initWithSchema:kSPGeoContextSchema andData:geoLocationDict]];
        }
    }

    if (_applicationContext) {
        SPSelfDescribingJson * contextJson = [SPUtilities getApplicationContext];
        if (contextJson != nil) {
            [contexts addObject:contextJson];
        }
    }

    if (isService) {
        return;
    }

    // Add session
    if (_session) {
        NSDictionary *sessionDict = [_session getSessionDictWithEventId:eventId eventTimestamp:eventTimestamp userAnonymisation:self.userAnonymisation];
        if (sessionDict) {
            [contexts addObject:[[SPSelfDescribingJson alloc] initWithSchema:kSPSessionContextSchema andData:sessionDict]];
        } else {
            SPLogTrack(nil, @"Unable to get session context for eventId: %@", eventId);
        }
    }

    // Add GDPR context
    if (self.gdpr) {
        SPSelfDescribingJson *gdprContext = self.gdpr.context;
        if (gdprContext) {
            [contexts addObject:gdprContext];
        }
    }
}

- (void)addGlobalContextsToContexts:(NSMutableArray<SPSelfDescribingJson *> *)contexts event:(SPInspectableEvent *)event {
    [self.globalContextGenerators enumerateKeysAndObjectsUsingBlock:^(NSString *key, SPGlobalContext *generator, BOOL *stop) {
        [contexts addObjectsFromArray:[generator contextsFromEvent:event]];
    }];
}

- (void)addStateMachineEntitiesToContexts:(NSMutableArray<SPSelfDescribingJson *> *)contexts event:(SPInspectableEvent *)event {
    NSArray<SPSelfDescribingJson *> *stateManagerEntities = [self.stateManager entitiesForProcessedEvent:event];
    [contexts addObjectsFromArray:stateManagerEntities];
}

- (void)wrapContexts:(NSArray<SPSelfDescribingJson *> *)contexts toPayload:(SPPayload *)payload {
    if (contexts.count == 0) {
        return;
    }
    NSMutableArray<NSDictionary *> *data = [NSMutableArray new];
    for (SPSelfDescribingJson *context in contexts) {
        [data addObject:[context getAsDictionary]];
    }

    SPSelfDescribingJson *finalContext = [[SPSelfDescribingJson alloc] initWithSchema:kSPContextSchema andData:data];
    if (finalContext == nil) {
        return;
    }
    [payload addDictionaryToPayload:[finalContext getAsDictionary]
                      base64Encoded:_base64Encoded
                    typeWhenEncoded:kSPContextEncoded
                 typeWhenNotEncoded:kSPContext];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
