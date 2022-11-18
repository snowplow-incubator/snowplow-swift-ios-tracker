//
//  TestEvent.m
//  Snowplow
//

#import <XCTest/XCTest.h>
#import "SPMockEventStore.h"
#import <SnowplowTracker/SnowplowTracker-Swift.h>

@interface TestEvent : XCTestCase

@end

@implementation TestEvent

- (void)testTrueTimestamp {
    SPPageView *event = [[SPPageView alloc] initWithPageUrl:@"DemoPageUrl"];
    XCTAssertNil(event.trueTimestamp);

    // Set trueTimestamp
    NSDate *testDate = [NSDate date];
    event.trueTimestamp = testDate;
    XCTAssertEqual(event.trueTimestamp, testDate);
}

- (void)testApplicationInstall {
    // Prepare ApplicationInstall event
    SPSelfDescribingJson *installEvent = [[SPSelfDescribingJson alloc] initWithSchema:kSPApplicationInstallSchema andData:@{}];
    SPSelfDescribing *event = [[SPSelfDescribing alloc] initWithEventData:installEvent];
    NSDate *currentTimestamp = [NSDate dateWithTimeIntervalSince1970:12345L];
    event.trueTimestamp = currentTimestamp;
    
    // Setup tracker
    SPTrackerConfiguration *trackerConfiguration = [SPTrackerConfiguration new];
    trackerConfiguration.base64Encoding = NO;
    trackerConfiguration.installAutotracking = NO;
    SPMockEventStore *eventStore = [SPMockEventStore new];
    SPNetworkConfiguration *networkConfiguration = [[SPNetworkConfiguration alloc] initWithEndpoint:@"fake-url" method:SPHttpMethodPost];
    SPEmitterConfiguration *emitterConfiguration = [[SPEmitterConfiguration alloc] init];
    emitterConfiguration.eventStore = eventStore;
    emitterConfiguration.threadPoolSize = 10;
    id<SPTrackerController> trackerController = [SPSnowplow createTrackerWithNamespace:@"namespace" network:networkConfiguration configurations:@[trackerConfiguration, emitterConfiguration]];

    // Track event
    [trackerController track:event];
    for (int i=0; eventStore.count < 1 && i < 10; i++) {
        [NSThread sleepForTimeInterval:1];
    }
    NSArray<SPEmitterEvent *> *events = [eventStore emittableEventsWithQueryLimit:10];
    [eventStore removeAllEvents];
    XCTAssertEqual(1, events.count);
    SPPayload *payload = events.firstObject.payload;
    
    // Check v_tracker field
    NSString *deviceTimestamp = (NSString *)[payload getAsDictionary][@"dtm"];
    NSString *expected = [NSString stringWithFormat:@"%lld", (long long)(currentTimestamp.timeIntervalSince1970 * 1000)];
    XCTAssertEqualObjects(expected, deviceTimestamp);
}

- (void)testWorkaroundForCampaignAttributionEnrichment {
    // Prepare DeepLinkReceived event
    SPDeepLinkReceived *event = [[SPDeepLinkReceived alloc] initWithUrl:@"url"];
    event.referrer = @"referrer";
    
    // Setup tracker
    SPTrackerConfiguration *trackerConfiguration = [SPTrackerConfiguration new];
    trackerConfiguration.base64Encoding = NO;
    trackerConfiguration.installAutotracking = NO;
    SPMockEventStore *eventStore = [SPMockEventStore new];
    SPNetworkConfiguration *networkConfiguration = [[SPNetworkConfiguration alloc] initWithEndpoint:@"fake-url" method:SPHttpMethodPost];
    SPEmitterConfiguration *emitterConfiguration = [[SPEmitterConfiguration alloc] init];
    emitterConfiguration.eventStore = eventStore;
    emitterConfiguration.threadPoolSize = 10;
    id<SPTrackerController> trackerController = [SPSnowplow createTrackerWithNamespace:@"namespace" network:networkConfiguration configurations:@[trackerConfiguration, emitterConfiguration]];

    // Track event
    [trackerController track:event];
    for (int i=0; eventStore.count < 1 && i < 10; i++) {
        [NSThread sleepForTimeInterval:1];
    }
    NSArray<SPEmitterEvent *> *events = [eventStore emittableEventsWithQueryLimit:10];
    [eventStore removeAllEvents];
    XCTAssertEqual(1, events.count);
    SPPayload *payload = events.firstObject.payload;
    
    // Check url and referrer fields
    NSString *url = (NSString *)[payload getAsDictionary][kSPPageUrl];
    NSString *referrer = (NSString *)[payload getAsDictionary][kSPPageRefr];
    XCTAssertEqualObjects(url, @"url");
    XCTAssertEqualObjects(referrer, @"referrer");
}

