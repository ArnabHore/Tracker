//
//  TrackerViewController.m
//  Tracker
//
//  Created by Arnab on 17/01/18.
//  Copyright © 2018 Arnab Hore. All rights reserved.
//

#import "TrackerViewController.h"
#import "SVPulsingAnnotationView.h"
#import "MAKRSampleAnnotation.h"
#import "AppDelegate.h"
#import "ActivityHistoryViewController.h"
#import <CoreMotion/CoreMotion.h>

@interface TrackerViewController () {
    IBOutlet MKMapView *customMapview;
    IBOutlet UILabel *distanceLabel;
    IBOutlet UILabel *speedLabel;
    IBOutlet UILabel *energyLabel;
    IBOutlet UILabel *timeLabel;
    IBOutlet UIButton *shareButton;
    IBOutlet UIButton *playPauseButton;
    IBOutlet UIButton *finishButton;
    IBOutlet UIScrollView *mainScroll;
    IBOutlet UIButton *shareButtonBig;
    IBOutlet UIButton *musicButton;
    
    CMPedometer *pedometer;
    
    CLLocationManager *locationManager;
    BOOL isAuthorizationAsked;
    CLLocationCoordinate2D prevLocation;
    NSTimer *mainTimer;
//    int totalTime;
//    NSMutableArray *latLongArray;
    UIView *contentView;
    MAKRSampleAnnotation *sampleAnnotation;
    BOOL isFinished;
    AppDelegate *appDelegate;
    
    double pausedDistance;
    BOOL isPaused;
    BOOL isPausedAdded;
}

@property (nonatomic, retain) MKPolyline *routeLine; //your line
@property (nonatomic, retain) MKPolylineView *routeLineView; //overlay view

// Speed
//
@property (nonatomic) CLLocationSpeed totalSpeed;
@property (nonatomic) CLLocationSpeed topSpeed;

// Distance
//
@property (nonatomic, strong) CLLocation *previousLocation;
//@property (nonatomic) CLLocationDistance totalDistance;

@end

@implementation TrackerViewController
//ah 31.8

- (void)viewDidLoad {
    [super viewDidLoad];
    pausedDistance = 0;
}
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];

    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    if (![Utility isEmptyCheck:_dataDict]) {
        isFinished = YES;
        shareButtonBig.hidden = false;
        playPauseButton.hidden = true;
        finishButton.hidden = true;
        shareButton.hidden = true;
        
        customMapview.delegate = self;
        customMapview.showsUserLocation = NO;

        distanceLabel.text = [NSString stringWithFormat:@"%.03f",[[_dataDict objectForKey:@"distance"] floatValue]];
        
        int totalTime = [[_dataDict objectForKey:@"time"] intValue];
        int seconds = totalTime % 60;
        int minutes = (totalTime / 60) % 60;
        int hours = totalTime / 3600;
        timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];

        CGFloat totalHour = hours + minutes/60.0 + seconds/3600.0;
        CGFloat distance = [[_dataDict objectForKey:@"distance"] floatValue];
        speedLabel.text = [NSString stringWithFormat:@"%.2f",distance/totalHour];
        
