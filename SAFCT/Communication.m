/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 */

#import "Communication.h"
#import "SerialPortTool.h"
#import "WDSyncSocket.h"
#import "Function.h"
#import "MainBoardComands.h"
#import "PlistOperator.h"
#import "Folder.h"
#import "GetTimeDay.h"




/*----global----*/
#define KCommand   @"Command"
#define KDelay     @"Delay"
#define KDevice    @"Device"
#define KDebug     @"Debug"
#define KTestName  @"TestName"
#define KChoose    @"Choose"
#define KSN        @"SN"
#define KIsReady   @"Ready"
#define CountKey   @"Count"
#define KIsOK      @"IsOK"
#define KSuffix    @"Suffix"

@interface Communication()

/*
   以下是所有的公共控制
*/
@property(nonatomic,strong)SerialPortTool   * mainBoardPort;
@property(nonatomic,strong)SerialPortTool   * pressBoardPort;
@property(nonatomic,strong)Function         * function;
@property(nonatomic,strong)NSString         * mainBoardPortPath;
@property(nonatomic,strong)NSString         * pressBoardPortPath;
@property(nonatomic,strong)NSMutableDictionary * configParams;
@property(nonatomic,strong)NSMutableDictionary * valueDictionary;
@property(nonatomic,strong)PlistOperator       * plistOperator;
@property(nonatomic,assign)NSInteger unitCounts;     //多少通道
@property(nonatomic,strong)Folder           * fold;
@property(nonatomic,strong)GetTimeDay       * timeDay;


//私有的IP地址
@property(nonatomic,strong)WDSyncSocket     * wdSyncSocket;
@property(nonatomic,strong)NSString         * IPString;
@property(nonatomic,strong)NSString         * PortString;
@property(nonatomic,strong)NSString         * debug;
@property(nonatomic,strong)NSString         * SN;
@property(nonatomic,strong)NSString         * DataPath;
@property(nonatomic,assign)BOOL               TestResult;     //测试的结果


@end



@implementation Communication

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        // enter initialization code here
    }

    return self;
}



-(NSMutableDictionary *)valueDictionary
{
    if (_valueDictionary == nil) {
        
        _valueDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return _valueDictionary;
}

-(SerialPortTool *)mainBoardPort
{
    if (_mainBoardPort == nil) {
        
        _mainBoardPort = [[SerialPortTool alloc]init];
    }

    return _mainBoardPort;
}


-(SerialPortTool *)pressBoardPort
{
    if (_pressBoardPort == nil) {
        
        _pressBoardPort = [[SerialPortTool alloc] init];
    }

    return _pressBoardPort;
}

-(WDSyncSocket *)wdSyncSocket{
  
    if (_wdSyncSocket == nil) {
        
        _wdSyncSocket = [[WDSyncSocket alloc] init];
    }

    return _wdSyncSocket;
}

-(PlistOperator *)plistOperator
{
    if (_plistOperator == nil)
    {
        _plistOperator=[[PlistOperator alloc]init];
    }
    return _plistOperator;
}

-(Folder *)fold{
    
    if (_fold == nil) {
        
        _fold = [Folder shareInstance];
    }
    
    return _fold;
    
}

-(GetTimeDay *)timeDay{
    
    if (_timeDay == nil) {
        
        _timeDay = [GetTimeDay shareInstance];
    }
    
    return _timeDay;
    
}




// For plugins that implement this method, Atlas will log the returned CTVersion
// on plugin launch, otherwise Atlas will log the version info of the bundle
// containing the plugin.
 - (CTVersion *)version
 {
     return [[CTVersion alloc] initWithVersion:@"1"
                           projectBuildVersion:@"1"
                              shortDescription:@"My short description"];
 }



- (BOOL)setupWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    CTLog(CTLOG_LEVEL_INFO,@"\n---------初始化---------\n");
    //处理方法
    self.function = [[Function alloc] init];
    
    //设置Uart参数
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:context.parameters];
    NSString  * fixtureUart = context.parameters[@"fixtureUart"];
    NSString  * pressUart   = context.parameters[@"pressUart"];
    NSString  * debug       = context.parameters[@"debug"];
    NSString  * ipStr       = context.parameters[@"ip"];
    NSString  * portStr     = context.parameters[@"port"];
    NSString  * path        = context.parameters[@"DataPath"];
    
    //设置串口参数
    [parameters setObject:@"@_@\r\n" forKey:@"reponseEndMark"];
    [parameters setObject:@"1.0" forKey:@"timeout"];
    self.configParams = parameters;
    
    
    //设置
    self.mainBoardPortPath  = fixtureUart;
    self.pressBoardPortPath = pressUart;
    self.debug              = debug;
    self.IPString           = ipStr;
    self.PortString         = portStr;
    self.DataPath           = [NSString stringWithFormat:@"%@/%@/",path,[self.timeDay getCurrentDay]];
    self.TestResult         = YES;
    self.unitCounts         = [context.parameters[@"unitCounts"] intValue];
    
    CTLog(CTLOG_LEVEL_ALERT,@"\n---------结束---------\n");
    
    //测试开始前，重置所有的参数
    [self resetParameters];
    return YES;
}



