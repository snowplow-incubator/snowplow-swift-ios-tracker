//
//  SPEmitterConfigurationUpdate.m
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

#import "SPEmitterConfigurationUpdate.h"

@implementation SPEmitterConfigurationUpdate

- (id<SPEventStore>)eventStore { return self.sourceConfig.eventStore; }
- (id<SPRequestCallback>)requestCallback { return self.sourceConfig.requestCallback; }

- (SPBufferOption)bufferOption { return (!self.sourceConfig || self.bufferOptionUpdated) ? super.bufferOption : self.sourceConfig.bufferOption; }
- (NSInteger)emitRange { return (!self.sourceConfig || self.emitRangeUpdated) ? super.emitRange : self.sourceConfig.emitRange; }
- (NSInteger)threadPoolSize { return (!self.sourceConfig || self.threadPoolSizeUpdated) ? super.threadPoolSize : self.sourceConfig.threadPoolSize; }
- (NSInteger)byteLimitGet { return (!self.sourceConfig || self.byteLimitGetUpdated) ? super.byteLimitGet : self.sourceConfig.byteLimitGet; }
- (NSInteger)byteLimitPost { return (!self.sourceConfig || self.byteLimitPostUpdated) ? super.byteLimitPost : self.sourceConfig.byteLimitPost; }
- (NSDictionary *)customRetryForStatusCodes { return (!self.sourceConfig || self.customRetryForStatusCodesUpdated) ? super.customRetryForStatusCodes : self.sourceConfig.customRetryForStatusCodes; }
- (BOOL)serverAnonymisation { return (!self.sourceConfig || self.serverAnonymisationUpdated) ? super.serverAnonymisation : self.sourceConfig.serverAnonymisation; }

@end
