
//
//  TestEvents.swift
//  SnowplowTests
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
//  Authors: Jonathan Almeida
//  License: Apache License Version 2.0
//

import XCTest
@testable import SnowplowTracker

class TestEvents: XCTestCase {
    func testTrueTimestamp() {
        let event = PageView(pageUrl: "DemoPageUrl")
        XCTAssertNil(event.trueTimestamp)

        // Set trueTimestamp
        let testDate = Date()
        event.trueTimestamp = testDate
        XCTAssertEqual(event.trueTimestamp, testDate)
    }

    func testApplicationInstall() {
        // Prepare ApplicationInstall event
        let installEvent = SelfDescribingJson(schema: kSPApplicationInstallSchema, andDictionary: [String:NSObject]())
        let event = SelfDescribing(eventData: installEvent)
        let currentTimestamp = Date(timeIntervalSince1970: 12345)
        event.trueTimestamp = currentTimestamp

        // Setup tracker
        let trackerConfiguration = TrackerConfiguration()
        trackerConfiguration.base64Encoding = false
        trackerConfiguration.installAutotracking = false
        let eventStore = MockEventStore()
        let networkConfiguration = NetworkConfiguration(endpoint: "fake-url", method: .post)
        let emitterConfiguration = EmitterConfiguration()
        emitterConfiguration.eventStore = eventStore
        emitterConfiguration.threadPoolSize = 10
        let trackerController = Snowplow.createTracker(namespace: "namespace", network: networkConfiguration, configurations: [trackerConfiguration, emitterConfiguration])

        // Track event
        _ = trackerController?.track(event)
        for _ in 0..<1 {
            Thread.sleep(forTimeInterval: 1)
        }
        let events = eventStore.emittableEvents(withQueryLimit: 10)
        _ = eventStore.removeAllEvents()
        XCTAssertEqual(1, events.count)
        let payload = events.first?.payload

        // Check v_tracker field
        let deviceTimestamp = payload?.getAsDictionary()?["dtm"] as? String
        let expected = String(format: "%lld", Int64(currentTimestamp.timeIntervalSince1970 * 1000))
        XCTAssertEqual(expected, deviceTimestamp)
    }

    func testWorkaroundForCampaignAttributionEnrichment() {
        // Prepare DeepLinkReceived event
        let event = DeepLinkReceived(url: "url")
        event.referrer = "referrer"

        // Setup tracker
        let trackerConfiguration = TrackerConfiguration()
        trackerConfiguration.base64Encoding = false
        trackerConfiguration.installAutotracking = false
        let eventStore = MockEventStore()
        let networkConfiguration = NetworkConfiguration(endpoint: "fake-url", method: .post)
        let emitterConfiguration = EmitterConfiguration()
        emitterConfiguration.eventStore = eventStore
        emitterConfiguration.threadPoolSize = 10
        let trackerController = Snowplow.createTracker(namespace: "namespace", network: networkConfiguration, configurations: [trackerConfiguration, emitterConfiguration])

        // Track event
        _ = trackerController?.track(event)
        for _ in 0..<1 {
            Thread.sleep(forTimeInterval: 1)
        }
        let events = eventStore.emittableEvents(withQueryLimit: 10)
        _ = eventStore.removeAllEvents()
        XCTAssertEqual(1, events.count)
        let payload = events.first?.payload

        // Check url and referrer fields
        let url = payload?.getAsDictionary()?[kSPPageUrl] as? String
        let referrer = payload?.getAsDictionary()?[kSPPageRefr] as? String
        XCTAssertEqual(url, "url")
        XCTAssertEqual(referrer, "referrer")
    }