#pragma mark----------------测试teardown
-(BOOL)teardownWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    //释放串口
    if (_mainBoardPort)
    {
        [_mainBoardPort close];
        _mainBoardPort=nil;
    }
    
    //释放网口
    if (_wdSyncSocket) {
        
        [_wdSyncSocket disConnectToServer];
    }
    
    CTLog(CTLOG_LEVEL_INFO,@"=============调用teardown的方法");
    
    return YES;
}



- (CTCommandCollection *)commmandDescriptors
{
    // Collection contains descriptions of all the commands exposed by a plugin
    CTCommandCollection *collection = [CTCommandCollection new];
    
    
    
//    CTCommandDescriptor *command = [[CTCommandDescriptor alloc] initWithName:@"OpenUart" selector:@selector(OpenUart:) description:@"Open Uart"];
//    [collection addCommand:command];

    //传递SN
     CTCommandDescriptor * command =  [[CTCommandDescriptor alloc] initWithName:@"GetSN" selector:@selector(GetSN:) description:@"Get SN"];
    [collection addCommand:command];
    
    
    //打开网口通信
    command =  [[CTCommandDescriptor alloc] initWithName:@"OpenSocket" selector:@selector(OpenSocket:) description:@"Open Socket"];
     [collection addCommand:command];
    
    //读取串口数据
    command = [[CTCommandDescriptor alloc] initWithName:@"ReadSerailPort" selector:@selector(ReadSerailPort:) description:@"ReadSerailPort"];
     [collection addCommand:command];
    
    
    //读取网口数据
    command = [[CTCommandDescriptor alloc] initWithName:@"LanSendCommand" selector:@selector(LanSendCommand:) description:@"LanSendCommand"];
    [collection addCommand:command];
    
    //读取存储的数据
    command = [[CTCommandDescriptor alloc] initWithName:@"GetFromDictionary" selector:@selector(GetFromDictionary:) description:@"GetFromDictionary"];
    [collection addCommand:command];
    
    //开始测试waitforStart
    command = [[CTCommandDescriptor alloc] initWithName:@"waitforRealStart" selector:@selector(waitforRealStart:) description:@"waitforRealStart"];
    [collection addCommand:command];
    
    //测试结束waitforRealFinsh
    command = [[CTCommandDescriptor alloc] initWithName:@"waitforRealFinsh" selector:@selector(waitforRealFinsh:) description:@"waitforRealFinsh"];
    [collection addCommand:command];
    
    
    //获取测试结果
    command = [[CTCommandDescriptor alloc] initWithName:@"responseTestResult" selector:@selector(responseTestResult:) description:@"responseTestResult"];
    [collection addCommand:command];
    
    
    return collection;
}



