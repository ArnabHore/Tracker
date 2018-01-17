//
//  TrackingLocationManager.h
//  Tracker
//
//  Created by Arnab on 17/01/18.
//  Copyright © 2018 Arnab Hore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "AppDelegate.h"
#import <CoreMotion/CoreMotion.h>

@interface TrackingLocationManager : NSObject <CLLocationManagerDelegate>
//ah tr

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSTimer *mainTimer;
@property (nonatomic, strong) CLLocation *previousLocation;
@property (nonatomic, strong) CMPedometer *pedometer;

+ (id)locManager;
- (void) startMonitoringLocation;
- (void) stopMonitoringLocation;
@end
