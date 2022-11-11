//
//  OnSessionStateUpdate.h
//  Snowplow
//
//  Created by Matus Tomlein on 10/11/2022.
//  Copyright © 2022 Snowplow Analytics. All rights reserved.
//

#import "SPSessionState.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^OnSessionStateUpdate)(SPSessionState * _Nonnull sessionState);

NS_ASSUME_NONNULL_END