//        NSString *jsonString = [_dataDict objectForKey:@"latLongArray"];
//        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *mapArray= [_dataDict objectForKey:@"latLongArray"];// [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        if (![Utility isEmptyCheck:mapArray]){
            MKMapRect zoomRect = MKMapRectNull;
            
            for (int i = 0; i < mapArray.count-1; i++) {
                NSDictionary *dict = [mapArray objectAtIndex:i];
                CLLocationCoordinate2D coordinateArray[2];
                coordinateArray[0] = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] doubleValue], [[dict objectForKey:@"longitude"] doubleValue]);
                
                NSDictionary *dict1 = [mapArray objectAtIndex:i+1];
                coordinateArray[1] = CLLocationCoordinate2DMake([[dict1 objectForKey:@"latitude"] doubleValue], [[dict1 objectForKey:@"longitude"] doubleValue]);
                
                self.routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
                [customMapview addOverlay:self.routeLine level:MKOverlayLevelAboveRoads];
                
                MKMapPoint annotationPoint = MKMapPointForCoordinate(coordinateArray[1]);
                MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
                zoomRect = MKMapRectUnion(zoomRect, pointRect);
            }
            [customMapview setVisibleMapRect:zoomRect animated:YES];
        }
    } else {
        isFinished = NO;
        shareButtonBig.hidden = true;
        playPauseButton.hidden = false;
        finishButton.hidden = false;
        shareButton.hidden = false;

        shareButton.userInteractionEnabled = NO;
        [shareButton setAlpha:0.3];
        
        isAuthorizationAsked = NO;
//        appDelegate.totalTime = 0;
        
        customMapview.delegate = self;
        customMapview.showsUserLocation = NO;
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.allowsBackgroundLocationUpdates = YES;  //ah 7.9
        locationManager.delegate = self;
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways) {
            
            //locationManager.distanceFilter = kCLDistanceFilterNone;
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager.activityType = CLActivityTypeFitness;
            locationManager.pausesLocationUpdatesAutomatically = YES;
            [locationManager startMonitoringSignificantLocationChanges];
            
            double latitude = locationManager.location.coordinate.latitude;
            double longitude = locationManager.location.coordinate.longitude;
            //prevLocation = CLLocationCoordinate2DMake(latitude, longitude);
            
            _customLocManager = [TrackingLocationManager locManager];
            [_customLocManager stopMonitoringLocation];
            
            [locationManager startUpdatingLocation];
            mainTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:mainTimer forMode:NSDefaultRunLoopMode];//ah 7.9

            CLLocationCoordinate2D center;
            center.latitude= latitude;
            center.longitude = longitude;
            MKCoordinateRegion region = [customMapview regionThatFits:MKCoordinateRegionMakeWithDistance(center, 200, 200)];
            [customMapview setRegion:region animated:YES];
            
            sampleAnnotation = [MAKRSampleAnnotation new];
            sampleAnnotation.coordinate = center;
            [customMapview addAnnotation:sampleAnnotation];
            
            if (![Utility isEmptyCheck:appDelegate.latLongArray]) {
                [self plotMap];
            }
            
            [self getPedometerData];
            
//            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%f",latitude],@"latitude",[NSString stringWithFormat:@"%f",longitude],@"longitude", nil];
//            [appDelegate.latLongArray addObject:dict];
        } else {
            [locationManager requestAlwaysAuthorization];
            isAuthorizationAsked = YES;
        }
    }
    
//ah 7.9
//    if (appDelegate.inactiveTimeInterval > 0) {
//        appDelegate.totalTime += appDelegate.inactiveTimeInterval;
//        appDelegate.inactiveTimeInterval = 0;
//    }
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIApplicationDidBecomeActiveNotification
//                                                  object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(activeNotification)
//                                                 name:UIApplicationDidBecomeActiveNotification object:nil];

    
//    if ([_fromController caseInsensitiveCompare:@"squadData"] == NSOrderedSame) {   //ah fbw2
//        shareButton.hidden = true;
//        shareButtonBig.hidden = true;
//        finishButton.hidden = true;
//        playPauseButton.hidden = true;
//    }
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    
    [_customLocManager startMonitoringLocation];
    [customMapview removeAnnotations:customMapview.annotations];
    
    NSArray *pointsArray = [customMapview overlays];
    [customMapview removeOverlays:pointsArray];
    
    [locationManager stopUpdatingLocation];
    [mainTimer invalidate];
    mainTimer = nil;

    [pedometer stopPedometerUpdates];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;

