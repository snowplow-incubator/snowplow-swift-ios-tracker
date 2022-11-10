//
//  SPEmitterConfiguration.h
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

#import <Foundation/Foundation.h>
#import "SPConfiguration.h"
#import "SPEventStore.h"
#import "SPRequestCallback.h"

/*!
 @brief An enum for buffer options.
 */
typedef NS_ENUM(NSUInteger, SPBufferOption) {
    /**
     * Sends both GET and POST requests with only a single event.  Can cause a spike in
     * network traffic if used in correlation with a large amount of events.
     */
    SPBufferOptionSingle = 1,
    /**
     * Sends POST requests in groups of 10 events.  This is the default amount of events too
     * package into a POST.  All GET requests will still emit one at a time.
     */
    SPBufferOptionDefaultGroup = 10,
    /**
     * Sends POST requests in groups of 25 events.  Useful for situations where many events
     * need to be sent.  All GET requests will still emit one at a time.
     */
    SPBufferOptionLargeGroup = 25,
    SPBufferOptionHeavyGroup __deprecated_enum_msg("Use BufferOption.largeGroup instead.") = SPBufferOptionLargeGroup
} NS_SWIFT_NAME(BufferOption);


NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EmitterConfigurationProtocol)
@protocol SPEmitterConfigurationProtocol

/**
 * Sets whether the buffer should send events instantly or after the buffer
 * has reached it's limit. By default, this is set to BufferOption Default.
 */
@property () SPBufferOption bufferOption;
/**
 * Maximum number of events collected from the EventStore to be sent in a request.
 */
@property () NSInteger emitRange;
/**
 * Maximum number of threads working in parallel in the tracker to send requests.
 */
@property () NSInteger threadPoolSize;
/**
 * Maximum amount of bytes allowed to be sent in a payload in a GET request.
 */
@property () NSInteger byteLimitGet;
/**
 * Maximum amount of bytes allowed to be sent in a payload in a POST request.
 */
@property () NSInteger byteLimitPost;
/**
 * Callback called for each request performed by the tracker to the collector.
 */
@property (nullable) id<SPRequestCallback> requestCallback;
/**
 *  Custom retry rules for HTTP status codes returned from the Collector.
 *  The dictionary is a mapping of integers (status codes) to booleans (true for retry and false for not retry).
 */
@property (nonatomic, nullable) NSDictionary<NSNumber *, NSNumber *> *customRetryForStatusCodes;
/**
 * Whether to anonymise server-side user identifiers including the `network_userid` and `user_ipaddress`
 */
@property () BOOL serverAnonymisation;

@end

/**
 * It allows the tracker configuration from the emission perspective.
 * The EmitterConfiguration can be used to setup details about how the tracker should treat the events
 * to emit to the collector.
 */
NS_SWIFT_NAME(EmitterConfiguration)
@interface SPEmitterConfiguration : SPConfiguration <SPEmitterConfigurationProtocol>

/**
 * Custom component with full ownership for persisting events before to be sent to the collector.
 * If it's not set the tracker will use a SQLite database as default EventStore.
 */
@property (nullable) id<SPEventStore> eventStore;

/**
 * It sets a default EmitterConfiguration.
 * Default values:
 *         bufferOption = BufferOption.Single;
 *         emitRange = 150;
 *         threadPoolSize = 15;
 *         byteLimitGet = 40000;
 *         byteLimitPost = 40000;
 *         serverAnonymisation = false;
 */
- (instancetype)init;

/**
 * Sets whether the buffer should send events instantly or after the buffer
 * has reached it's limit. By default, this is set to BufferOption Default.
 */
- (instancetype)bufferOption:(SPBufferOption)value NS_SWIFT_NAME(bufferOption(_:));
/**
 * Maximum number of events collected from the EventStore to be sent in a request.
 */
- (instancetype)emitRange:(NSInteger)value NS_SWIFT_NAME(emitRange(_:));
/**
 * Maximum number of threads working in parallel in the tracker to send requests.
 */
- (instancetype)threadPoolSize:(NSInteger)value NS_SWIFT_NAME(threadPoolSize(_:));
/**
 * Maximum amount of bytes allowed to be sent in a payload in a GET request.
 */
- (instancetype)byteLimitGet:(NSInteger)value NS_SWIFT_NAME(byteLimitGet(_:));
/**
 * Maximum amount of bytes allowed to be sent in a payload in a POST request.
 */
- (instancetype)byteLimitPost:(NSInteger)value NS_SWIFT_NAME(byteLimitPost(_:));
/**
 * Callback called for each request performed by the tracker to the collector.
 */
- (instancetype)requestCallback:(nullable id<SPRequestCallback>)value NS_SWIFT_NAME(requestCallback(_:));
/**
 * Custom component with full ownership for persisting events before to be sent to the collector.
 * If it's not set the tracker will use a SQLite database as default EventStore.
 */
- (instancetype)eventStore:(nullable id<SPEventStore>)value NS_SWIFT_NAME(eventStore(_:));
/**
 * Custom retry rules for HTTP status codes returned from the Collector.
 * The dictionary is a mapping of integers (status codes) to booleans (true for retry and false for not retry).
 */
- (instancetype)customRetryForStatusCodes:(nullable NSDictionary *)value NS_SWIFT_NAME(customRetryForStatusCodes(_:));
/**
 * Whether to anonymise server-side user identifiers including the `network_userid` and `user_ipaddress`
 */
- (instancetype)serverAnonymisation:(BOOL)value NS_SWIFT_NAME(serverAnonymisation(_:));

@end

NS_ASSUME_NONNULL_END