    func testDeepLinkContextAndAtomicPropertiesAddedToScreenView() {
        // Prepare DeepLinkReceived event
        let deepLink = DeepLinkReceived(url: "the_url")
        deepLink.referrer = "the_referrer"

        // Prepare ScreenView event
        let screenView = ScreenView(name: "SV", screenId: UUID())

        // Setup tracker
        let trackerConfiguration = TrackerConfiguration()
        trackerConfiguration.base64Encoding = false
        trackerConfiguration.installAutotracking = false
        let eventStore = MockEventStore()
        let networkConfiguration = NetworkConfiguration(endpoint: "fake-url", method: .post)
        let emitterConfiguration = EmitterConfiguration()
        emitterConfiguration.eventStore = eventStore
        emitterConfiguration.threadPoolSize = 10
        let trackerController = Snowplow.createTracker(namespace: "namespace", network: networkConfiguration, configurations: [trackerConfiguration, emitterConfiguration])

        // Track event
        _ = trackerController?.track(deepLink)
        let screenViewId = trackerController?.track(screenView)
        for _ in 0..<2 {
            Thread.sleep(forTimeInterval: 1)
        }
        let events = eventStore.emittableEvents(withQueryLimit: 10)
        _ = eventStore.removeAllEvents()
        XCTAssertEqual(2, events.count)

        var screenViewPayload: Payload? = nil
        for event in events {
            if (event.payload.getAsDictionary()?["eid"] as? String) == screenViewId?.uuidString {
                screenViewPayload = event.payload
            }
        }
        XCTAssertNotNil(screenViewPayload)

        // Check the DeepLink context entity properties
        let screenViewContext = screenViewPayload?.getAsDictionary()?["co"] as? String
        XCTAssertTrue(screenViewContext?.contains("\"referrer\":\"the_referrer\"") ?? false)
        XCTAssertTrue(screenViewContext?.contains("\"url\":\"the_url\"") ?? false)

        // Check url and referrer fields for atomic table
        let url = screenViewPayload?.getAsDictionary()?[kSPPageUrl] as? String
        let referrer = screenViewPayload?.getAsDictionary()?[kSPPageRefr] as? String
        XCTAssertEqual(url, "the_url")
        XCTAssertEqual(referrer, "the_referrer")
    }

    func testPageView() {
        let event = PageView(pageUrl: "DemoPageUrl")
        XCTAssertEqual("DemoPageUrl", event.payload["url"] as? String)
    }

    func testStructured() {
        let event = Structured(category: "category", action: "action")
        XCTAssertEqual("category", event.payload["se_ca"] as? String)
        XCTAssertEqual("action", event.payload["se_ac"] as? String)
    }

    func testUnstructured() {
        var data: [String : NSObject] = [:]
        data["level"] = NSNumber(value: 23)
        data["score"] = NSNumber(value: 56473)
        let sdj = SelfDescribingJson(
            schema: "iglu:com.acme_company/demo_ios_event/jsonschema/1-0-0",
            andDictionary: data)
        let event = SelfDescribing(eventData: sdj)
        XCTAssertEqual("iglu:com.acme_company/demo_ios_event/jsonschema/1-0-0", event.schema)
        XCTAssertEqual(NSNumber(value: 23), event.payload["level"])
    }

    func testConsentWithdrawn() {
        let event = ConsentWithdrawn()
        event.name = "name"
        event.all = false
        event.version = "3"
        event.documentId = "1000"
        event.documentDescription = "description"
        XCTAssertEqual(NSNumber(value: false), event.payload["all"])
        XCTAssertEqual(1, event.allDocuments.count)
    }

    func testConsentGranted() {
        let event = ConsentGranted(expiry: "expiry", documentId: "1000", version: "3")
        event.name = "name"
        event.documentDescription = "description"
        XCTAssertEqual("expiry", event.payload["expiry"] as? String)
    }

    func testScreenView() {
        let screenId = UUID()

        let event = ScreenView(name: "name", screenId: screenId)
        XCTAssertEqual("name", event.payload["name"] as? String)
    }

    func testTiming() {
        let event = Timing(category: "cat", variable: "var", timing: 5)
        XCTAssertEqual("cat", event.payload["category"] as? String)
    }

    func testEcommerce() {
        let event = Ecommerce(orderId: "id", totalValue: 5, items: [])
        XCTAssertEqual("id", event.payload["tr_id"] as? String)
    }

    func testEcommerceItem() {
        let event = EcommerceItem(sku: "sku", price: 5.3, quantity: 5)
        XCTAssertEqual("sku", event.payload["ti_sk"] as? String)
    }

    func testPushNotificationContent() {
        let attachments = [
            [
                "identifier": "id",
                "url": "www.test.com",
                "type": "test"
            ],
            [
                "identifier": "id2",
                "url": "www.test2.com",
                "type": "test2"
            ]
        ]
        
        let userInfo = [
            "aps": [
                "alert": "test",
                "sound": "sound",
                "category": "category"
            ]
        ]
        
        let event = NotificationContent(title: "title", body: "body", badge: NSNumber(value: 5))
        event.subtitle = "subtitle"
        event.sound = "sound"
        event.launchImageName = "image"
        event.userInfo = userInfo as [String : NSObject]
        event.attachments = attachments as [NSObject]
        XCTAssertEqual("sound", event.payload["sound"] as? String)
    }