//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIApplicationDidBecomeActiveNotification
//                                                  object:nil];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction
-(IBAction)back:(id)sender {
    [self shouldPopOnBackButtonWithResponse:^(BOOL shouldPop) {
        if (shouldPop) {
            [locationManager stopUpdatingLocation];
            [mainTimer invalidate];
            mainTimer = nil;
            
            isFinished = YES;
            [appDelegate.latLongArray removeAllObjects];
            appDelegate.totalTime = 0;
            appDelegate.totalDistance = 0;
            [pedometer stopPedometerUpdates];            
            
            ActivityHistoryViewController *controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ActivityHistory"];
            [self.navigationController pushViewController:controller animated:YES];
        }
    }];
}
- (IBAction)showMenu:(id)sender {
//    [self shouldPopOnBackButtonWithResponse:^(BOOL shouldPop) {
//        if (shouldPop) {
//            [self.slidingViewController anchorTopViewToRightAnimated:YES];
//            [self.slidingViewController resetTopViewAnimated:YES];
//        }
//    }];
}
- (IBAction)logoButtonPressed:(UIButton *)sender {
//        [self shouldPopOnBackButtonWithResponse:^(BOOL shouldPop) {
//        if (shouldPop) {
            [self.navigationController popToRootViewControllerAnimated:YES];
//        }
//    }];
}
- (IBAction)musicButtonTapped:(id)sender {
//    AudioBookViewController *controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"AudioBook"];
//    [self.navigationController pushViewController:controller animated:YES];
}
- (IBAction)finish:(id)sender {
    if ([distanceLabel.text floatValue] > 0.1) {
        [self shouldPopOnBackButtonWithResponse:^(BOOL shouldPop) {
            if (shouldPop) {
                [locationManager stopUpdatingLocation];
                [mainTimer invalidate];
                
               /* customMapview.showsUserLocation = NO;
                [playPauseButton setSelected:true];
                playPauseButton.userInteractionEnabled = NO;
                [playPauseButton setAlpha:0.3];
                finishButton.userInteractionEnabled = NO;
                [finishButton setAlpha:0.3];
                shareButton.userInteractionEnabled = YES;
                [shareButton setAlpha:1];
                
                [customMapview removeAnnotations:customMapview.annotations];    //ah fbw2

                NSArray *pointsArray = [customMapview overlays];
                [customMapview removeOverlays:pointsArray];
                NSLog(@"arr %@",appDelegate.latLongArray);*/
                
//                MKMapRect zoomRect = MKMapRectNull;
//                
//                for (int i = 0; i < appDelegate.latLongArray.count-1; i++) {
//                    NSDictionary *dict = [appDelegate.latLongArray objectAtIndex:i];
//                    CLLocationCoordinate2D coordinateArray[2];
//                    coordinateArray[0] = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] doubleValue], [[dict objectForKey:@"longitude"] doubleValue]);
//                    
//                    NSDictionary *dict1 = [appDelegate.latLongArray objectAtIndex:i+1];
//                    coordinateArray[1] = CLLocationCoordinate2DMake([[dict1 objectForKey:@"latitude"] doubleValue], [[dict1 objectForKey:@"longitude"] doubleValue]);
//                    
//                    self.routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
//                    [customMapview addOverlay:self.routeLine level:MKOverlayLevelAboveRoads];
//                    
//                    MKMapPoint annotationPoint = MKMapPointForCoordinate(coordinateArray[1]);
//                    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
//                    zoomRect = MKMapRectUnion(zoomRect, pointRect);
//                }
//                [customMapview setVisibleMapRect:zoomRect animated:YES];
                
                NSError *error;
                NSData *postData = [NSJSONSerialization dataWithJSONObject:appDelegate.latLongArray options:NSJSONWritingPrettyPrinted  error:&error];
                if (error) {
                    [Utility msg:@"Something went wrong. Please try again later." title:@"Oops" controller:self haveToPop:NO];
                    return;
                }
                NSString *jsonString = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
                NSLog(@"json %@",jsonString);
                
                [pedometer stopPedometerUpdates];
                [self saveFbwDataWithJson:jsonString];
            }
        }];
    } else {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Finish?"
                                              message:@"Do you really want to finish? You need to move a bit more to save your activity."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"Finish"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction *action)
                                   {
                                       isFinished = YES;
                                       [appDelegate.latLongArray removeAllObjects];
                                       appDelegate.totalTime = 0;
                                       appDelegate.totalDistance = 0;
                                       [pedometer stopPedometerUpdates];
                                       [self back:nil];
                                   }];
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {

                                       }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

