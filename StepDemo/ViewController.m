//
//  ViewController.m
//  StepDemo
//
//  Created by iosOne on 16/5/13.
//  Copyright © 2016年 iosOne. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>

#define maxCount 15//一秒钟最多刷新的次数
#define KDEVICEHEIGHT ([UIScreen mainScreen].bounds.size.height)
#define KDEVICEWIDTH ([UIScreen mainScreen].bounds.size.width)
#define A_WIDTH ([UIScreen mainScreen].bounds.size.width/320)
#define B_HIGHT ([UIScreen mainScreen].bounds.size.height/568)

@interface ViewController ()

@property(nonatomic,strong)HKHealthStore *healthStore;
@property(nonatomic,assign)CGFloat totalSteps;
@property(nonatomic,strong)NSTimer *timer;

@property(nonatomic,strong)CAShapeLayer *myLayer;
@property(nonatomic,strong)CATextLayer *textLayer;
@property(nonatomic,strong)UIView *view1;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configShowView];
    if (![HKHealthStore isHealthDataAvailable])
    {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示:" message:@"当前设备不支持从健康应用获取步数" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alertC dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertC addAction:cancelAction];
        [self presentViewController:alertC animated:YES completion:^{
        }];

    }
    else
    {
        self.healthStore = [[HKHealthStore alloc]init];
        HKObjectType *stepCount = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        NSSet *healthSet = [NSSet setWithObjects:stepCount, nil];
        [self.healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
            if (success)
            {
                NSLog(@"获取步数权限成功");
                //获取步数后我们调用获取步数的方法
                [self readStepsCount];
            }
            else
            {
                NSLog(@"获取步数权限失败");
            }
        }];
        
    }

}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}
-(void)configShowView
{
    _view1 = [[UIView alloc]initWithFrame:CGRectMake(20*A_WIDTH, 90*B_HIGHT, KDEVICEWIDTH- 40*A_WIDTH,240*B_HIGHT)];
    _view1.backgroundColor = [UIColor whiteColor];
    _view1.layer.cornerRadius = 5;
    _view1.layer.masksToBounds = YES;
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.bounds = CGRectMake(0, 0, 200*B_HIGHT, 200*B_HIGHT);
    layer.position = CGPointMake(_view1.frame.size.width/2, 120*B_HIGHT);
    layer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(100*B_HIGHT, 100*B_HIGHT)
                                                radius:100*B_HIGHT
                                            startAngle:-(M_PI+M_PI_4)
                                              endAngle:M_PI_4
                                             clockwise:YES].CGPath;
    layer.strokeStart = 0;
    layer.strokeEnd = 1;
    layer.strokeColor = [UIColor grayColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.lineWidth = 10;
    layer.lineCap = @"round";
    [_view1.layer addSublayer:layer];
    
    _myLayer = [CAShapeLayer layer];
    _myLayer.bounds = CGRectMake(0, 0, 200*B_HIGHT, 200*B_HIGHT);
    _myLayer.position = CGPointMake(_view1.frame.size.width/2, 120*B_HIGHT);
    _myLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(100*B_HIGHT, 100*B_HIGHT)
                                                   radius:100*B_HIGHT
                                               startAngle:-(M_PI+M_PI_4)
                                                 endAngle:M_PI_4
                                                clockwise:YES].CGPath;    _myLayer.strokeStart = 0;
    _myLayer.strokeEnd = 0;
    _myLayer.strokeColor = [self colorWithHex:0x00b9bb alpha:1].CGColor;
    _myLayer.fillColor = [UIColor clearColor].CGColor;
    _myLayer.lineWidth = 10;
    _myLayer.lineCap = @"round";
    [_view1.layer addSublayer:_myLayer];
    
    CGSize strSize = [@"122" sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:25]}];
    _textLayer= [CATextLayer layer];
    _textLayer.bounds = CGRectMake(0, 0, strSize.width, strSize.height);
    _textLayer.position = CGPointMake(_view1.frame.size.width/2, 120*B_HIGHT);
    _textLayer.string = @"122";
    _textLayer.fontSize = 25;
    _textLayer.foregroundColor = [UIColor blackColor].CGColor;
    [_view1.layer addSublayer:_textLayer];
    
    [self.view addSubview:_view1];
}

//获取当天步数
-(void)readStepsCount
{
    NSCalendar *calender = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *components = [calender components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    NSDate *startDate = [calender dateFromComponents:components];
    NSDate *endDate = [calender dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    HKSampleQuery *query = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        if (!results)
        {
            abort();
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            for (HKQuantitySample *sample in results)
            {
                HKQuantity *quantity = sample.quantity;
//                NSString *stepStr = (NSString *)quantity;
                double d = [quantity doubleValueForUnit:[HKUnit unitFromString:@"count"]];
                _totalSteps = _totalSteps +d;
            }
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateLayer:) userInfo:nil repeats:YES];
        });
    }];
    [self.healthStore executeQuery:query];
}


-(void)updateLayer:(NSTimer *)timer
{
    static int i =0;
    i++;
    _myLayer.strokeEnd = 1.0/maxCount*i;
    [_myLayer setNeedsDisplay];
    
    CGSize strSize = [[NSString stringWithFormat:@"%.0f",_totalSteps/maxCount*i] sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:25]}];
    _textLayer.bounds = CGRectMake(0, 0, strSize.width+2, strSize.height+2);
    _textLayer.string =[NSString stringWithFormat:@"%.0f",_totalSteps/maxCount*i];
    if ( i == maxCount)
    {
        i=0;
        [_timer invalidate];
        _timer = nil;
    }
}



- (UIColor *)colorWithHex:(long)hexColor alpha:(float)opacity
{
    float red = ((float)((hexColor & 0xFF0000) >> 16))/255.0;
    float green = ((float)((hexColor & 0xFF00) >> 8))/255.0;
    float blue = ((float)(hexColor & 0xFF))/255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:opacity];
}
@end
