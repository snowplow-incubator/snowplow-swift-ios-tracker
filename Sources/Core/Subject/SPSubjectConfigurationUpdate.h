//
//  SPSubjectConfigurationUpdate.h
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

#import "SPSubjectConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPSubjectConfigurationUpdate : SPSubjectConfiguration

@property (nonatomic, nullable) SPSubjectConfiguration *sourceConfig;

@property BOOL userIdUpdated;
@property BOOL networkUserIdUpdated;
@property BOOL domainUserIdUpdated;
@property BOOL useragentUpdated;
@property BOOL ipAddressUpdated;
@property BOOL timezoneUpdated;
@property BOOL languageUpdated;
@property BOOL screenResolutionUpdated;
@property BOOL screenViewPortUpdated;
@property BOOL colorDepthUpdated;

@end

NS_ASSUME_NONNULL_END