#pragma mark-------waitforRealStart
-(void)waitforRealStart:(CTTestContext *)context{

    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        //debug模式开始测试
        if ([self.debug isEqualToString:@"YES"]) {
            context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            CTLog(CTLOG_LEVEL_ALERT,@"self.debug=%@,OpenUart Success",self.debug);
            
            if (self.mainBoardPortPath.length>2 && self.pressBoardPortPath.length >2) {
                while (1) {   //主控板准备好
                    sleep(1.0);
                    [self.plistOperator setPlistValue:@"YES" forKey:KIsReady];
                    NSString  * readStr = [self.plistOperator readValueForKey:KIsReady];
                    CTLog(CTLOG_LEVEL_INFO,@"1up中打印readStr的值=%@",readStr);
                    break;
                }
            }else{
                while (1) {
                    sleep(1.0);
                    NSString  * readStr = [self.plistOperator readValueForKey:KIsReady];
                    if ([readStr isEqualToString:@"YES"]) {
                        CTLog(CTLOG_LEVEL_INFO,@"主控板动作到位，测试板开始测试,%@",readStr);
                        break;
                    }else{
                        CTLog(CTLOG_LEVEL_INFO,@"测试板还不能开始，等待主板子发送命令");
                    }
                }
            }
            
            return CTRecordStatusPass;
        }
        
        //Unit1中执行控制板的动作
        if (self.mainBoardPortPath.length>2 && self.pressBoardPortPath.length >2) {
            while (1) {
                BOOL  isMainPortConnect  = [self.mainBoardPort openSerialPortWithPath:self.mainBoardPortPath congfig:self.configParams];
                if (isMainPortConnect) {
                        CTLog(CTLOG_LEVEL_ALERT,@"ControllerBoard Connect Success!");
                        //复位控制板
                        NSString  * response=[self.mainBoardPort sendCommand:[MainBoardComands shareInstance].reset_ctrlboard];
                        CTLog(CTLOG_LEVEL_ALERT,@"response = %@",response);
                    
                        //检测板子是否准备好
                        while (1) {
                         [NSThread sleepForTimeInterval:0.5];
                        
                          if ([[self.mainBoardPort sendCommand:[MainBoardComands shareInstance].check_ctrlboard]
                              containsString:@"OK@_@\r\n"]) {
                              
                              [self.plistOperator setPlistValue:@"YES" forKey:KIsReady];
                              break;
                            }
                        }
                }
                else{
                
                    if (!isMainPortConnect)
                    {
                        CTLog(CTLOG_LEVEL_INFO, @"主控制板连接失败！");
                    }
                }
            }
            
        }
        //其它的Unit都在等待过程中
        else
        {
            while (1) {
                
                sleep(1.0);
                
                NSString  * readStr = [self.plistOperator readValueForKey:KIsReady];
                
                if ([readStr isEqualToString:@"YES"]) {
                    
                    CTLog(CTLOG_LEVEL_INFO,@"主控板动作到位，测试板开始测试,%@",readStr);
                    break;
                }else{
                    CTLog(CTLOG_LEVEL_INFO,@"测试板还不能开始，等待主板子发送命令");
                }
            }
        }
        
        return CTRecordStatusPass;
    }];
}



#pragma mark---------waitforRealFinsh 测试结束
-(void)waitforRealFinsh:(CTTestContext *)context
{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        if ([self.debug isEqualToString:@"YES"]) {
            
            return CTRecordStatusPass;
        }
        //等到所有的测试结束之后才才开始复位控制板
        
        NSInteger finishCount;
        if (self.mainBoardPortPath.length > 2){ //第一个unit,等待第其他的unit完成，然后发送公共的命令
            
            while (1) {
                sleep(1.0);
                finishCount = [[self.plistOperator readValueForKey:CountKey] integerValue];
                
               if (finishCount == self.unitCounts - 1) {
                    
                    if (![self.debug isEqualToString:@"YES"]) {
                        
                        //发送ctrl_turn_black_card
                        NSString * response = [self.mainBoardPort sendCommand:[NSString stringWithFormat:@"%@\r\n",[MainBoardComands shareInstance].ctrl_turn_black_card ]];
                        
                        if (![response containsString:@"OK@_@\r\n"]) {
                            CTLog(CTLOG_LEVEL_ERR,@"控制板发送:ctrl_turn_black_card异常,response:%@",response);
                            return CTRecordStatusFail;
                        }
                        //发送ctrl_turn_card_off
                        response = [self.mainBoardPort sendCommand:[NSString stringWithFormat:@"%@\r\n",[MainBoardComands shareInstance].ctrl_turn_card_off ]];
                        
                        
                        if (![response containsString:@"OK@_@\r\n"]) {
                            CTLog(CTLOG_LEVEL_ERR,@"控制板发送:ctrl_turn_card_off异常,response:%@",response);
                            return CTRecordStatusFail;
                        }
                    }
                    CTLog(CTLOG_LEVEL_INFO,@"主板子所有的测试都已经结束，而且其他unit也完成了，关闭了USB");
                    finishCount = finishCount + 1;
                    
                    [self.plistOperator setPlistValue:[NSString stringWithFormat:@"%ld",finishCount] forKey:CountKey];
                    
                    break;
                    
                }else{
                    
                    CTLog(CTLOG_LEVEL_INFO,@"主板子所有的测试还未结束，等待其他unit的完成");
              }
                
          }
            
            
        }
        else{
            
            finishCount = [[self.plistOperator readValueForKey:CountKey] integerValue];
            finishCount = finishCount + 1;
            [self.plistOperator setPlistValue:[NSString stringWithFormat:@"%ld",finishCount] forKey:CountKey];
            while (1) {
                sleep(1.0);
                finishCount = [[self.plistOperator readValueForKey:CountKey] integerValue];
                if (finishCount == self.unitCounts) {
                    CTLog(CTLOG_LEVEL_INFO,@"从板子所有的测试都已经结束，其他unit都已经完成");
                    break;
                }else{
                    CTLog(CTLOG_LEVEL_INFO,@"从板子所有的测试还未结束，等待其他unit的完成");
                }
            }
        }
        return CTRecordStatusPass;
    }];
    
    
}


