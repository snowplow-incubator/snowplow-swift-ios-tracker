//
//  StateFuture.swift
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

/// StateFuture represents the placeholder of a future computation.
/// The proper state value is computed when it's observed. Until that moment the StateFuture keeps the elements
/// (event, previous StateFuture, StateMachine) needed to calculate the real state value.
/// For this reason, the StateFuture can be the head of StateFuture chain which will collapse once the StateFuture
/// head is asked to get the real state value.
class StateFuture: NSObject {
    var state: State? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if computedState == nil {
            if let stateMachine, let event {
                computedState = stateMachine.transition(from: event, state: previousState?.state)
            }
            event = nil
            previousState = nil
            stateMachine = nil
        }
        return computedState
    }
    private var event: Event?
    private var previousState: StateFuture?
    private var stateMachine: StateMachineProtocol?
    private var computedState: State?

    init(event: Event, previousState: StateFuture?, stateMachine: StateMachineProtocol) {
        super.init()
        self.event = event
        self.previousState = previousState
        self.stateMachine = stateMachine
    }
}