-(IBAction)share:(id)sender {
    UIImage *shareImage = [self captureView:mainScroll];
    NSArray *items = @[shareImage];
    
    // build an activity view controller
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    
    // and present it
    [self presentActivityController:controller];
}
- (IBAction)pause:(UIButton *)sender {
    if (sender.isSelected) {
        [sender setSelected:NO];
        isPaused = false;
        [self getPedometerData];
        mainTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:mainTimer forMode:NSDefaultRunLoopMode];//ah 7.9

        //locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.activityType = CLActivityTypeFitness;
        locationManager.pausesLocationUpdatesAutomatically = YES;
        [locationManager startMonitoringSignificantLocationChanges];
        
        double latitude = locationManager.location.coordinate.latitude;
        double longitude = locationManager.location.coordinate.longitude;
        prevLocation = CLLocationCoordinate2DMake(latitude, longitude);
        NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%f",prevLocation.latitude],@"latitude",[NSString stringWithFormat:@"%f",prevLocation.longitude],@"longitude", nil];
        [appDelegate.latLongArray addObject:dict];
        [locationManager startUpdatingLocation];
    } else {
        
        isPaused = true;
        if (!isPausedAdded){
            isPausedAdded = true;
            pausedDistance += appDelegate.totalDistance;
        }
        
        [sender setSelected:YES];
        [mainTimer invalidate];
        [locationManager stopUpdatingLocation];
        [pedometer stopPedometerUpdates];
    }
}

#pragma mark - Location Manager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        
        //locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.activityType = CLActivityTypeFitness;
        locationManager.pausesLocationUpdatesAutomatically = YES;
        [locationManager startMonitoringSignificantLocationChanges];
        
        double latitude = locationManager.location.coordinate.latitude;
        double longitude = locationManager.location.coordinate.longitude;
        NSLog(@"lat %f long %f",latitude,longitude);
        //        customMapview.showsUserLocation = YES;
        
        CLLocationCoordinate2D center;
        center.latitude= latitude;
        center.longitude = longitude;
        MKCoordinateRegion region = [customMapview regionThatFits:MKCoordinateRegionMakeWithDistance(center, 1000, 1000)];
        [customMapview setRegion:region animated:YES];
        isAuthorizationAsked = NO;
        
        BOOL isValid = mainTimer.isValid;
        
        if (!mainTimer || !isValid){
            
            mainTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:mainTimer forMode:NSDefaultRunLoopMode];//ah 7.9
        }
        
        if (!sampleAnnotation){
            sampleAnnotation = [MAKRSampleAnnotation new];
        }
        
        
        
        sampleAnnotation.coordinate = center;
        [customMapview addAnnotation:sampleAnnotation];
        
        [self getPedometerData];
        
    } else {
        if (!isAuthorizationAsked) {
            NSString *title = (status == kCLAuthorizationStatusDenied) ? @"Location service is off" : @"Location Service is not enabled";
            NSString *message = @"To use this feature you must turn on Location Service in the Settings menu. Go to 'Settings'->'Location'->'When In Use'";
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:title
                                                  message:message
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:@"Settings"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                           [[UIApplication sharedApplication] openURL:settingsURL];
                                       }];
            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:@"Cancel"
                                           style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction *action)
                                           {
                                               [self.navigationController popViewControllerAnimated:YES];
                                           }];
            [alertController addAction:okAction];
            [alertController addAction:cancelAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
}


