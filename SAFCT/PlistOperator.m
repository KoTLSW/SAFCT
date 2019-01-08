//
//  PlistOperator.m
//  Framework
//
//  Created by Robin on 2018/11/13.
//  Copyright © 2018年 RobinCode. All rights reserved.
//

#import "PlistOperator.h"

@implementation PlistOperator

-(void)setPlistValue:(NSString*)value forKey:(NSString*)key{
    
     NSString *filePath = @"/Users/piaoxu/Library/Atlas/Configs/Reference.plist";
    
     NSFileManager *manager = [NSFileManager defaultManager];
     
     if (![manager fileExistsAtPath:filePath]) {
          //ShowAlert
          return;
     }
     NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:filePath];
     
     [dic setValue:value forKey:key];
     
     if([dic writeToFile:filePath atomically:YES]){
          NSLog(@"Write to file successfully");
         
     }else{
          NSLog(@"Write to file fail");
     }
}

-(NSString *)readValueForKey:(NSString *)key
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/Users/piaoxu/Library/Atlas/Configs/Reference.plist"];
    
    return [dictionary objectForKey:key];
}

@end
