//
//  SPWebViewMessageHandler.m
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
//  Authors: Matus Tomlein
//  License: Apache License Version 2.0
//

#import "SPWebViewMessageHandler.h"
#import "SPSnowplow.h"
#import "SPSelfDescribing.h"
#import "SPStructured.h"
#import "SPPageView.h"
#import "SPScreenView.h"

#if SNOWPLOW_TARGET_IOS || SNOWPLOW_TARGET_OSX

@implementation SPWebViewMessageHandler

/**
 * Callback called when the message handler receives a new message.
 *
 * The message dictionary should contain three properties:
 * 1. "event" with a dictionary containing the event information (structure depends on the tracked event)
 * 2. "context" (optional) with a list of self-describing JSONs
 * 3. "trackers" (optional) with a list of tracker namespaces to track the event with
 */
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *event = message.body[@"event"];
    NSArray<NSDictionary *> *context = message.body[@"context"];
    NSArray<NSString *> *trackers = message.body[@"trackers"];
    NSString *command = message.body[@"command"];

    if ([command isEqual:@"trackSelfDescribingEvent"]) {
        [self trackSelfDescribing:event withContext:context andTrackers:trackers];
    } else if ([command isEqual: @"trackStructEvent"]) {
        [self trackStructEvent:event withContext:context andTrackers:trackers];
    } else if ([command isEqual: @"trackPageView"]) {
        [self trackPageView:event withContext:context andTrackers:trackers];
    } else if ([command isEqual: @"trackScreenView"]) {
        [self trackScreenView:event withContext:context andTrackers:trackers];
    }
}

- (void)trackSelfDescribing:(NSDictionary *)event withContext:(NSArray<NSDictionary *> *)context andTrackers:(NSArray<NSString *> *)trackers {
    NSString *schema = event[@"schema"];
    NSDictionary *payload = event[@"data"];
    
    if (schema && payload) {
        SPSelfDescribing *selfDescribing = [[SPSelfDescribing alloc] initWithSchema:schema payload:payload];
        [self track:selfDescribing withContext:context andTrackers:trackers];
    }
}

- (void)trackStructEvent:(NSDictionary *)event withContext:(NSArray<NSDictionary *> *)context andTrackers:(NSArray<NSString *> *)trackers {
    NSString *category = event[@"category"];
    NSString *action = event[@"action"];
    NSString *label = event[@"label"];
    NSString *property = event[@"property"];
    NSNumber *value = event[@"value"];
    
    if (category && action) {
        SPStructured *structured = [[SPStructured alloc] initWithCategory:category action:action];
        if (label) { structured.label = label; }
        if (property) { structured.property = property; }
        if (value) { structured.value = value; }
        [self track:structured withContext:context andTrackers:trackers];
    }
}

- (void)trackPageView:(NSDictionary *)event withContext:(NSArray<NSDictionary *> *)context andTrackers:(NSArray<NSString *> *)trackers {
    NSString *url = event[@"url"];
    NSString *title = event[@"title"];
    NSString *referrer = event[@"referrer"];
    
    if (url) {
        SPPageView *pageView = [[SPPageView alloc] initWithPageUrl:url];
        if (title) { pageView.pageTitle = title; }
        if (referrer) { pageView.referrer = referrer; }
        [self track:pageView withContext:context andTrackers:trackers];
    }
}

- (void)trackScreenView:(NSDictionary *)event withContext:(NSArray<NSDictionary *> *)context andTrackers:(NSArray<NSString *> *)trackers {
    NSString *name = event[@"name"];
    NSString *screenId = event[@"id"];
    NSString *type = event[@"type"];
    NSString *previousName = event[@"previousName"];
    NSString *previousId = event[@"previousId"];
    NSString *previousType = event[@"previousType"];
    NSString *transitionType = event[@"transitionType"];
    
    if (name && screenId) {
        NSUUID *screenUuid = [[NSUUID alloc] initWithUUIDString:screenId];
        SPScreenView *screenView = [[SPScreenView alloc] initWithName:name screenId:screenUuid];
        if (type) { screenView.type = type; }
        if (previousName) { screenView.previousName = previousName; }
        if (previousId) { screenView.previousId = previousId; }
        if (previousType) { screenView.previousType = previousType; }
        if (transitionType) { screenView.transitionType = transitionType; }
        [self track:screenView withContext:context andTrackers:trackers];
    }
}

- (void)track:(SPEvent *)event withContext:(NSArray<NSDictionary *> *)context andTrackers:(NSArray<NSString *> *)trackers {
    if (context) {
        event.contexts = [self parseContext:context];
    }
    if (trackers.count > 0) {
        for (NSString *namespace in trackers) {
            id<SPTrackerController> tracker = [SPSnowplow trackerByNamespace:namespace];
            if (tracker) {
                [tracker track:event];
            }
        }
    } else {
        [[SPSnowplow defaultTracker] track:event];
    }
}

- (NSMutableArray<SPSelfDescribingJson *> *) parseContext:(NSArray<NSDictionary *> *)context {
    NSMutableArray<SPSelfDescribingJson *> *contextEntities = [[NSMutableArray alloc] init];

    for (NSDictionary *entityJson in context) {
        NSString *schema = entityJson[@"schema"];
        NSDictionary *payload = entityJson[@"data"];
        
        if (schema && payload) {
            SPSelfDescribingJson *entity = [[SPSelfDescribingJson alloc] initWithSchema:schema andDictionary:payload];
            [contextEntities addObject:entity];
        }
    }
    
    return contextEntities;
}

@end

#endif
