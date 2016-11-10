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
#define kTransactionInterval 1

@interface EDKDbInfo : NSObject

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, assign) BOOL isNeedCommit;
@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation EDKDbInfo
@end

@interface EDKManager ()

@property (nonatomic, strong) NSMutableDictionary *dbInfos;

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
        _dbInfos = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (EDKDbInfo *)dbInfoFromeDbName:(NSString *)dbName {
    @synchronized (_dbInfos) {
        EDKDbInfo *dbInfo = [self.dbInfos objectForKey:dbName];
        if (!dbInfo) {
            NSString *path = [PATH_OF_DOCUMENT stringByAppendingPathComponent:[dbName stringByAppendingPathExtension:@"db"]];
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:path];
            EasyDataKitThreadsafetyForQueue(queue);
            [queue setShouldCacheStatements:YES];
            #ifdef DEBUG
            NSLog(@"DB LOG PATH: %@",path);
            #endif
            
            dbInfo = [[EDKDbInfo alloc] init];
            dbInfo.databaseQueue = queue;
            dbInfo.isNeedCommit = NO;
            [_dbInfos setObject:dbInfo forKey:dbName];
        }
        
        if (!dbInfo.timer) {
            [self autoTransaction:dbInfo];
        }
        return dbInfo;
    }
}

- (void)autoTransaction:(EDKDbInfo *)dbInfo {
    FMDatabaseQueue *databaseQueue = dbInfo.databaseQueue;
    
    dbInfo.timer = CreateDispatchTimer(kTransactionInterval, [databaseQueue queue], ^{
        if (dbInfo.isNeedCommit) {
            syncInDb(databaseQueue, ^(FMDatabase *db) {
                [db commit];
                [db beginTransaction];
            });
            dbInfo.isNeedCommit = NO;
        }
    });
    if (dbInfo.timer) {
        asyncInDb(databaseQueue, ^(FMDatabase *db) {
            [db beginTransaction];
        });
        dispatch_resume(dbInfo.timer);
    }
}

- (void)dbNeedCommit:(EDKDbInfo *)dbInfo {
    if (dbInfo.timer) {
        dbInfo.isNeedCommit = YES;
    }
}

#pragma mark - private method
- (void)syncExcuteSql:(NSString *)sql withDbQueue:(FMDatabaseQueue *)dbQueue {
    syncInDb(dbQueue, ^(FMDatabase *db) {
        [db executeUpdate:sql];
    });
}

- (void)asyncExcuteSql:(NSString *)sql arguments:(NSArray *)arguments withDbQueue:(FMDatabaseQueue *)dbQueue block:(void (^)())block {
    asyncInDb(dbQueue, ^(FMDatabase *db) {
        block();
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

- (void)createIndexes:(NSString *)tableName index:(NSArray *)index allColumns:(NSArray *)allColumns withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    asyncInDb(databaseQueue, ^(FMDatabase *db) {
        NSString *indexSql = [EDKUtilities createIndexesSql:tableName index:index allColumn:allColumns];
        [db executeUpdate:indexSql];
    });
}

- (NSMutableSet *)getIndexes:(NSString *)tableName withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    NSMutableSet *indexes = [[NSMutableSet alloc] init];
    NSString *sql = [[NSString alloc] initWithFormat:@"PRAGMA index_list(%@)", tableName];
    syncInDb(databaseQueue, ^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            NSString *indexName = [resultSet stringForColumn:@"name"];
            if (![indexName hasPrefix:@"sqlite_autoindex_"]) {
                [indexes addObject:[resultSet stringForColumn:@"name"]];
            }
        }
        [resultSet close];
    });
    
    return indexes;
}

- (void)dropIndex:(NSString *)indexName withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    asyncInDb(databaseQueue, ^(FMDatabase *db) {
        NSString *sql = [[NSString alloc] initWithFormat:@"DROP INDEX %@", indexName];
        [db executeUpdate:sql];
    });
}

#pragma mark - Primark Column Method
- (NSString *)getPkColumn:(EDKEntity *)entity {
    EDKDbInfo *dbInfo = [self dbInfoFromeDbName:entity.dbName];
    return [self pkColumn:entity.tableName withDatabaseQueue:dbInfo.databaseQueue];
}