#pragma mark-------获取SN
-(void)GetSN:(CTTestContext *)context{

    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        self.SN = context.parameters[KSN];
        CTLog(CTLOG_LEVEL_INFO,@"GetSN:context.output = %@",self.SN);
        
        self.DataPath = [NSString stringWithFormat:@"%@%@",self.DataPath,self.SN];
        //生成文件夹的路径
        if ([self.fold Folder_Creat:self.DataPath]) {
            
            CTLog(CTLOG_LEVEL_ALERT,@"文件夹创建成功=%@",self.DataPath);
        }
        
        return CTRecordStatusPass;
    }];

}


#pragma mark--------读取port数据
-(void)ReadSerailPort:(CTTestContext *)context{
    
    if ([context.parameters[KDevice] containsString:@"FIXPressDevice"]) {
        
        [self sendCommandWithDevice:self.pressBoardPort command:context.parameters[KCommand] context:context];
    }else{
    
        [self sendCommandWithDevice:self.mainBoardPort command:context.parameters[KCommand] context:context];
    }
}


#pragma mark-------OpenSocket
-(void)OpenSocket:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {

        //debug模式
        if ([self.debug isEqualToString:@"YES"]) {
            context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            CTLog(CTLOG_LEVEL_ALERT,@"self.debug=%@,OpenSocket Success",self.debug);
            return CTRecordStatusPass;
        }
        
        
        while (1) {
            
            BOOL  isSocketConnect  = [self.wdSyncSocket connectToServerIPAddress:self.IPString port:[self.PortString intValue] timeout:1.0 terminator:@"OK@_@" dataTerminator:@"DA@_@"];
            
            if (isSocketConnect) {
                 CTLog(CTLOG_LEVEL_ALERT,@"网络连接成功！");
                
                 //复位测试板子
                 NSString * resetCommand = [self.wdSyncSocket sendCommand:[NSString stringWithFormat:@"%@\r\n",[MainBoardComands shareInstance].reset_measureboard] timeout:1.0];
                
                if ([resetCommand containsString:@"OK@_@\r\n"]) {
                    
                      CTLog(CTLOG_LEVEL_ALERT,@"测试板复位成功！");
                }
                else
                {
                       CTLog(CTLOG_LEVEL_ALERT,@"测试板复位失败！");
                }
                
                //检测测试板是否Ready
                NSString * readyCommand = [self.wdSyncSocket sendCommand:[NSString stringWithFormat:@"%@\r\n",[MainBoardComands shareInstance].check_measureboard] timeout:1.0];
                if ([readyCommand containsString:@"OK@_@\r\n"]) {
                    
                    CTLog(CTLOG_LEVEL_ALERT,@"测试板已经准备OK！");
                    
                    break;
                }
                else
                {
                    CTLog(CTLOG_LEVEL_ALERT,@"测试板没有准备好！");
                }
            }
            else{
                    CTLog(CTLOG_LEVEL_ALERT,@"网络连接失败！");
            }
         }
        
        return CTRecordStatusPass;
    }];
}



