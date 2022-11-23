//
//  TestLifecycleState.swift
//  Snowplow-iOSTests
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
//  Authors: Michael Hadam
//  License: Apache License Version 2.0
//

import XCTest
@testable import SnowplowTracker

class TestLifecycleState: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testLifecycleStateMachine() {
        let eventStore = MockEventStore()
        let emitter = Emitter(urlEndpoint: "http://snowplow-fake-url.com")
        emitter.eventStore = eventStore
        emitter.setup()
        let tracker = Tracker(trackerNamespace: "namespace", appId: nil, trackerVersionSuffix: nil, emitter: emitter)
        tracker.base64Encoded = false
        tracker.lifecycleEvents = true
        tracker.setup()
        tracker.checkInstall()

        // Send events
        _ = tracker.track(Timing(category: "category", variable: "variable", timing: 123))
        Thread.sleep(forTimeInterval: 1)
        if eventStore.lastInsertedRow == -1 {
            XCTFail()
        }
        var payload = eventStore.db[Int64(eventStore.lastInsertedRow)]
        _ = eventStore.removeAllEvents()
        var entities = (payload?.getAsDictionary()?["co"]) as? String
        XCTAssertNotNil(entities)
        XCTAssertTrue(entities!.contains("\"isVisible\":true"))

        _ = tracker.track(Background(index: 1))
        Thread.sleep(forTimeInterval: 1)
        if eventStore.lastInsertedRow == -1 {
            XCTFail()
        }
        payload = eventStore.db[Int64(eventStore.lastInsertedRow)]
        _ = eventStore.removeAllEvents()
        entities = (payload?.getAsDictionary()?["co"]) as? String
        XCTAssertNotNil(entities)
        XCTAssertTrue(entities!.contains("\"isVisible\":false"))

        _ = tracker.track(Timing(category: "category", variable: "variable", timing: 123))
        Thread.sleep(forTimeInterval: 1)
        if eventStore.lastInsertedRow == -1 {
            XCTFail()
        }
        payload = eventStore.db[Int64(eventStore.lastInsertedRow)]
        _ = eventStore.removeAllEvents()
        entities = (payload?.getAsDictionary()?["co"]) as? String
        XCTAssertTrue(entities!.contains("\"isVisible\":false"))

        _ = tracker.track(Foreground(index: 1))
        Thread.sleep(forTimeInterval: 1)
        if eventStore.lastInsertedRow == -1 {
            XCTFail()
        }
        payload = eventStore.db[Int64(eventStore.lastInsertedRow)]
        _ = eventStore.removeAllEvents()
        entities = (payload?.getAsDictionary()?["co"]) as? String
        XCTAssertNotNil(entities)
        XCTAssertTrue(entities!.contains("\"isVisible\":true"))

        let uuid = UUID()
        _ = tracker.track(ScreenView(name: "screen1", screenId: uuid))
        Thread.sleep(forTimeInterval: 1)
        if eventStore.lastInsertedRow == -1 {
            XCTFail()
        }
        payload = eventStore.db[Int64(eventStore.lastInsertedRow)]
        _ = eventStore.removeAllEvents()
        entities = (payload?.getAsDictionary()?["co"]) as? String
        XCTAssertNotNil(entities)
        XCTAssertTrue(entities!.contains("\"isVisible\":true"))
    }
}
