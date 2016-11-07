//
//  EDKTests.m
//  EDKTests
//
//  Copyright © 2016年 陈浩. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EDKEntity.h"

@interface EDKTests : XCTestCase

@end

@implementation EDKTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testAsyncSave {
    // you should call this method first for test query, update and delete
    [self initial];
}

- (void)testQuery {
    EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
    
    // select by id
    id object = [entity queryByPrimaryKey:@"581d2fdb36a4471100e311d6" withColumns:@[@"topicId", @"commentCount", @"topic"]];
    NSLog(@"%@", object);
    
    // relationship query
    EDKEntity *topicEntity = [[EDKEntity alloc] initWithTableName:@"topics" dbName:nil];
    id topic = [topicEntity queryByPrimaryKey:object[@"topic"] withColumns:nil];
    NSLog(@"%@",topic);
    
    // select by where
//    NSArray *objects = [entity queryWithColumns:nil where:@"WHERE commentCount < ? and read = ?" arguments:@[@20, @1]];
//    NSLog(@"%@", objects);

    // select all
//    NSArray *objects = [entity queryAll];
//    NSLog(@"%@", objects);
    
    // select then convert to dictionary
//    EDKEntity *subcribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
//    // select by id
//    id subcribe = [subcribeEntity queryByPrimaryKey:@"56d177a27cb3331100465f72" withColumns:@[@"squarePicture"]];
//    // subcribe is a json string
//    NSData *data = [subcribe[@"squarePicture"] dataUsingEncoding:NSUTF8StringEncoding];
//    NSError *error;
//    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
//    NSLog(@"JSONDict: %@", jsonDict);
}

- (void)testAsyncUpdate {
    EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
    
    // update by id
    [entity updateByPrimaryKey:@"5805905a319a9c1200833660" set:@{@"read": @"0", @"commentCount": @99}];
    // update by where
    [entity updateWithSet:@{@"messageId": @"2333333"} where:@"WHERE commentCount > ?" arguments:@[@50]];
    
    // update by dictionary..
    NSDictionary *square = @{@"lisp": @"blablabla..."};
    EDKEntity *subcribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
    [subcribeEntity updateByPrimaryKey:@"56d177a27cb3331100465f72" set:@{@"squarePicture": square}];

    XCTestExpectation *exp = [self expectationWithDescription:@"wtf?"];
    sleep(1);
    [exp fulfill];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testAsyncDelete {
    EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
    
    // delete by id
    [entity deleteByPrimaryKey:@"5805905a319a9c1200833660"];
    
    // delete by where
    [entity deleteWithWhere:@"WHERE popularity = ?" arguments:@[@"93"]];
    
    // delete all
    [entity deleteAll];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"wtf?"];
    sleep(1);
    [exp fulfill];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}


- (void)initial {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *messagesPath = [bundle pathForResource:@"data" ofType:@"json"];
    NSData *messagesData = [NSData dataWithContentsOfFile:messagesPath];
    NSArray *messages;
    
    NSString *subscribePath = [bundle pathForResource:@"subscribeData" ofType:@"json"];
    NSData *subscribeData = [NSData dataWithContentsOfFile:subscribePath];
    NSDictionary *subscribe;
    
    if (messagesData) {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:messagesData options:NSJSONReadingAllowFragments error:nil];
        messages = dictionary[@"data"];
    }
    
    if (subscribeData) {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:subscribeData options:NSJSONReadingAllowFragments error:nil];
        subscribe = dictionary[@"data"];
    }

    for (int i = 0; i < messages.count; i++) {
        NSDictionary *message = [messages objectAtIndex:i];
        NSDictionary *topicInfo = message[@"topic"];
        EDKEntity *topicEntity = [[EDKEntity alloc] initWithTableName:@"topics" dbName:nil];
        id topicRowId = [topicEntity saveData:topicInfo primaryColumn:nil relationShip:nil];
        
        EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
        [entity saveData:message primaryColumn:@"id" relationShip:@{@"topic": topicRowId}];
    }
    
    // ex. how to add a field
    NSMutableDictionary *subcribeInfo = [[NSMutableDictionary alloc] initWithDictionary:subscribe];
    [subcribeInfo setObject:@1 forKey:@"isSubcribed"];
    EDKEntity *subscribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
    [subscribeEntity saveData:subcribeInfo primaryColumn:@"id" relationShip:nil];
    
    // for async task, because easydatakit's transaction default setup 1 second
    XCTestExpectation *exp = [self expectationWithDescription:@"wtf?"];
    sleep(1);
    [exp fulfill];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
