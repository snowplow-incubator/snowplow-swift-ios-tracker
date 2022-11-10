//
//  SPSessionConfigurationUpdate.m
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

#import "SPSessionConfigurationUpdate.h"

@implementation SPSessionConfigurationUpdate

- (NSInteger)foregroundTimeoutInSeconds { return (!self.sourceConfig || self.foregroundTimeoutInSecondsUpdated) ? super.foregroundTimeoutInSeconds : self.sourceConfig.foregroundTimeoutInSeconds; }
- (NSInteger)backgroundTimeoutInSeconds { return (!self.sourceConfig || self.backgroundTimeoutInSecondsUpdated) ? super.backgroundTimeoutInSeconds : self.sourceConfig.backgroundTimeoutInSeconds; }
- (OnSessionStateUpdate)onSessionStateUpdate { return (!self.sourceConfig || self.onSessionStateUpdateUpdated) ? super.onSessionStateUpdate : self.sourceConfig.onSessionStateUpdate; }

@end
