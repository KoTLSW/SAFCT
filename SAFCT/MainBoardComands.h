//
//  MainBoardComands.h
//  BCM
//
//  Created by Robin on 2018/9/18.
//  Copyright © 2018年 RobinCode. All rights reserved.
//

#import <Foundation/Foundation.h>

//主控制板上的气缸进出的命令和读取温湿度的命令

@interface MainBoardComands : NSObject

//操作主控板，串口发送命令
@property(nonatomic,strong) NSString * reset_ctrlboard;

@property(nonatomic,strong) NSString * check_ctrlboard;

@property(nonatomic,strong) NSString * ctrl_turn_black_card;

@property(nonatomic,strong) NSString * ctrl_turn_card_off;


//操控测试板，网口发送命令
@property(nonatomic,strong) NSString *reset_measureboard;

@property(nonatomic,strong) NSString *check_measureboard;




/*rfix的校准的时候的 MAX -Min 不能大于这个值*/
@property(nonatomic,strong) NSString *rfixDeltValueLimit;
/*rfix的校准的时候的 MAX -Min 不能大于这个值*/
@property(nonatomic,strong) NSString *rfixDeltPercentLimit;

@property(nonatomic,strong) NSString *fixtureID;

+(instancetype)shareInstance;

@end
