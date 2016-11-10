//
//  EDKUtility.h
//  EasyDataKit
//
//  Copyright © 2016年 hawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

typedef void (^DbBlock)(FMDatabase *db);

extern void EasyDataKitThreadsafetyForQueue(FMDatabaseQueue *queue);
extern void syncInDb(FMDatabaseQueue *queue, DbBlock block);
extern void asyncInDb(FMDatabaseQueue *queue, DbBlock block);

extern dispatch_source_t CreateDispatchTimer(double interval, dispatch_queue_t queue, dispatch_block_t block);

@interface EDKUtilities : NSObject

+ (void)parseDictionary:(NSDictionary *)dictionary columnInfoString:(NSMutableString * __autoreleasing *)columnInfoString properties:(NSMutableDictionary * __autoreleasing *)properties;

+ (void)parseArguments:(NSArray *)arguments newArguments:(NSMutableArray **)newArguments;

+ (NSString *)createTableSql:(NSString *)tableName columnInfoString:(NSMutableString *)columnInfoString primaryKey:(NSString *)primaryKey hasPrimaryKey:(BOOL)hasPrimaryKey;

+ (NSString *)createIndexesSql:(NSString *)tableName index:(NSArray *)index allColumn:(NSArray *)allColumn;

+ (NSString *)alterTableSql:(NSString *)tableName dictionary:(NSDictionary *)dictionary;

+ (NSString *)insertSql:(NSString *)tableName tableColumns:(NSArray *)tableColumns propertyDict:(NSDictionary *)propertyDict arguments:(NSMutableArray * __autoreleasing *)arguments;

+ (NSString *)whereIdSql:(NSString *)pkColumn;

+ (NSMutableString *)querySql:(NSString *)tableName columns:(NSArray *)columns;

+ (NSMutableString *)deleteSql:(NSString *)tableName;

+ (NSMutableString *)updateSql:(NSString *)tableName set:(NSDictionary *)set values:(NSMutableArray * __autoreleasing *)values;

@end

@interface NSDictionary (Additions)

- (NSString *)jsonString;
- (NSDictionary *)safeObjectsForSql;

@end

@interface NSMutableDictionary (Additions)

- (void)once_setObject:(id)anObject forKey:(id<NSCopying>)aKey;

@end

@interface NSArray (Additions)

- (NSString *)jsonString;
- (NSArray *)safeObjectsForSql;

@end

@interface NSMutableArray (Additions)

@end

@interface NSString (Addtional)

- (BOOL)isEmptyString;
- (BOOL)isVaildVariableName;

@end


@interface FMDatabaseQueue (ThreadSafe)

- (dispatch_queue_t)queue;
- (void)setShouldCacheStatements:(BOOL)value;
- (FMDatabase*)database;

@end
