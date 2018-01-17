//
//  ActivityHistoryViewController.m
//  Tracker
//
//  Created by Arnab on 17/01/18.
//  Copyright © 2018 Arnab Hore. All rights reserved.
//

#import "ActivityHistoryViewController.h"
#import "ActivityHistoryTableViewCell.h"
#import "TrackerViewController.h"
#import "AppDelegate.h"

@interface ActivityHistoryViewController () {
    IBOutlet UITableView *table;
    
    UIView *contentView;
    NSMutableArray *activityHistoryArray;
    NSMutableArray *filterArray;
    int dayFilter;
    AppDelegate *appDelegate;
}

@end

@implementation ActivityHistoryViewController
//ah 31.8

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    activityHistoryArray = [[NSMutableArray alloc] init];
    filterArray = [[NSMutableArray alloc] init];
    dayFilter = 0;

}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"savedData"] isKindOfClass:[NSNull class]]) {
        [activityHistoryArray addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"savedData"]];
        [table reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction
-(IBAction)back:(id)sender {
    TrackerViewController *controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Tracker"];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - TableView Datasource & Delegate


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return activityHistoryArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *CellIdentifier = @"ActivityHistoryTableViewCell";
    ActivityHistoryTableViewCell *cell = (ActivityHistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (cell == nil) {
        cell = [[ActivityHistoryTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *dict = [activityHistoryArray objectAtIndex:indexPath.row];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    NSDate *newDate = [formatter dateFromString:[dict objectForKey:@"date"]];
    [formatter setDateFormat:@"MMMM dd, yyyy"];
    NSString *dateStr = [formatter stringFromDate:newDate];
    
    cell.dateLabel.text = dateStr;
    cell.distanceLabel.text = [NSString stringWithFormat:@"%.03f",[[dict objectForKey:@"distance"] floatValue]];
    
    int totalTime = [[dict objectForKey:@"time"] intValue];
    int seconds = totalTime % 60;
    int minutes = (totalTime / 60) % 60;
    int hours = totalTime / 3600;
    
    cell.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];

    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = [activityHistoryArray objectAtIndex:indexPath.row];
    TrackerViewController *controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Tracker"];
    controller.dataDict = dict;
    [self.navigationController pushViewController:controller animated:YES];
}

@end