- (void)testDeepLinkContextAndAtomicPropertiesAddedToScreenView {
    // Prepare DeepLinkReceived event
    SPDeepLinkReceived *deepLink = [[SPDeepLinkReceived alloc] initWithUrl:@"the_url"];
    deepLink.referrer = @"the_referrer";
    
    // Prepare ScreenView event
    SPScreenView *screenView = [[SPScreenView alloc] initWithName:@"SV" screenId:[NSUUID UUID]];
    
    // Setup tracker
    SPTrackerConfiguration *trackerConfiguration = [SPTrackerConfiguration new];
    trackerConfiguration.base64Encoding = NO;
    trackerConfiguration.installAutotracking = NO;
    SPMockEventStore *eventStore = [SPMockEventStore new];
    SPNetworkConfiguration *networkConfiguration = [[SPNetworkConfiguration alloc] initWithEndpoint:@"fake-url" method:SPHttpMethodPost];
    SPEmitterConfiguration *emitterConfiguration = [[SPEmitterConfiguration alloc] init];
    emitterConfiguration.eventStore = eventStore;
    emitterConfiguration.threadPoolSize = 10;
    id<SPTrackerController> trackerController = [SPSnowplow createTrackerWithNamespace:@"namespace" network:networkConfiguration configurations:@[trackerConfiguration, emitterConfiguration]];

    // Track event
    [trackerController track:deepLink];
    NSUUID *screenViewId = [trackerController track:screenView];
    for (int i=0; eventStore.count < 2 && i < 10; i++) {
        [NSThread sleepForTimeInterval:1];
    }
    NSArray<SPEmitterEvent *> *events = [eventStore emittableEventsWithQueryLimit:10];
    [eventStore removeAllEvents];
    XCTAssertEqual(2, events.count);
    
    SPPayload *screenViewPayload = nil;
    for (SPEmitterEvent *event in events) {
        if ([(NSString *)[[[event payload] getAsDictionary] objectForKey:@"eid"] isEqualToString:[screenViewId UUIDString]]) {
            screenViewPayload = [event payload];
        }
    }
    XCTAssertNotNil(screenViewPayload);
    
    // Check the DeepLink context entity properties
    NSString *screenViewContext = (NSString *)[[screenViewPayload getAsDictionary] objectForKey:@"co"];
    XCTAssertTrue([screenViewContext containsString:@"\"referrer\":\"the_referrer\""]);
    XCTAssertTrue([screenViewContext containsString:@"\"url\":\"the_url\""]);
    
    // Check url and referrer fields for atomic table
    NSString *url = (NSString *)[[screenViewPayload getAsDictionary] objectForKey:kSPPageUrl];
    NSString *referrer = (NSString *)[[screenViewPayload getAsDictionary] objectForKey:kSPPageRefr];
    XCTAssertEqualObjects(url, @"the_url");
    XCTAssertEqualObjects(referrer, @"the_referrer");
}