#pragma mark - Save Method
- (void)createOrUpdateTable:(NSString *)tableName primaryKey:(NSString *)primaryKey columnInfoString:(NSMutableString *)columnInfoString hasPrimaryKey:(BOOL)hasPrimaryKey properties:(NSDictionary *)properties indexes:(NSArray *)indexes withDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
    @synchronized (self) {
        BOOL isTableExist = [self existTable:tableName withDatabaseQueue:databaseQueue];
        
        if (!isTableExist) {
            NSString *sql = [EDKUtilities createTableSql:tableName columnInfoString:columnInfoString primaryKey:primaryKey hasPrimaryKey:hasPrimaryKey];
            [self syncExcuteSql:sql withDbQueue:databaseQueue];
            
            for (NSArray *index in indexes) {
                NSAssert([index isKindOfClass:[NSArray class]], @"type error");
                [self createIndexes:tableName index:index allColumns:properties.allKeys withDatabaseQueue:databaseQueue];
            }
            
        } else {
            NSArray *tableColumns = [self tableColumns:tableName withDatabaseQueue:databaseQueue];
            
            if ((tableColumns.count - 2) < properties.allKeys.count) {
                for (NSString *key in properties.allKeys) {
                    if (![tableColumns containsObject:key]) {
                        NSDictionary *dictionary = @{key: properties[key]};
                        NSString *sql = [EDKUtilities alterTableSql:tableName dictionary:dictionary];
                        [self syncExcuteSql:sql withDbQueue:databaseQueue];
                    }
                }
            }
            
            NSMutableSet *allIndexes = [self getIndexes:tableName withDatabaseQueue:databaseQueue];
            for (NSArray *index in indexes) {
                NSAssert([index isKindOfClass:[NSArray class]], @"type error");
                NSString *indexName = [[NSString alloc] initWithFormat:@"%@_%@", tableName, [index componentsJoinedByString:@"_"]];
                if (![allIndexes containsObject:indexName]) {
                    [self createIndexes:tableName index:index allColumns:properties.allKeys withDatabaseQueue:databaseQueue];
                } else {
                    [allIndexes removeObject:indexName];
                }
            }
            
            for (NSString *indexName in allIndexes) {
                [self dropIndex:indexName withDatabaseQueue:databaseQueue];
            }
        }
    }
    
}

- (void)insertToTable:(NSString *)tableName properties:(NSMutableDictionary *)properties hasPrimaryKey:(BOOL)hasPrimaryKey rowId:(NSNumber **)rowId withDatabaseQueue:(EDKDbInfo *)dbInfo {
    [properties setObject:[NSDate date] forKey:@"private_created_time"];
    [properties setObject:[NSDate date] forKey:@"private_updated_time"];
    NSArray *tableColumns = [self tableColumns:tableName withDatabaseQueue:dbInfo.databaseQueue];
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    
    NSString *sql = [EDKUtilities insertSql:tableName tableColumns:tableColumns propertyDict:properties arguments:&arguments];
    
    if (hasPrimaryKey) {
        
        __weak __typeof(self)weakSelf = self;
        [self asyncExcuteSql:sql arguments:arguments withDbQueue:dbInfo.databaseQueue block:^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf dbNeedCommit:dbInfo];
        }];
    } else {
        
        __weak __typeof(self)weakSelf = self;
        syncInDb(dbInfo.databaseQueue, ^(FMDatabase *db) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf dbNeedCommit:dbInfo];
            
            BOOL result = [db executeUpdate:sql withArgumentsInArray:arguments];
            if (result) {
                if (rowId) {
                    *rowId = @([db lastInsertRowId]);
                }
            }
        });
    }
}

- (id)saveObject:(EDKEntity *)entity {
    __block NSNumber *rowId;
    EDKDbInfo *dbInfo = [self dbInfoFromeDbName:entity.dbName];
    
    [self createOrUpdateTable:entity.tableName primaryKey:entity.primaryColumn columnInfoString:entity.columnInfoString hasPrimaryKey:entity.hasPrimaryKey properties:entity.properties indexes:entity.indexes withDatabaseQueue:dbInfo.databaseQueue];
    [self insertToTable:entity.tableName properties:entity.properties hasPrimaryKey:entity.hasPrimaryKey rowId:&rowId withDatabaseQueue:dbInfo];
    
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

- (NSArray *)queryObjects:(EDKEntity *)entity {
    EDKDbInfo *dbInfo = [self dbInfoFromeDbName:entity.dbName];
    return [self queryFromTable:entity.tableName columns:entity.columns where:entity.where arguments:entity.arguments withDatabaseQueue:dbInfo.databaseQueue];
}

#pragma mark - Delete Method
- (void)deleteFromTable:(NSString *)tableName where:(NSString *)where arguments:(NSArray *)arguments withDatabaseQueue:(EDKDbInfo *)dbInfo {
    NSMutableString *sql = [EDKUtilities deleteSql:tableName];
    if (where) {
        NSAssert([where isKindOfClass:[NSString class]], @"type error");
        [sql appendFormat:@" %@", where];
    }
    
    __weak __typeof(self)weakSelf = self;
    [self asyncExcuteSql:sql arguments:arguments withDbQueue:dbInfo.databaseQueue block:^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf dbNeedCommit:dbInfo];
    }];
}

- (void)deleteObjects:(EDKEntity *)entity {
    EDKDbInfo *dbInfo = [self dbInfoFromeDbName:entity.dbName];
    [self deleteFromTable:entity.tableName where:entity.where arguments:entity.arguments withDatabaseQueue:dbInfo];
}

#pragma mark - Update Method
- (void)updateToTable:(NSString *)tableName set:(NSDictionary *)set where:(NSString *)where arguments:(NSArray *)arguments withDatabaseQueue:(EDKDbInfo *)dbInfo {
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
    
    __weak __typeof(self)weakSelf = self;
    [self asyncExcuteSql:sql arguments:values withDbQueue:dbInfo.databaseQueue block:^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf dbNeedCommit:dbInfo];
    }];
}

- (void)updateObjects:(EDKEntity *)entity {
    EDKDbInfo *dbInfo = [self dbInfoFromeDbName:entity.dbName];
    [self updateToTable:entity.tableName set:entity.set where:entity.where arguments:entity.arguments withDatabaseQueue:dbInfo];
}

@end
