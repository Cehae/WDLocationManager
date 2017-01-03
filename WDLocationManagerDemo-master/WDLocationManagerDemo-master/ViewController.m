//
//  ViewController.m
//  WDLocationManagerDemo-master
//
//  Created by huylens on 17/1/3.
//  Copyright © 2017年 WDD. All rights reserved.
//

#import "ViewController.h"
#import "WDLocationManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    [[WDLocationManager sharedInstance] getCurrentLocation:^(CLLocation *currentLocation, CLLocationCoordinate2D currentCoordinate2D, CLPlacemark *placemark, NSString *currentLocationStr, NSString *error) {
        
        NSLog(@"addressDictionary - %@ currentLocationStr - %@ error - %@",placemark.addressDictionary,currentLocationStr,error);
        
    }];
}

@end