/* - (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocationCoordinate2D coordinateArray[2];
    coordinateArray[0] = prevLocation;
    
    for (CLLocation *loc in locations) {
        if ([self filterAndAddLocationWithLocation:loc]) {
            
            //CLLocationAccuracy accuracy = loc.horizontalAccuracy;
            //        NSLog(@"kCLLocationAccuracyBest -> %f",kCLLocationAccuracyBest);
            //        NSLog(@"kCLLocationAccuracyBestForNavigation -> %f",kCLLocationAccuracyBestForNavigation);
            //        NSLog(@"kCLLocationAccuracyNearestTenMeters -> %f",kCLLocationAccuracyNearestTenMeters);
            //        NSLog(@"kCLLocationAccuracyNearestTenMeters -> %f",kCLLocationAccuracyNearestTenMeters);
            //        NSLog(@"horizontalAccuracy -> %f",loc.horizontalAccuracy);
            //        NSLog(@"verticalAccuracy -> %f",loc.verticalAccuracy);
            
            //        NSString *acc = [NSString stringWithFormat:@"horizontalAccuracy %f & verticalAccuracy %f",loc.horizontalAccuracy,loc.verticalAccuracy];
            //      [Utility showToastInsideView:self.view WithMessage:acc];
            
            //if (accuracy > 0 && accuracy <= 50) {
                [UIView animateWithDuration:0.1f animations:^{
                    sampleAnnotation.coordinate = loc.coordinate;
                }];
                
                coordinateArray[1] = loc.coordinate;
                
                self.routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
                [customMapview addOverlay:self.routeLine level:MKOverlayLevelAboveRoads];
                
                prevLocation = coordinateArray[1];
                
                NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%f",prevLocation.latitude],@"latitude",[NSString stringWithFormat:@"%f",prevLocation.longitude],@"longitude", nil];
                [appDelegate.latLongArray addObject:dict];
                
//                MKPointAnnotation *currentAnnotaion = [[MKPointAnnotation alloc] init];
//                 currentAnnotaion.coordinate = loc.coordinate;
//                 MKMapRect visibleMapRect = customMapview.visibleMapRect;
//                 NSSet *visibleAnnotations = [customMapview annotationsInMapRect:visibleMapRect];
//                 BOOL annotationIsVisible = [visibleAnnotations containsObject:currentAnnotaion];
//                 if (!annotationIsVisible) {
//                 [customMapview setVisibleMapRect:[self.routeLine boundingMapRect]];
//                 }
 
               [self handleLocationUpdate:loc];
            //}
        }
    }
}*/

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    if (![self filterAndAddLocationWithLocation:locations.lastObject]) {
        
        return;
    }
    
    CLLocation *lastLocation = locations.lastObject;
    CLLocationCoordinate2D lastCoordinate = lastLocation.coordinate;
    
    if (prevLocation.latitude == 0.0 && prevLocation.longitude == 0.0) {
        prevLocation = lastCoordinate ;
    }
    
    
    
    [UIView animateWithDuration:0.1f animations:^{
        sampleAnnotation.coordinate = lastLocation.coordinate;
    }];
    
    CLLocationCoordinate2D coordinateArray[2];
    coordinateArray[0] = prevLocation;
    coordinateArray[1] = lastCoordinate;
    
    self.routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
    [customMapview addOverlay:self.routeLine level:MKOverlayLevelAboveRoads];
    
    prevLocation = lastCoordinate;
    
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%f",prevLocation.latitude],@"latitude",[NSString stringWithFormat:@"%f",prevLocation.longitude],@"longitude", nil];
    [appDelegate.latLongArray addObject:dict];
    
    [self handleLocationUpdate:lastLocation];
    
    
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
#pragma mark - Map view delegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:self.routeLine];
    renderer.fillColor = [UIColor colorWithRed:244/255.0 green:39/255.0 blue:171/255.0 alpha:1.0];
    renderer.strokeColor = [UIColor colorWithRed:244/255.0 green:39/255.0 blue:171/255.0 alpha:1.0];
    renderer.lineWidth = 5;
    
    MKMapRect visibleMapRect = customMapview.visibleMapRect;
    NSSet *visibleAnnotations = [customMapview annotationsInMapRect:visibleMapRect];
    BOOL annotationIsVisible = [visibleAnnotations containsObject:sampleAnnotation];
    if (!annotationIsVisible) {
        MKCoordinateRegion currentRegion = mapView.region;
        currentRegion.center = sampleAnnotation.coordinate;
        [customMapview setRegion:currentRegion animated:YES];
    }
    
    return renderer;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (!mapView.userLocationVisible && [Utility isEmptyCheck:_dataDict]) {
        MKCoordinateRegion currentRegion = mapView.region;
        currentRegion.center = userLocation.coordinate;
        [customMapview setRegion:currentRegion animated:YES];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if([annotation isKindOfClass:[MAKRSampleAnnotation class]]) {
        static NSString *identifier = @"currentLocation";
        SVPulsingAnnotationView *pulsingView = (SVPulsingAnnotationView *)[customMapview dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if(pulsingView == nil) {
            pulsingView = [[SVPulsingAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            pulsingView.canShowCallout = NO;
        }
        
        return pulsingView;
    }
    
    return nil;
}
#pragma mark - Calculations

- (void)handleLocationUpdate:(CLLocation *)location {
//    energyLabel.text = @"speed";
    // Speed
    //
//    CLLocationSpeed speed = location.speed;
//    self.totalSpeed += speed;
//    
//    if (speed > self.topSpeed) {
//        self.topSpeed = speed;
//    }
    
    if ((location.speed*3.6) > 0)
        speedLabel.text = [NSString stringWithFormat:@"%0.2f",(location.speed*3.6)];
    
    // Distance
    //
    if (![CMPedometer isDistanceAvailable]){
        appDelegate.totalDistance += [location distanceFromLocation:self.previousLocation] > 0 ? [location distanceFromLocation:self.previousLocation] : 0;
    }
    
    self.previousLocation = location;
    
    if (appDelegate.totalDistance/1000.0 > 0)
        distanceLabel.text = [NSString stringWithFormat:@"%0.3f",appDelegate.totalDistance/1000.0];

}
#pragma mark - Private Methods
-(void) updateTime {
    if (appDelegate.totalTime == 0) {
        NSArray *pointsArray = [customMapview overlays];
        [customMapview removeOverlays:pointsArray];
        distanceLabel.text = @"0.000";
    }
    
    appDelegate.totalTime++;
    
    int seconds = appDelegate.totalTime % 60;
    int minutes = (appDelegate.totalTime / 60) % 60;
    int hours = appDelegate.totalTime / 3600;
    
    timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (UIImage*)captureView:(UIView *)captureView {
    CGRect rect = captureView.bounds;
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [captureView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
- (void)presentActivityController:(UIActivityViewController *)controller {
    
    // for iPad: make the presentation a Popover
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.barButtonItem = self.navigationItem.leftBarButtonItem;
    
    // access the completion handler
    controller.completionWithItemsHandler = ^(NSString *activityType,
                                              BOOL completed,
                                              NSArray *returnedItems,
                                              NSError *error){
        // react to the completion
        if (completed) {
            
            // user shared an item
            NSLog(@"We used activity type%@", activityType);
            
        } else {
            
            // user cancelled
            NSLog(@"We didn't want to share anything after all.");
        }
        
        if (error) {
            NSLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
        }
    };
}
- (void) shouldPopOnBackButtonWithResponse:(void (^)(BOOL shouldPop))response {
    if (isFinished) {
        response(YES);
    } else {
        [self pause:playPauseButton];       //ah fbw2
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Finish?"
                                              message:@"Are you sure you want to stop your activity?"
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"Finish"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       isFinished = YES;
                                       response(YES);
                                   }];
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {
                                           [self pause:playPauseButton];       //ah tr
                                           response(NO);
                                       }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}
- (void) plotMap {
    NSArray *mapArray = appDelegate.latLongArray;
    if (![Utility isEmptyCheck:mapArray]){
        MKMapRect zoomRect = MKMapRectNull;
        
        for (int i = 0; i < mapArray.count-1; i++) {
            NSDictionary *dict = [mapArray objectAtIndex:i];
            CLLocationCoordinate2D coordinateArray[2];
            coordinateArray[0] = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] doubleValue], [[dict objectForKey:@"longitude"] doubleValue]);
            
            NSDictionary *dict1 = [mapArray objectAtIndex:i+1];
            coordinateArray[1] = CLLocationCoordinate2DMake([[dict1 objectForKey:@"latitude"] doubleValue], [[dict1 objectForKey:@"longitude"] doubleValue]);
            
            self.routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
            [customMapview addOverlay:self.routeLine level:MKOverlayLevelAboveRoads];
            
            MKMapPoint annotationPoint = MKMapPointForCoordinate(coordinateArray[1]);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        [customMapview setVisibleMapRect:zoomRect animated:YES];
    }
}

-(void)getPedometerData {
    
    if (!pedometer){
        pedometer = [[CMPedometer alloc]init];
    }
    
    if ([CMPedometer isDistanceAvailable]){
        
        [pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            
            if (!error){
                
                if (isPaused){
                    
                }else{
                    appDelegate.totalDistance = [pedometerData.distance doubleValue]+pausedDistance;
                }
            }
        }];
    }
    
}

//- (void)activeNotification {    //ah 7.9
//    NSLog(@"vc active");
//    if (appDelegate.inactiveTimeInterval > 0) {
//        appDelegate.totalTime += appDelegate.inactiveTimeInterval;
//        appDelegate.inactiveTimeInterval = 0;
//    }
//}
#pragma mark - Save Data
-(void) saveFbwDataWithJson:(NSString *) latLongJson{
    customMapview.showsUserLocation = NO;
    [playPauseButton setSelected:true];
    playPauseButton.userInteractionEnabled = NO;
    [playPauseButton setAlpha:0.3];
    finishButton.userInteractionEnabled = NO;
    [finishButton setAlpha:0.3];
    shareButton.userInteractionEnabled = YES;
    [shareButton setAlpha:1];
    
    [customMapview removeAnnotations:customMapview.annotations];    //ah fbw2
    
    NSArray *pointsArray = [customMapview overlays];
    [customMapview removeOverlays:pointsArray];
    
    MKMapRect zoomRect = MKMapRectNull;
    
    for (int i = 0; i < appDelegate.latLongArray.count-1; i++) {
        NSDictionary *dict = [appDelegate.latLongArray objectAtIndex:i];
        CLLocationCoordinate2D coordinateArray[2];
        coordinateArray[0] = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] doubleValue], [[dict objectForKey:@"longitude"] doubleValue]);
        
        NSDictionary *dict1 = [appDelegate.latLongArray objectAtIndex:i+1];
        coordinateArray[1] = CLLocationCoordinate2DMake([[dict1 objectForKey:@"latitude"] doubleValue], [[dict1 objectForKey:@"longitude"] doubleValue]);
        
        self.routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
        [customMapview addOverlay:self.routeLine level:MKOverlayLevelAboveRoads];
        
        MKMapPoint annotationPoint = MKMapPointForCoordinate(coordinateArray[1]);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    [customMapview setVisibleMapRect:zoomRect animated:YES];
    
    NSLog(@"arr %@",appDelegate.latLongArray);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    NSString *currentDateStr = [formatter stringFromDate:[NSDate date]];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:appDelegate.latLongArray forKey:@"latLongArray"];
    [dict setObject:[NSNumber numberWithInt:appDelegate.totalTime] forKey:@"time"];
    [dict setObject:[NSNumber numberWithDouble:appDelegate.totalDistance] forKey:@"distance"];
    [dict setObject:currentDateStr forKey:@"date"];
    
    NSMutableArray *savedArray = [[NSMutableArray alloc] init];
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"savedData"] isKindOfClass:[NSNull class]]) {
        [savedArray addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"savedData"]];
    }
    [savedArray addObject:dict];
    
    [[NSUserDefaults standardUserDefaults] setObject:savedArray forKey:@"savedData"];
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"savedData"]);
    
    [appDelegate.latLongArray removeAllObjects];
    appDelegate.totalTime = 0;
    appDelegate.totalDistance = 0;
}
//    if (Utility.reachable) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (contentView) {
//                [contentView removeFromSuperview];
//            }
//            contentView = [Utility activityIndicatorView:self];
//        });
//
//        NSURLSession *customSession = [NSURLSession sharedSession];
//
//        NSError *error;
//
//        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZZZZZ"];
//        NSString *currentDateStr = [formatter stringFromDate:[NSDate date]];
//
//        NSMutableDictionary *mainDict=[[NSMutableDictionary alloc]init];
//        [mainDict setObject:AccessKey forKey:@"Key"];
//        [mainDict setObject:[defaults objectForKey:@"UserSessionID"] forKey:@"UserSessionID"];
//        [mainDict setObject:[defaults objectForKey:@"UserID"] forKey:@"UserID"];
//        [mainDict setObject:[NSNumber numberWithInteger:1] forKey:@"EventType"];
//        [mainDict setObject:currentDateStr forKey:@"Logdate"];
//        [mainDict setObject:timeLabel.text forKey:@"Time"];
//        [mainDict setObject:[NSNumber numberWithFloat:[distanceLabel.text floatValue]] forKey:@"Distance"];
//        [mainDict setObject:[NSNumber numberWithFloat:[speedLabel.text floatValue]] forKey:@"Speed"];
//        [mainDict setObject:[NSNumber numberWithInteger:0] forKey:@"Energy"];
//        [mainDict setObject:latLongJson forKey:@"GoogleMapJsonData"];
//
//        NSData *postData = [NSJSONSerialization dataWithJSONObject:mainDict options:NSJSONWritingPrettyPrinted  error:&error];
//        if (error) {
//            [Utility msg:@"Something went wrong. Please try again later." title:@"Oops" controller:self haveToPop:NO];
//            return;
//        }
//        NSString *jsonString = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
//
//        NSMutableURLRequest *request = [Utility getRequest:jsonString api:@"AddTrackData" append:@""forAction:@"POST"];
//        NSURLSessionDataTask * dataTask =[customSession dataTaskWithRequest:request
//                                                          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//                                                              dispatch_async(dispatch_get_main_queue(), ^{
//                                                                  if (contentView) {
//                                                                      [contentView removeFromSuperview];
//                                                                  }
//                                                                  if(error == nil)
//                                                                  {
//                                                                      NSString* responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//                                                                      NSDictionary *responseDict= [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//                                                                      if (![Utility isEmptyCheck:responseString] && ![Utility isEmptyCheck:responseDict] && [[responseDict objectForKey:@"Success"]boolValue]) {
//
//                                                                          customMapview.showsUserLocation = NO;
//                                                                          [playPauseButton setSelected:true];
//                                                                          playPauseButton.userInteractionEnabled = NO;
//                                                                          [playPauseButton setAlpha:0.3];
//                                                                          finishButton.userInteractionEnabled = NO;
//                                                                          [finishButton setAlpha:0.3];
//                                                                          shareButton.userInteractionEnabled = YES;
//                                                                          [shareButton setAlpha:1];
//
//                                                                          [customMapview removeAnnotations:customMapview.annotations];    //ah fbw2
//
//                                                                          NSArray *pointsArray = [customMapview overlays];
//                                                                          [customMapview removeOverlays:pointsArray];
//
//                                                                          MKMapRect zoomRect = MKMapRectNull;
//
//                                                                          for (int i = 0; i < appDelegate.latLongArray.count-1; i++) {
//                                                                              NSDictionary *dict = [appDelegate.latLongArray objectAtIndex:i];
//                                                                              CLLocationCoordinate2D coordinateArray[2];
//                                                                              coordinateArray[0] = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] doubleValue], [[dict objectForKey:@"longitude"] doubleValue]);
//
//                                                                              NSDictionary *dict1 = [appDelegate.latLongArray objectAtIndex:i+1];
//                                                                              coordinateArray[1] = CLLocationCoordinate2DMake([[dict1 objectForKey:@"latitude"] doubleValue], [[dict1 objectForKey:@"longitude"] doubleValue]);
//
//                                                                              self.routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
//                                                                              [customMapview addOverlay:self.routeLine level:MKOverlayLevelAboveRoads];
//
//                                                                              MKMapPoint annotationPoint = MKMapPointForCoordinate(coordinateArray[1]);
//                                                                              MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
//                                                                              zoomRect = MKMapRectUnion(zoomRect, pointRect);
//                                                                          }
//                                                                          [customMapview setVisibleMapRect:zoomRect animated:YES];
//
//                                                                          NSLog(@"arr %@",appDelegate.latLongArray);
//
//                                                                          [appDelegate.latLongArray removeAllObjects];
//                                                                          appDelegate.totalTime = 0;
//                                                                          appDelegate.totalDistance = 0;
//                                                                          [Utility msg:@"Saved Successfully!" title:@"Success" controller:self haveToPop:NO];
//                                                                      }
//                                                                      else{
//                                                                          [Utility msg:[responseDict objectForKey:@"ErrorMessage"] title:@"Error !" controller:self haveToPop:NO];
//                                                                          return;
//                                                                      }
//                                                                  }else{
//                                                                      [Utility msg:error.localizedDescription title:@"Error !" controller:self haveToPop:NO];
//                                                                  }
//                                                              });
//
//                                                          }];
//        [dataTask resume];
//
//    }else{
//        [Utility msg:@"Check Your network connection and try again." title:@"Oops! " controller:self haveToPop:NO];
//    }
//}

@end
