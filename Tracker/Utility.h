//
//  Utility.h
//  Tracker
//
//  Created by Arnab on 17/01/18.
//  Copyright © 2018 Arnab Hore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utility : NSObject

+(BOOL)isEmptyCheck:(id)data;
+ (void)msg:(NSString*)str title:(NSString *)title controller:(UIViewController *)controller haveToPop:(BOOL)haveToPop;

@end
