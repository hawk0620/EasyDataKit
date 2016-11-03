//
//  EDKManager.m
//  EasyDataKit
//
//  Copyright © 2016年 hawk. All rights reserved.
//

#import "EDKManager.h"
#import "EDKUtilities.h"
#import "EDKEntity.h"

#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@interface EDKManager ()

@property (nonatomic, strong) NSMutableDictionary *dbQueues;
@property (nonatomic, strong) NSMutableArray *dbTables;

@end

@implementation EDKManager

+ (instancetype)sharedInstance {
    static EDKManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EDKManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _dbQueues = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (FMDatabaseQueue *)dbQueueFromeDbName:(NSString *)dbName {
    @synchronized (self.dbQueues) {
        FMDatabaseQueue *queue = [self.dbQueues objectForKey:dbName];
        if (!queue) {
            NSString *path = [PATH_OF_DOCUMENT stringByAppendingPathComponent:[dbName stringByAppendingPathExtension:@"db"]];
            NSLog(@"%@", path);
            queue = [FMDatabaseQueue databaseQueueWithPath:path];
            EasyDataKitThreadsafetyForQueue(queue);
            [self.dbQueues setObject:queue forKey:dbName];
        }
        return queue;
    }
}

#pragma mark - private method
- (void)syncExcuteSql:(NSString *)sql withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    syncInDb(databaseQueue, ^(FMDatabase *db) {
        BOOL result = [db executeUpdate:sql];
        NSLog(@"Handler is succeed: %d", result);
    });
}

- (void)syncExcuteSql:(NSString *)sql arguments:(NSArray *)arguments withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    syncInDb(databaseQueue, ^(FMDatabase *db) {
        [db executeUpdate:sql withArgumentsInArray:arguments];
    });
}

- (void)asyncExcuteSql:(NSString *)sql arguments:(NSArray *)arguments withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    asyncInDb(databaseQueue, ^(FMDatabase *db) {
        [db executeUpdate:sql withArgumentsInArray:arguments];
    });
}

- (BOOL)existTable:(NSString *)tableName withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    __block BOOL result = NO;
    NSString *tableExistsql = @"SELECT name FROM sqlite_master WHERE type='table' AND name=?";
    
    syncInDb(databaseQueue, ^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:tableExistsql withArgumentsInArray:@[ tableName ]];
        if ([rs next]) {
            result = YES;
        }
        [rs close];
    });
    
    return result;
}

- (NSArray *)tableColumns:(NSString *)tableName withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName];
    NSMutableArray *names = [[NSMutableArray alloc] init];
    
    syncInDb(databaseQueue, ^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next]) {
            NSString *name = [rs stringForColumn:@"name"];
            [names addObject:name];
        }
        [rs close];
    });
    
    return names;
}

- (NSString *)pkColumn:(NSString *)tableName withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    __block NSString *tempName;
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName];
    syncInDb(databaseQueue, ^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql];
        
        while ([rs next]) {
            NSString *name = [rs stringForColumn:@"name"];
            NSInteger isPk = [rs intForColumn:@"pk"];
            if (isPk) {
                tempName = name;
            }
        }
        [rs close];
    });
    
    return tempName;
}

- (NSNumber *)syncInsert:(NSString *)sql data:(NSArray *)array withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    __block NSNumber *rowId;
    syncInDb(databaseQueue, ^(FMDatabase *db) {
        BOOL result = [db executeUpdate:sql withArgumentsInArray:array];
        if (result) {
            rowId = @([db lastInsertRowId]);
        }
    });
    return rowId;
}

- (NSArray *)querySql:(NSString *)sql arguments:(NSArray *)arguments queryColumns:(NSArray *)queryColumns withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    syncInDb(databaseQueue, ^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql withArgumentsInArray:arguments];
        while ([rs next]) {
            NSMutableDictionary *object = [[NSMutableDictionary alloc] init];
            for (NSString *columnName in queryColumns) {
                id columnValue = [rs objectForColumnName:columnName];
                [object setObject:columnValue forKey:columnName];
            }
            
            [objects addObject:object];
        }
        [rs close];
    });
    return objects;
}

#pragma mark - Primark Column Method
- (NSString *)getPkColumn:(EDKEntity *)entity {
    FMDatabaseQueue *databaseQueue = [self dbQueueFromeDbName:entity.dbName];
    return [self pkColumn:entity.tableName withDatabaseQueue:databaseQueue];
}

#pragma mark - Save Method
- (void)createOrUpdateTable:(NSString *)tableName primaryKey:(NSString *)primaryKey columnInfoString:(NSMutableString *)columnInfoString hasPrimaryKey:(BOOL)hasPrimaryKey properties:(NSDictionary *)properties withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    @synchronized (self) {
        BOOL isTableExist = [self existTable:tableName withDatabaseQueue:databaseQueue];
        
        if (!isTableExist) {
            NSString *sql = [EDKUtilities createTableSql:tableName columnInfoString:columnInfoString primaryKey:primaryKey hasPrimaryKey:hasPrimaryKey];
            [self syncExcuteSql:sql withDatabaseQueue:databaseQueue];
        } else {
            NSArray *tableColumns = [self tableColumns:tableName withDatabaseQueue:databaseQueue];
            for (NSString *key in properties.allKeys) {
                if (![tableColumns containsObject:key]) {
                    NSDictionary *dictionary = @{key: properties[key]};
                    NSString *sql = [EDKUtilities alterTableSql:tableName dictionary:dictionary];
                    [self syncExcuteSql:sql withDatabaseQueue:databaseQueue];
                }
            }
        }
    }
    
}