#pragma mark-------LanSendCommand
-(void)LanSendCommand:(CTTestContext *)context{
    
    float delay = [context.parameters[KDelay] floatValue];
    NSString * testName      =  context.parameters[KTestName];
    NSString * command       =  context.parameters[KCommand];
    NSString * suffix        =  context.parameters[KSuffix];
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        if ([self.debug isEqualToString:@"YES"]) {
            context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            //将数据存储到plist文件中
            if ([context.parameters[KChoose] isEqualToString:@"WriteToPlist"]) {
                
                CTLog(CTLOG_LEVEL_INFO,@"Debug:testName = %@;KChoose=%@;WriteToPlist",testName,context.parameters[KChoose]);
            }
            //将数据存储到字典中
            if ([context.parameters[KChoose] isEqualToString:@"SaveToDictionary"]) {
                CTLog(CTLOG_LEVEL_INFO,@"testName = %@;KType=%@;SaveToDictionary",testName,context.parameters[KChoose]);
                NSString  * backStr = [NSString stringWithFormat:@"%@ 50 10 5 11 60 18DA@_@\r\n",command];
                NSString  * simpleResponse = [self.function rangeofString:backStr Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:@"DA@_@\r\n"];
                CTLog(CTLOG_LEVEL_INFO,@"testName = %@,simpleResponse = %@",testName,simpleResponse);
                NSArray   *  arr =[simpleResponse componentsSeparatedByString:@" "];
                
                CTLog(CTLOG_LEVEL_INFO,@"arr:%lu",(unsigned long)[arr count]);
                [self.valueDictionary setObject:arr[0] forKey:[NSString stringWithFormat:@"%@_average",testName]];
                [self.valueDictionary setObject:arr[1] forKey:[NSString stringWithFormat:@"%@_rms",testName]];
                [self.valueDictionary setObject:arr[2] forKey:[NSString stringWithFormat:@"%@_std",testName]];
                [self.valueDictionary setObject:arr[3] forKey:[NSString stringWithFormat:@"%@_vpp",testName]];
                [self.valueDictionary setObject:arr[4] forKey:[NSString stringWithFormat:@"%@_max",testName]];
                [self.valueDictionary setObject:arr[5] forKey:[NSString stringWithFormat:@"%@_min",testName]];
                CTLog(CTLOG_LEVEL_INFO,@"Debug:value insert into Dictionary:%@",self.valueDictionary);
            }
            return CTRecordStatusPass;
        }
        
        
        //正式发送数据
        NSString *response=[self.wdSyncSocket sendCommand:context.parameters[KCommand] timeout:1];
        usleep(delay*1000);
        CTLog(CTLOG_LEVEL_INFO,@"socket command:%@  response in Plugin:%@",context.parameters[KCommand],response);
        
        if([response containsString:@"DA@_@"]){
            
            
            //将数据存储到txt文件中
            if ([context.parameters[KChoose] isEqualToString:@"WriteToPlist"]) {
                
                CTLog(CTLOG_LEVEL_INFO,@"testName = %@;KType=%@;WriteToPlist",testName,context.parameters[KChoose]);
                
                [response writeToFile:[NSString stringWithFormat:@"%@/%@_%@.txt",self.DataPath,testName,self.SN] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
            
            //将数据存储到字典中
            else if ([context.parameters[KChoose] isEqualToString:@"SaveToDictionary"]) {
                
                //OFF_Lisa_Get_Stats_Data(0x01) MAX MIN Vpp STDDA@_@\r\n
                NSString  * simpleResponse = [self.function rangeofString:response Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:suffix];
                
                
                CTLog(CTLOG_LEVEL_INFO,@"testName = %@;command= %@, simpleResponse:%@",testName,command,simpleResponse);
                
                NSArray   *  arr =[simpleResponse componentsSeparatedByString:@" "];
                [self.valueDictionary setObject:arr[0] forKey:[NSString stringWithFormat:@"%@_average",testName]];
                [self.valueDictionary setObject:arr[1] forKey:[NSString stringWithFormat:@"%@_rms",testName]];
                [self.valueDictionary setObject:arr[2] forKey:[NSString stringWithFormat:@"%@_std",testName]];
                [self.valueDictionary setObject:arr[3] forKey:[NSString stringWithFormat:@"%@_vpp",testName]];
                [self.valueDictionary setObject:arr[4] forKey:[NSString stringWithFormat:@"%@_max",testName]];
                [self.valueDictionary setObject:arr[5] forKey:[NSString stringWithFormat:@"%@_min",testName]];
            }
            else{
            
                context.output = [self.function rangeofString:response Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:@" DA@_@\r\n"];
                
                [self GetTestResult:context];
                
                CTLog(CTLOG_LEVEL_INFO,@"返回====数据，以DA@_@结尾:response=%@",response);
            }
        
        }else{
            
            CTLog(CTLOG_LEVEL_INFO,@"返回====数据，以OK@_@结尾:response=%@",response);
        }
        
        return CTRecordStatusPass;
    }];
}



