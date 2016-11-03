//
//  EDKManager.h
//  EasyDataKit
//
//  Copyright © 2016年 hawk. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EDKEntity;

@interface EDKManager : NSObject

+ (instancetype)sharedInstance;

- (NSString *)getPkColumn:(EDKEntity *)entity;

- (id)saveObject:(EDKEntity *)entity;

- (NSArray *)queryObjects:(EDKEntity *)entity;

- (void)deleteObjects:(EDKEntity *)entity;

- (void)updateObjects:(EDKEntity *)entity;

@end
