//
//  Utility.m
//  Tracker
//
//  Created by Arnab on 17/01/18.
//  Copyright © 2018 Arnab Hore. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+(BOOL)isEmptyCheck:(id)data{
    BOOL isEmpty=YES;
    if ([data class] !=[NSNull class]) {
        if (data !=nil) {
            if ([data isKindOfClass:[NSString class]] && ([data isEqualToString:@""] || [data isEqualToString:@"<null>"])) {
                return YES;
            }else if([data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSMutableDictionary class]]){
                NSDictionary *temp = (NSDictionary *)data;
                if (temp.count > 0) {
                    return NO;
                }else{
                    return YES;
                }
            }else if([data isKindOfClass:[NSMutableArray class]] || [data isKindOfClass:[NSArray class]]){
                NSArray *temp = (NSArray *)data;
                if (temp.count > 0) {
                    return NO;
                }else{
                    return YES;
                }
            }
            isEmpty = NO;
        }
    }
    return isEmpty;
}

+ (void)msg:(NSString*)str title:(NSString *)title controller:(UIViewController *)controller haveToPop:(BOOL)haveToPop{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:title
                                          message:str
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:haveToPop ? UIAlertActionStyleCancel : UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   if (haveToPop) {
                                       [controller.navigationController popViewControllerAnimated:YES];
                                   }
                               }];
    [alertController addAction:okAction];
    [controller presentViewController:alertController animated:YES completion:nil];
    
}


@end
