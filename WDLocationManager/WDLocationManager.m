//
//  WDLocationManager.m
//  LocationTest
//
//  Created by huylens on 16/12/20.
//  Copyright © 2016年 WDD. All rights reserved.
//  GutHub:https://github.com/Cehae/WDLocationManager

#import "WDLocationManager.h"
#import <UIKit/UIKit.h>

#define isiOS(version) ([[UIDevice currentDevice].systemVersion floatValue] >= version)

@interface WDLocationManager()<CLLocationManagerDelegate>
// 位置管理者
@property (nonatomic, strong) CLLocationManager *locationM;
// geo编码
@property (nonatomic, strong) CLGeocoder *geoCoder;
// 定位结果回调
@property (nonatomic, copy) ResultBlock resultBlock;
// 错误信息
@property (nonatomic, copy) NSString * error;


@end
@implementation WDLocationManager

static WDLocationManager * _instance = nil;

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WDLocationManager *)sharedInstance
{
    if (_instance == nil) {
        _instance = [[self alloc] init];
    }
    return _instance;
}

#pragma mark -懒加载
-(CLLocationManager *)locationM
{
    if (!_locationM) {
        _locationM = [[CLLocationManager alloc] init];
        //请求定位权限
        //判断是否 iOS 8
        if(isiOS(8.0)) {
            // 获取info.plist文件信息
            NSDictionary *dic = [[NSBundle mainBundle] infoDictionary];
        
            // 获取前后台定位描述
            NSString *alwaysStr = [dic valueForKey:@"NSLocationAlwaysUsageDescription"];
            // 获取前台定位描述
            NSString *whenInUseStr = [dic valueForKey:@"NSLocationWhenInUseUsageDescription"];
            
            if (alwaysStr.length > 0)
            {
                [_locationM requestAlwaysAuthorization]; //请求永久授权
            }
            else if(whenInUseStr.length > 0)
            {
                [_locationM requestWhenInUseAuthorization]; //请求使用中授权
            }else
            {
                NSLog(@"在iOS8.0之后定位,请在info.plist文件中配置NSLocationAlwaysUsageDescription 请求前后台授权 或者 NSLocationWhenInUseUsageDescription 请求前台授权");
            }
            
            // 判断iOS9.0 兼容iOS9.0前台授权模式下的后台获取位置(会出现蓝条)
            if (isiOS(9.0)) {
                // 获取后台模式数组
                NSArray *backModes = [dic valueForKey:@"UIBackgroundModes"];
                // 判断后台模式中是否包含位置更新服务
                if ([backModes containsObject:@"location"])
                {
                    _locationM.allowsBackgroundLocationUpdates = YES;
                }
            }
        }
        _locationM.delegate = self;
        
        //设置定位精确度 可以在此做一些定位相关的设置
        [_locationM setDesiredAccuracy:kCLLocationAccuracyBest];
        
    }
    return _locationM;
}

-(CLGeocoder *)geoCoder
{
    if (_geoCoder == nil) {
        _geoCoder = [[CLGeocoder alloc] init];
    }
    return _geoCoder;
}


// 获取当前位置
- (void)getCurrentLocation:(ResultBlock)block
{
    // 记录代码块
    self.resultBlock = block;
    
    [self.locationM startUpdatingLocation];
}



#pragma mark - CLLocationManagerDelegate
/**
 *  获取到用户位置之后调用
 *
 *  @param manager   位置管理者
 *  @param locations 位置数组
 */
-(void)locationManager:(CLLocationManager *)manager
    didUpdateLocations:(NSArray *)locations
{
    
    if (locations && locations.count) {
    [manager stopUpdatingLocation];

    // 获取到位置信息后,再进行地理编码
    CLLocation * lastLocation = locations.lastObject;
        
    [self.geoCoder reverseGeocodeLocation:lastLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (placemarks.count > 0) {
            
            CLPlacemark * firstPlacemark = placemarks.firstObject;
            //省:
            NSString *sheng = firstPlacemark.addressDictionary[@"State"];
            //城:
            NSString *city = firstPlacemark.addressDictionary[@"City"];
            
            NSString * locationStr = [NSString stringWithFormat:@"%@%@%@",firstPlacemark.country,sheng,city];
            
            !self.resultBlock?:self.resultBlock(lastLocation,lastLocation.coordinate,firstPlacemark,locationStr ,nil);
            
        }else{
            
            !self.resultBlock?:self.resultBlock(lastLocation,lastLocation.coordinate,nil,nil ,@"编码信息错误");
        }
        
           }];
    
       }
}

/**
 定位失败

 @param manager 位置管理者
 @param error 错误信息
 */
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(nonnull NSError *)error
{

    //拒绝原因:1定位服务关闭2定位服务开启但没有权限
    if ([error code] == kCLErrorDenied)
    {
        !self.resultBlock?:self.resultBlock(nil,kCLLocationCoordinate2DInvalid,nil,nil,self.error);
    }
    //网络原因
    if ([error code] == kCLErrorNetwork) {
        
        !self.resultBlock?:self.resultBlock(nil,kCLLocationCoordinate2DInvalid,nil,nil,@"因网络原因无法获得位置信息,请手动设置");
    }
    //未知错误:
    if ([error code] == kCLErrorLocationUnknown)
    {
        !self.resultBlock?:self.resultBlock(nil,kCLLocationCoordinate2DInvalid,nil,nil,@"未知错误");
    }

}



/**
 *  当用户授权状态发生变化时调用
 */
-(void)locationManager:(nonnull CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
            // 用户还未决定
        case kCLAuthorizationStatusNotDetermined:
        {
            NSLog(@"用户未决定是否授权定位权限");
            break;
        }
            //定位失败
            
            // 定位关闭时和对此APP授权为never时调用
        case kCLAuthorizationStatusDenied:
        {
            // 定位是否可用（是否支持定位或者定位是否开启）
            if([CLLocationManager locationServicesEnabled])
            {
                self.error = @"定位服务开启，但没有定位权限";
                
            }else
            {
                self.error = @"定位服务未开启,为了提供更多服务请设置:设置>隐私>开启定位";
            }
            break;
        }
            // 访问受限
        case kCLAuthorizationStatusRestricted:
        {
            self.error = @"访问受限";
            break;
        }

            //可以定位
            
            // 获取前后台定位授权
        case kCLAuthorizationStatusAuthorizedAlways:
        {
            NSLog(@"获取前后台定位授权");
            break;
        }
            // 获得前台定位授权
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            NSLog(@"获得前台定位授权");
            break;
        }
        default:
            break;
    }
    
}


@end
