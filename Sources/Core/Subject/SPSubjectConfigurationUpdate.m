//
//  SPSubjectConfigurationUpdate.m
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

#import "SPSubjectConfigurationUpdate.h"

@implementation SPSubjectConfigurationUpdate

- (NSString *)userId { return (!self.sourceConfig || self.userIdUpdated) ? super.userId : self.sourceConfig.userId; }
- (NSString *)networkUserId { return (!self.sourceConfig || self.networkUserIdUpdated) ? super.networkUserId : self.sourceConfig.networkUserId; }
- (NSString *)domainUserId { return (!self.sourceConfig || self.domainUserIdUpdated) ? super.domainUserId : self.sourceConfig.domainUserId; }
- (NSString *)useragent { return (!self.sourceConfig || self.useragentUpdated) ? super.useragent : self.sourceConfig.useragent; }
- (NSString *)ipAddress { return (!self.sourceConfig || self.ipAddressUpdated) ? super.ipAddress : self.sourceConfig.ipAddress; }
- (NSString *)timezone { return (!self.sourceConfig || self.timezoneUpdated) ? super.timezone : self.sourceConfig.timezone; }
- (NSString *)language { return (!self.sourceConfig || self.languageUpdated) ? super.language : self.sourceConfig.language; }
- (SPSize *)screenResolution { return (!self.sourceConfig || self.screenResolutionUpdated) ? super.screenResolution : self.sourceConfig.screenResolution; }
- (SPSize *)screenViewPort { return (!self.sourceConfig || self.screenViewPortUpdated) ? super.screenViewPort : self.sourceConfig.screenViewPort; }
- (NSNumber *)colorDepth { return (!self.sourceConfig || self.colorDepthUpdated) ? super.colorDepth : self.sourceConfig.colorDepth; }

@end
