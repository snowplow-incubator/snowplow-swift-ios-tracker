//
//  SPScreenView.h
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

#import "SPEventBase.h"
#import "SPSelfDescribingJson.h"

@class SPScreenState;

NS_ASSUME_NONNULL_BEGIN

/// A screenview event.
NS_SWIFT_NAME(ScreenView)
@interface SPScreenView : SPSelfDescribingAbstract

/// Name of the screen.
@property (nonatomic, readonly) NSString *name;
/// Identifier of the screen.
@property (nonatomic, readonly) NSString *screenId;
/// Type of screen.
@property (nonatomic, nullable) NSString *type;
/// Name of the previous screen.
@property (nonatomic, nullable) NSString *previousName;
/// Identifier of the previous screen.
@property (nonatomic, nullable) NSString *previousId;
/// Type of the previous screen.
@property (nonatomic, nullable) NSString *previousType;
/// Type of transition between previous and current screen,
@property (nonatomic, nullable) NSString *transitionType;
/// Name of the ViewController subclass.
@property (nonatomic, nullable) NSString *viewControllerClassName;
/// Name of the top ViewController subclass.
@property (nonatomic, nullable) NSString *topViewControllerClassName;

- (instancetype)init NS_UNAVAILABLE;

/// Creates a screenview event.
/// @param name Name of the screen.
/// @param screenId Identifier of the screen.
- (instancetype)initWithName:(NSString *)name screenId:(nullable NSUUID *)screenId NS_SWIFT_NAME(init(name:screenId:));

/// Type of screen.
- (instancetype)type:(nullable NSString *)value NS_SWIFT_NAME(type(_:));
/// Name of the previous screen.
- (instancetype)previousName:(nullable NSString *)value NS_SWIFT_NAME(previousName(_:));
/// Identifier of the previous screen.
- (instancetype)previousId:(nullable NSString *)value NS_SWIFT_NAME(previousId(_:));
/// Type of the previous screen.
- (instancetype)previousType:(nullable NSString *)value NS_SWIFT_NAME(previousType(_:));
/// Type of transition between previous and current screen,
- (instancetype)transitionType:(nullable NSString *)value NS_SWIFT_NAME(transitionType(_:));
/// Name of the ViewController subclass.
- (instancetype)viewControllerClassName:(nullable NSString *)value NS_SWIFT_NAME(viewControllerClassName(_:));
/// Name of the top ViewController subclass.
- (instancetype)topViewControllerClassName:(nullable NSString *)value NS_SWIFT_NAME(topViewControllerClassName(_:));

@end


NS_ASSUME_NONNULL_END