- (void)insertToTable:(NSString *)tableName properties:(NSMutableDictionary *)properties hasPrimaryKey:(BOOL)hasPrimaryKey rowId:(NSNumber **)rowId withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    [properties setObject:[NSDate date] forKey:@"private_created_time"];
    [properties setObject:[NSDate date] forKey:@"private_updated_time"];
    NSArray *tableColumns = [self tableColumns:tableName withDatabaseQueue:databaseQueue];
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    
    NSString *sql = [EDKUtilities insertSql:tableName tableColumns:tableColumns propertyDict:properties arguments:&arguments];
    
    if (hasPrimaryKey) {
        [self asyncExcuteSql:sql arguments:arguments withDatabaseQueue:databaseQueue];
    } else {
        NSNumber *lastInsertId = [self syncInsert:sql data:arguments withDatabaseQueue:databaseQueue];
        if (rowId) {
            *rowId = lastInsertId;
        }
    }
}

- (id)saveObject:(EDKEntity *)entity {
    __block NSNumber *rowId;
    FMDatabaseQueue *databaseQueue = [self dbQueueFromeDbName:entity.dbName];
    
    [self createOrUpdateTable:entity.tableName primaryKey:entity.primaryColumn columnInfoString:entity.columnInfoString hasPrimaryKey:entity.hasPrimaryKey properties:entity.properties withDatabaseQueue:databaseQueue];
    [self insertToTable:entity.tableName properties:entity.properties hasPrimaryKey:entity.hasPrimaryKey rowId:&rowId withDatabaseQueue:databaseQueue];
    
    NSLog(@"==%@", entity.properties[entity.primaryColumn]);
    return entity.hasPrimaryKey ? entity.properties[entity.primaryColumn] : rowId;
}

#pragma mark - Query Method
- (NSArray *)queryFromTable:(NSString *)tableName columns:(NSArray *)columns where:(NSString *)where arguments:(NSArray *)arguments withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    NSMutableString *sql = [EDKUtilities querySql:tableName columns:columns];
    if (where) {
        NSAssert([where isKindOfClass:[NSString class]], @"type error");
        [sql appendFormat:@" %@", where];
    }
    
    NSArray *queryColumns = columns.count == 0 ? [self tableColumns:tableName withDatabaseQueue:databaseQueue] : [columns safeObjectsForSql];
    NSArray *objects = [self querySql:sql arguments:arguments queryColumns:queryColumns withDatabaseQueue:databaseQueue];
    return objects;
}

- (NSArray *)queryObjects:(EDKEntity *)entity {
    FMDatabaseQueue *databaseQueue = [self dbQueueFromeDbName:entity.dbName];
    return [self queryFromTable:entity.tableName columns:entity.columns where:entity.where arguments:entity.arguments withDatabaseQueue:databaseQueue];
}

#pragma mark - Delete Method
- (void)deleteFromTable:(NSString *)tableName where:(NSString *)where arguments:(NSArray *)arguments withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    NSMutableString *sql = [EDKUtilities deleteSql:tableName];
    if (where) {
        NSAssert([where isKindOfClass:[NSString class]], @"type error");
        [sql appendFormat:@" %@", where];
    }
    
    [self asyncExcuteSql:sql arguments:arguments withDatabaseQueue:databaseQueue];
}

- (void)deleteObjects:(EDKEntity *)entity {
    FMDatabaseQueue *databaseQueue = [self dbQueueFromeDbName:entity.dbName];
    [self deleteFromTable:entity.tableName where:entity.where arguments:entity.arguments withDatabaseQueue:databaseQueue];
}

#pragma mark - Update Method
- (void)updateToTable:(NSString *)tableName set:(NSDictionary *)set where:(NSString *)where arguments:(NSArray *)arguments withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    [EDKUtilities parseDictionary:set columnInfoString:nil properties:&properties];
    [properties setObject:[NSDate date] forKey:@"private_updated_time"];
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    NSMutableString *sql = [EDKUtilities updateSql:tableName set:properties values:&values];
    if (where) {
        NSAssert([where isKindOfClass:[NSString class]], @"type error");
        [sql appendFormat:@" %@", where];
    }
    
    [values addObjectsFromArray:arguments];
    [self asyncExcuteSql:sql arguments:values withDatabaseQueue:databaseQueue];
}

- (void)updateObjects:(EDKEntity *)entity {
    FMDatabaseQueue *databaseQueue = [self dbQueueFromeDbName:entity.dbName];
    [self updateToTable:entity.tableName set:entity.set where:entity.where arguments:entity.arguments withDatabaseQueue:databaseQueue];
}

@end
