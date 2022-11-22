//
//  SPLifecycleStateMachine.swift
//  Snowplow
//
// Copyright (c) 2013-2022 Snowplow Analytics Ltd. All rights reserved.
//
// This program is licensed to you under the Apache License Version 2.0,
// and you may not use this file except in compliance with the Apache License
// Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
// http://www.apache.org/licenses/LICENSE-2.0.
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the Apache License Version 2.0 is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the Apache License Version 2.0 for the specific
// language governing permissions and limitations there under.
//
// License: Apache License Version 2.0
//

import Foundation

class LifecycleStateMachine: StateMachineProtocol {
    override var subscribedEventSchemasForTransitions: [String] {
        return [kSPBackgroundSchema, kSPForegroundSchema]
    }

    override func transition(from event: Event, state currentState: State?) -> State? {
        if let e = event as? Foreground {
            return LifecycleState(asForegroundWithIndex: NSNumber(value: e.index))
        }
        if let e = event as? Background {
            return LifecycleState(asBackgroundWithIndex: NSNumber(value: e.index))
        }
        return nil
    }

    override var subscribedEventSchemasForEntitiesGeneration: [String] {
        return ["*"]
    }

    override func entities(from event: InspectableEvent, state: State?) -> [SelfDescribingJson]? {
        if state == nil {
            return [LifecycleEntity(isVisible: true).index(0)]
        }
        if let s = state as? LifecycleState {
            return [
                LifecycleEntity(isVisible: s.isForeground).index(s.index)
            ]
        }
        return nil
    }

    override var subscribedEventSchemasForPayloadUpdating: [String] {
        return []
    }

    override func payloadValues(from event: InspectableEvent, state: State?) -> [String : NSObject]? {
        return nil
    }
}
