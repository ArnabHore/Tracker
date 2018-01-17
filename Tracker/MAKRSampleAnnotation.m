//
//  MAKRSampleAnnotation.m
//  MapKit Callout-Views
//
//  Created by Alexander Repty on 08.12.13.
//  Copyright (c) 2013 alexrepty. All rights reserved.
//

#import "MAKRSampleAnnotation.h"

@interface MAKRSampleAnnotation ()

@property(nonatomic,assign) CLLocationCoordinate2D coordinate;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *subtitle;
@end

@implementation MAKRSampleAnnotation
// required if you set the MKPinAnnotationView's "canShowCallout" property to YES
- (NSString *)title
{
//    return @"Golden Gate Bridge";
    return _title;
}

// optional
- (NSString *)subtitle
{
//    return @"Opened: May 27, 1937";   //ah new3
    return _subtitle;
}

@end
