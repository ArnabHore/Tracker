//
//  TrackerViewController.h
//  Tracker
//
//  Created by Arnab on 17/01/18.
//  Copyright © 2018 Arnab Hore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "TrackingLocationManager.h"
#import "Utility.h"

@interface TrackerViewController : UIViewController<CLLocationManagerDelegate, MKMapViewDelegate>
//ah tr

@property (strong, nonatomic) NSDictionary *dataDict;
@property (strong, nonatomic) NSString *fromController;
@property (nonatomic) TrackingLocationManager *customLocManager;  //ah TR
@end
