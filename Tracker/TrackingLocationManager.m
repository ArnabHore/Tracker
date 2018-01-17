//
//  TrackingLocationManager.m
//  Tracker
//
//  Created by Arnab on 17/01/18.
//  Copyright © 2018 Arnab Hore. All rights reserved.
//

#import "TrackingLocationManager.h"

@implementation TrackingLocationManager
@synthesize locationManager, mainTimer, previousLocation,pedometer;
//ah 31.8

AppDelegate *appDelegate;

+ (id)locManager {
    static id locManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        locManager = [[self alloc] init];
    });
    
    return locManager;
}
- (void) updateTime {
    appDelegate.totalTime++;
}
#pragma mark - CLLocationManager
- (void) startMonitoringLocation {
    locationManager = [[CLLocationManager alloc] init];
    locationManager.allowsBackgroundLocationUpdates = YES;  //ah 7.9
    locationManager.delegate = self;
    //locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.pausesLocationUpdatesAutomatically = YES;
    [locationManager startMonitoringSignificantLocationChanges];
    [locationManager startUpdatingLocation];
    [self getPedometerData];
    
    mainTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:mainTimer forMode:NSDefaultRunLoopMode];   //ah 7.9
}
- (void) stopMonitoringLocation {
    [locationManager stopUpdatingLocation];
    [mainTimer invalidate];
    [pedometer stopPedometerUpdates];
}
#pragma mark - Location Manager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    //for (CLLocation *loc in locations) {
        if ([self filterAndAddLocationWithLocation:locations.lastObject]) {
//            CLLocationAccuracy accuracy = loc.horizontalAccuracy;
//            if (accuracy > 0 && accuracy <= 50) {
            
                CLLocation *loc = locations.lastObject;
                NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%f",loc.coordinate.latitude],@"latitude",[NSString stringWithFormat:@"%f",loc.coordinate.longitude],@"longitude", nil];
                [appDelegate.latLongArray addObject:dict];
            if (![CMPedometer isDistanceAvailable]){
                appDelegate.totalDistance += [loc distanceFromLocation:previousLocation] > 0 ? [loc distanceFromLocation:previousLocation] : 0;
            }
                previousLocation = loc;
            //}
        }
    //}
}
- (BOOL) filterAndAddLocationWithLocation:(CLLocation*)location {
    
    
    NSTimeInterval age = -location.timestamp.timeIntervalSinceNow;
    
    if (age > 10) {
        return false;
    }
    
    if (location.horizontalAccuracy < 0) {
        return false;
    }
    
    if (location.horizontalAccuracy > 100) {
        return false;
    }
    
    return true;
    
}
-(void)getPedometerData {
    
    if (!pedometer){
        pedometer = [[CMPedometer alloc]init];
    }
    
    if ([CMPedometer isDistanceAvailable]){
        
        [pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            
            if (!error){
                
//                if (isPaused && !isPausedAdded){
//                    isPausedAdded = true;
//                    pausedDistance = [pedometerData.distance doubleValue];
//                }else if (isPaused){
//                    
//                }else{
//                    
//                    if (pausedDistance > 0){
                        appDelegate.totalDistance = [pedometerData.distance doubleValue];//+pausedDistance;
//                        pausedDistance = 0;
//                    }else{
//                        appDelegate.totalDistance = [pedometerData.distance doubleValue]+pausedDistance;
//                    }
                    
//                }
                
                
            }
            
        }];
    }
    
}
@end
