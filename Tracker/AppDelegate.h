//
//  AppDelegate.h
//  Tracker
//
//  Created by Arnab on 17/01/18.
//  Copyright © 2018 Arnab Hore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property int totalTime;
@property (nonatomic) CLLocationDistance totalDistance;
@property (strong, nonatomic) NSMutableArray *latLongArray;

@end