#pragma mark---------GetFromDictionary
-(void)GetFromDictionary:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        if ([self.debug isEqualToString:@"YES"]) {
            
            NSString  * testName = context.parameters[KTestName];
             CTLog(CTLOG_LEVEL_INFO,@"=====================testName = %@",testName);
            context.output = [self.valueDictionary objectForKey:testName];
            CTLog(CTLOG_LEVEL_INFO,@"=====================context.output = %@",context.output);
            //context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            return CTRecordStatusPass;
        }
        
        NSString  * testName = context.parameters[KTestName];
        context.output = [self.valueDictionary objectForKey:testName];
        CTLog(CTLOG_LEVEL_INFO,@"context.output = %@",context.output);
        
        return CTRecordStatusPass;
    }];
    
}



#pragma mark ----Private Function called by self---------

-(void)sendCommandWithDevice:(SerialPortTool*)device command:(NSString*)command context:(CTTestContext*)context{

    float delay = [context.parameters[KDelay] floatValue];
    
    CTLog(CTLOG_LEVEL_INFO,@"command in Plugin:%@,current device:%@",command,device);
    
    /*---- 检查位，有些串口动作需要用相应的字符串判断指令是否执行成功,如果这个数值不为nil,需要做判断 */
    [context runTest:^CTRecordStatus(NSError *__autoreleasing *failureInfo) {
    
        if ([self.debug isEqualToString:@"YES"]) {
            
            CTLog(CTLOG_LEVEL_INFO,@"Debug,sendCommandWithDevice");
            context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            return CTRecordStatusPass;
        }
        
        //所有的串口命令都是由unit1发送
        if (self.mainBoardPortPath.length>2) {
            
            NSString *response;
            if (![self.debug isEqualToString:@"YES"]) {
                response = [device sendCommand:command];
                usleep(delay*1000);
                CTLog(CTLOG_LEVEL_INFO,@"response in Plugin:%@",response);
                context.output = response;
                
                if (![response containsString:@"OK@_@\r\n"]) {
                    
                    CTLog(CTLOG_LEVEL_INFO,@"command =%@,wrong response:%@",command,response);
                }
            }
        
            
            if ([context.parameters[KChoose] isEqualToString:@"waitForControllerFinsh"]) {
                
                 [self.plistOperator  setPlistValue:@"YES" forKey:KIsOK];
            }
            
            return CTRecordStatusPass;

            
        }
        else{ //其它unit直接判断下面的项
            
            if ([context.parameters[KChoose] isEqualToString:@"waitForControllerFinsh"]) {
                
                while (1) {
                    
                    sleep(1.0);
                    
                    if ([[self.plistOperator readValueForKey:KIsOK] isEqualToString:@"YES"]) {
                        
                        //重新设置
                         [self.plistOperator  setPlistValue:@"" forKey:KIsOK];
                        
                         break;
                    }
                }
                
                return CTRecordStatusPass;

                
            }else{
               
                return CTRecordStatusPass;
            }
        }
        
        
        
    }];
}


#pragma mark----------------增加判断测试结果方法
-(void)GetTestResult:(CTTestContext*)context{
    //
    //    [context runTest:^CTRecordStatus(NSError *__autoreleasing *failureInfo) {
    //
    
    CTLog(CTLOG_LEVEL_INFO,@"打印testName:%@,Max=%@,Min=%@",context.parameters[@"testName"],context.parameters[@"testName"],context.parameters[@"Min"]);
    
    if (([context.output floatValue]<[context.parameters[@"Min"] floatValue])||
        ([context.output floatValue]>[context.parameters[@"Max"] floatValue])) {
        
        self.TestResult = NO;
    }
    //        return CTRecordStatusPass;
    //    }];
}



-(void)responseTestResult:(CTTestContext*)context{
    
    [context runTest:^CTRecordStatus(NSError *__autoreleasing *failureInfo) {
        
        if (self.TestResult) { //发送绿灯
            
            [self.mainBoardPort sendCommand:@"LED_Out_Green"];
        }
        else{//发送红灯
            
            [self.mainBoardPort sendCommand:@"LED_Out_Red"];
        }
        return CTRecordStatusPass;
        
    }];
}

#pragma mark-----------resetParameters
-(void)resetParameters{
    
    [self.plistOperator setPlistValue:@"NO" forKey:KIsReady];
    [self.plistOperator  setPlistValue:@"10" forKey:CountKey];
    [self.plistOperator  setPlistValue:@"" forKey:KIsOK];
    CTLog(CTLOG_LEVEL_INFO,@"KIsReady=%@,CountKey=%@",[self.plistOperator readValueForKey:KIsReady],[self.plistOperator readValueForKey:CountKey]);
    
}



@end
