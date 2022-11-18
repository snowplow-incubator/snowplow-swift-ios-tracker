//
//  SPTrackerEvent.h
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

@objc(SPTrackerEvent)
public class TrackerEvent : InspectableEvent {
    
    private var _payload: [String: NSObject]
    @objc override public var payload: [String: NSObject] {
        get { return _payload }
        set { _payload = newValue }
    }
    private var _schema: String?
    @objc override public var schema: String? {
        get { return _schema }
        set { _schema = newValue }
    }
    private var _eventName: String?
    @objc override public var eventName: String? {
        get { return _eventName }
        set { _eventName = newValue }
    }
    @objc public var eventId: UUID
    @objc public var timestamp: Int64
    @objc public var trueTimestamp: Date?
    @objc public var contexts: [SelfDescribingJson]
    private var _state: TrackerStateSnapshot
    @objc public override var state: TrackerStateSnapshot {
        get { return _state }
        set { _state = newValue }
    }

    @objc public var isPrimitive: Bool
    @objc public var isService: Bool
    
    @objc public init(event: Event, state: TrackerStateSnapshot?) {
        eventId = UUID()
        timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        trueTimestamp = event.trueTimestamp
        contexts = event.contexts
        _payload = event.payload
        _state = state ?? TrackerState()

        isService = (event is TrackerError)
        if let abstractEvent = event as? PrimitiveAbstract {
            _eventName = abstractEvent.eventName
            isPrimitive = true
        } else {
            _schema = (event as! SelfDescribingAbstract).schema
            isPrimitive = false
        }
    }

    override public func addPayloadValues(_ payload: [String : NSObject]) -> Bool {
        var result = true
        for (key, obj) in payload {
            if self.payload[key] == nil {
                self.payload[key] = obj
            } else {
                result = false
            }
        }
        return result
    }
}