    func testPushNotification() {
        let attachments = [
            [
                "identifier": "id",
                "url": "www.test.com",
                "type": "test"
            ],
            [
                "identifier": "id2",
                "url": "www.test2.com",
                "type": "test2"
            ]
        ]
        
        let userInfo = [
            "aps": [
                "alert": [
                    "title": "test-title",
                    "body": "test-body"
                ]
            ]
        ]
        
        let content = NotificationContent(title: "title", body: "body", badge: NSNumber(value: 5))
        content.subtitle = "subtitle"
        content.sound = "sound"
        content.launchImageName = "image"
        content.userInfo = userInfo as [String : NSObject]
        content.attachments = attachments as [NSObject]

        let event = PushNotification(
            date: "date",
            action: "action",
            trigger: "PUSH",
            category: "category",
            thread: "thread",
            notification: content)
        XCTAssertEqual("action", event.payload["action"] as? String)
    }

    func testMessageNotification() {
        let event = MessageNotification(title: "title", body: "body", trigger: .push)
        event.notificationTimestamp = "2020-12-31T15:59:60-08:00"
        event.action = "action"
        event.bodyLocKey = "loc key"
        event.bodyLocArgs = ["loc arg1", "loc arg2"]
        event.sound = "chime.mp3"
        // TODO: commented out because Obj-C does not support the property
        //    event.notificationCount = @9;
        event.category = "category1"
        event.attachments = [
            MessageNotificationAttachment(identifier: "id", type: "type", url: "url")
        ]

        let payload = event.payload
        XCTAssertEqual("title", payload["title"] as? String)
        XCTAssertEqual("body", payload["body"] as? String)
        XCTAssertEqual("2020-12-31T15:59:60-08:00", payload["notificationTimestamp"] as? String)
        XCTAssertEqual("push", payload["trigger"] as? String)
        XCTAssertEqual("action", payload["action"] as? String)
        XCTAssertEqual("loc key", payload["bodyLocKey"] as? String)
        let locArgs = (payload["bodyLocArgs"]) as? [String]
        XCTAssertNotNil(locArgs)
        XCTAssertEqual(2, (locArgs?.count ?? 0))
        XCTAssertEqual("loc arg1", locArgs?[0])
        XCTAssertEqual("loc arg2", locArgs?[1])
        XCTAssertEqual("chime.mp3", payload["sound"] as? String)
        //    XCTAssertEqualObjects(@9, payload["notificationCount"]);
        XCTAssertEqual("category1", payload["category"] as? String)
        let attachments = (payload["attachments"]) as? [[String : NSObject]]
        XCTAssertNotNil(attachments)
        XCTAssertEqual(1, (attachments?.count ?? 0))
        let attachment = attachments?[0] as? [String : NSObject]
        XCTAssertEqual("id", attachment?["identifier"] as? String)
        XCTAssertEqual("type", attachment?["type"] as? String)
        XCTAssertEqual("url", attachment?["url"] as? String)
    }

    func testMessageNotificationWithUserInfo() {
        let userInfo: [String : Any] = [
            "aps": [
                "alert": [
                    "title": "test-title",
                    "body": "test-body",
                    "loc-key": "loc key",
                    "loc-args": ["loc arg1", "loc arg2"]
                ],
                "sound": "chime.aiff",
                "badge": NSNumber(value: 9),
                "category": "category1",
                "content-available": NSNumber(value: 1)
            ],
            "custom-element": NSNumber(value: 1)
        ]
        let event = MessageNotification.messageNotification(userInfo: userInfo as! [String : NSObject], defaultTitle: nil, defaultBody: nil)!
        let payload = event.payload
        XCTAssertEqual("test-title", payload["title"] as? String)
        XCTAssertEqual("test-body", payload["body"] as? String)
        XCTAssertEqual("loc key", payload["bodyLocKey"] as? String)
        let locArgs = payload["bodyLocArgs"] as? [AnyHashable]
        XCTAssertEqual(2, (locArgs?.count ?? 0))
        XCTAssertEqual("loc arg1", locArgs?[0] as? String)
        XCTAssertEqual("loc arg2", locArgs?[1] as? String)
        XCTAssertEqual(NSNumber(value: 9), payload["notificationCount"])
        XCTAssertEqual("chime.aiff", payload["sound"] as? String)
        XCTAssertEqual("category1", payload["category"] as? String)
        XCTAssertEqual(NSNumber(value: true), payload["contentAvailable"])
    }

    func testError() {
        // Valid construction
        let error = SNOWError(message: "message")
        error.name = "name"
        error.stackTrace = "stacktrace"
        XCTAssertEqual("name", error.payload["exceptionName"] as? String)
    }

    func testTrackerError() {
        let trackerError = TrackerError(source: "classname", message: "message", error: nil, exception: NSException(name: NSExceptionName("CustomException"), reason: "reason", userInfo: nil))
        let payload = trackerError.payload
        XCTAssertEqual(payload["message"] as? String, "message")
        XCTAssertEqual(payload["className"] as? String, "classname")
        XCTAssertEqual(payload["exceptionName"] as? String, "CustomException")
    }
}
