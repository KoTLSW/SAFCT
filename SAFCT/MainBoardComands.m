//
//  MainBoardComands.m
//  BCM
//
//  Created by Robin on 2018/9/18.
//  Copyright © 2018年 RobinCode. All rights reserved.


#import "MainBoardComands.h"

static MainBoardComands *singleTeon = nil;
@implementation MainBoardComands

+(instancetype)shareInstance{
     if (singleTeon == nil) {
          singleTeon = [[self alloc] init];
          [singleTeon parseSelf];
     }
     return singleTeon;
}

-(void)parseSelf{

     NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:@"/Users/gdlocal/Library/Atlas/Resources/MainComands.plist"];
     [singleTeon setValuesForKeysWithDictionary:dic];
     

}

@end