- (void)testPageView {
    // Valid construction
    SPPageView *event = [[SPPageView alloc] initWithPageUrl:@"DemoPageUrl"];
    XCTAssertNotNil(event);
    event = nil;
    
    // PageURL is empty
    @try {
        event = [[SPPageView alloc] initWithPageUrl:@""];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"PageURL cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
}

- (void)testStructured {
    // Valid construction
    SPStructured *event = [[SPStructured alloc] initWithCategory:@"category" action:@"action"];
    XCTAssertNotNil(event);
    event = nil;
    
    // Category is empty
    @try {
        event = [[SPStructured alloc] initWithCategory:@"" action:@"action"];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Category cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
        
    // Action is empty
    @try {
        event = [[SPStructured alloc] initWithCategory:@"category" action:@""];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Action cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
}

- (void)testUnstructured {
    // Valid construction
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    data[@"level"] = @23;
    data[@"score"] = @56473;
    SPSelfDescribingJson *sdj = [[SPSelfDescribingJson alloc] initWithSchema:@"iglu:com.acme_company/demo_ios_event/jsonschema/1-0-0"
                                                                      andData:data];
    SPSelfDescribing *event = [[SPSelfDescribing alloc] initWithEventData:sdj];
    XCTAssertNotNil(event);
}

- (void)testConsentWithdrawn {
    // Valid construction
    SPConsentWithdrawn *event = [[SPConsentWithdrawn alloc] init];
    event.name = @"name";
    event.all = NO;
    event.version = @"3";
    event.documentId = @"1000";
    event.documentDescription = @"description";
    XCTAssertNotNil(event);
}

- (void)testConsentGranted {
    // Valid construction
    SPConsentGranted *event = [[SPConsentGranted alloc] initWithExpiry:@"expiry" documentId:@"1000" version:@"3"];
    event.name = @"name";
    event.documentDescription = @"description";
    XCTAssertNotNil(event);
}

- (void)testConsentDocument {
    // Valid construction
    SPConsentGranted *event = [[SPConsentGranted alloc] initWithExpiry:@"expiry" documentId:@"1000" version:@"3"];
    event.name = @"name";
    event.documentDescription = @"description";
    XCTAssertNotNil(event);
}

- (void)testScreenView {
    NSUUID *screenId = [NSUUID UUID];
    
    // Valid construction
    SPScreenView *event = [[SPScreenView alloc] initWithName:@"name" screenId:screenId];
    XCTAssertNotNil(event);
    event = nil;

    @try {
        event = [[SPScreenView alloc] initWithName:@"" screenId:screenId];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Name cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
}

- (void)testTiming {
    // Valid construction
    SPTiming *event = [[SPTiming alloc] initWithCategory:@"cat" variable:@"var" timing:5];
    XCTAssertNotNil(event);
    event = nil;
    
    // Category is empty
    @try {
        event = [[SPTiming alloc] initWithCategory:@"" variable:@"var" timing:5];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Category cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
    
    // Variable is empty
    @try {
        event = [[SPTiming alloc] initWithCategory:@"cat" variable:@"" timing:5];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Variable cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
}

- (void)testEcommerce {
    // Valid construction
    SPEcommerce *event = [[SPEcommerce alloc] initWithOrderId:@"id" totalValue:5 items:@[]];
    XCTAssertNotNil(event);
    event = nil;
    
    // OrderID is empty
    @try {
        event = [[SPEcommerce alloc] initWithOrderId:@"" totalValue:5 items:@[]];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"OrderId cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
}

- (void)testEcommerceItem {
    // Valid construction
    SPEcommerceItem *event = [[SPEcommerceItem alloc] initWithSku:@"sku" price:5.3 quantity:5];
    XCTAssertNotNil(event);
    event = nil;
    
    // Sku is empty
    @try {
        event = [[SPEcommerceItem alloc] initWithSku:@"" price:5.3 quantity:5];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"SKU cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
}

- (void)testPushNotificationContent {
    // Valid construction
    NSArray *attachments = @[ @{ @"identifier": @"id",
                                 @"url": @"www.test.com",
                                 @"type": @"test"
    },
                              @{ @"identifier": @"id2",
                                 @"url": @"www.test2.com",
                                 @"type": @"test2"
                              }
    ];
    
    NSDictionary *userInfo = @{ @"aps" : @{ @"alert": @"test",
                                            @"sound": @"sound",
                                            @"category": @"category"
    }
    };
    
    SPNotificationContent *event = [[SPNotificationContent alloc] initWithTitle:@"title" body:@"body" badge:@5];
    event.subtitle = @"subtitle";
    event.sound = @"sound";
    event.launchImageName = @"image";
    event.userInfo = userInfo;
    event.attachments = attachments;
    XCTAssertNotNil(event);
    event = nil;

    // Title is empty
    @try {
        event = [[SPNotificationContent alloc] initWithTitle:@"" body:@"body" badge:@5];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Title cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);

    // Body is empty
    @try {
        event = [[SPNotificationContent alloc] initWithTitle:@"title" body:@"" badge:@5];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Body cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
}

- (void)testPushNotification {
    // Valid construction
    NSArray *attachments = @[ @{ @"identifier": @"id",
                                 @"url": @"www.test.com",
                                 @"type": @"test"
    },
                              @{ @"identifier": @"id2",
                                 @"url": @"www.test2.com",
                                 @"type": @"test2"
                              }
    ];
    
    NSDictionary *userInfo = @{ @"aps":
                                    @{ @"alert":
                                           @{
                                               @"title": @"test-title",
                                               @"body": @"test-body"
                                           },
                                    }
    };
    
    SPNotificationContent *content = [[SPNotificationContent alloc] initWithTitle:@"title" body:@"body" badge:@5];
    content.subtitle = @"subtitle";
    content.sound = @"sound";
    content.launchImageName = @"image";
    content.userInfo = userInfo;
    content.attachments = attachments;

    SPPushNotification *event = [[SPPushNotification alloc] initWithDate:@"date"
                                                                  action:@"action"
                                                                 trigger:@"PUSH"
                                                                category:@"category"
                                                                  thread:@"thread"
                                                            notification:content];
    XCTAssertNotNil(event);
    event = nil;

    // Action is empty
    @try {
        event = [[SPPushNotification alloc] initWithDate:@"date"
                                                  action:@""
                                                 trigger:@"PUSH"
                                                category:@"category"
                                                  thread:@"thread"
                                            notification:content];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Action cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);

    // Trigger is empty
    @try {
        event = [[SPPushNotification alloc] initWithDate:@"date"
                                                  action:@"action"
                                                 trigger:@""
                                                category:@"category"
                                                  thread:@"thread"
                                            notification:content];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Trigger cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
    
    // Date is nil
    @try {
        event = [[SPPushNotification alloc] initWithDate:@""
                                                  action:@"action"
                                                 trigger:@"PUSH"
                                                category:@"category"
                                                  thread:@"thread"
                                            notification:content];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Delivery date cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
    
    // CategoryId is empty
    @try {
        event = [[SPPushNotification alloc] initWithDate:@"date"
                                                  action:@"action"
                                                 trigger:@"PUSH"
                                                category:@""
                                                  thread:@"thread"
                                            notification:content];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Category identifier cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
    
    // ThreadId is empty
    @try {
        event = [[SPPushNotification alloc] initWithDate:@"date"
                                                  action:@"action"
                                                 trigger:@"PUSH"
                                                category:@"category"
                                                  thread:@""
                                            notification:content];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(@"Thread identifier cannot be empty.", exception.reason);
    }
    XCTAssertNil(event);
}

- (void)testMessageNotification {
    SPMessageNotification *event = [[SPMessageNotification alloc] initWithTitle:@"title" body:@"body" trigger:SPMessageNotificationTriggerPush];
    event.notificationTimestamp = @"2020-12-31T15:59:60-08:00";
    event.action = @"action";
    event.bodyLocKey = @"loc key";
    event.bodyLocArgs = @[@"loc arg1", @"loc arg2"];
    event.sound = @"chime.mp3";
    // TODO: commented out because Obj-C does not support the property
//    event.notificationCount = @9;
    event.category = @"category1";
    event.attachments = @[[[SPMessageNotificationAttachment alloc] initWithIdentifier:@"id" type:@"type" url:@"url"]];

    NSDictionary<NSString *, NSObject *> *payload = event.payload;
    XCTAssertEqualObjects(@"title", payload[@"title"]);
    XCTAssertEqualObjects(@"body", payload[@"body"]);
    XCTAssertEqualObjects(@"2020-12-31T15:59:60-08:00", payload[@"notificationTimestamp"]);
    XCTAssertEqualObjects(@"push", payload[@"trigger"]);
    XCTAssertEqualObjects(@"action", payload[@"action"]);
    XCTAssertEqualObjects(@"loc key", payload[@"bodyLocKey"]);
    NSArray<NSString *> *locArgs = (NSArray<NSString *> *)(payload[@"bodyLocArgs"]);
    XCTAssertNotNil(locArgs);
    XCTAssertEqual(2, locArgs.count);
    XCTAssertEqualObjects(@"loc arg1", locArgs[0]);
    XCTAssertEqualObjects(@"loc arg2", locArgs[1]);
    XCTAssertEqualObjects(@"chime.mp3", payload[@"sound"]);
//    XCTAssertEqualObjects(@9, payload["notificationCount"]);
    XCTAssertEqualObjects(@"category1", payload[@"category"]);
    NSArray<NSDictionary<NSString *, NSObject *> *> *attachments = (NSArray<NSDictionary<NSString *, NSObject *> *> *)(payload[@"attachments"]);
    XCTAssertNotNil(attachments);
    XCTAssertEqual(1, attachments.count);
    NSDictionary<NSString *, NSObject *> *attachment = attachments[0];
    XCTAssertEqualObjects(@"id", attachment[@"identifier"]);
    XCTAssertEqualObjects(@"type", attachment[@"type"]);
    XCTAssertEqualObjects(@"url", attachment[@"url"]);
}

- (void)testMessageNotificationWithUserInfo {
    NSDictionary *userInfo = @{ @"aps":
                                    @{ @"alert":
                                           @{
                                               @"title": @"test-title",
                                               @"body": @"test-body",
                                               @"loc-key": @"loc key",
                                               @"loc-args": @[@"loc arg1", @"loc arg2"]
                                           },
                                       @"sound": @"chime.aiff",
                                       @"badge": @9,
                                       @"category": @"category1",
                                       @"content-available": @1
                                    },
                                @"custom-element": @1
    };
    SPMessageNotification *event = [SPMessageNotification messageNotificationWithUserInfo:userInfo defaultTitle:nil defaultBody:nil];
    XCTAssertNotNil(event);
    NSDictionary<NSString *, NSObject *> *payload = event.payload;
    XCTAssertEqualObjects(@"test-title", payload[@"title"]);
    XCTAssertEqualObjects(@"test-body", payload[@"body"]);
    XCTAssertEqualObjects(@"loc key", payload[@"bodyLocKey"]);
    NSArray *locArgs = (NSArray *)payload[@"bodyLocArgs"];
    XCTAssertEqual(2, locArgs.count);
    XCTAssertEqualObjects(@"loc arg1", locArgs[0]);
    XCTAssertEqualObjects(@"loc arg2", locArgs[1]);
    XCTAssertEqualObjects(@9, payload[@"notificationCount"]);
    XCTAssertEqualObjects(@"chime.aiff", payload[@"sound"]);
    XCTAssertEqualObjects(@"category1", payload[@"category"]);
    XCTAssertEqualObjects(@YES, payload[@"contentAvailable"]);
}

- (void)testError {
    // Valid construction
    SNOWError *error = [[SNOWError alloc] initWithMessage:@"message"];
    error.name = @"name";
    error.stackTrace = @"stacktrace";
    XCTAssertNotNil(error);
}

- (void)testTrackerErrorContainsStacktrace {
    @try {
        @throw([NSException exceptionWithName:@"CustomException" reason:@"reason" userInfo:nil]);
    } @catch (NSException *exception) {
        SPTrackerError *trackerError = [[SPTrackerError alloc] initWithSource:@"classname" message:@"message" error:nil exception:exception];
        NSDictionary<NSString *, NSObject *> *payload = trackerError.payload;
        XCTAssertEqualObjects(payload[@"message"], @"message");
        XCTAssertEqualObjects(payload[@"className"], @"classname");
        XCTAssertEqualObjects(payload[@"exceptionName"], @"CustomException");
        XCTAssertTrue([(NSString *)payload[@"stackTrace"] length]);
    }
}

@end
