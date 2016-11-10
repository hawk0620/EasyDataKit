//
//  EDKUtility.m
//  EasyDataKit
//
//  Copyright © 2016年 hawk. All rights reserved.
//

#import "EDKUtilities.h"
#import "objc/runtime.h"

static void *const EasyDataKitThreadsafetyQueueIDKey = (void *)&EasyDataKitThreadsafetyQueueIDKey;

void EasyDataKitThreadsafetyForQueue(FMDatabaseQueue *queue) {
    void *uuid = calloc(1, sizeof(uuid));
    dispatch_queue_set_specific([queue queue], EasyDataKitThreadsafetyQueueIDKey, uuid, free);
}

void syncInDb(FMDatabaseQueue *queue, DbBlock block) {
    void *uuidMine = dispatch_get_specific(EasyDataKitThreadsafetyQueueIDKey);
    void *uuidOther = dispatch_queue_get_specific([queue queue], EasyDataKitThreadsafetyQueueIDKey);
    
    dispatch_block_t task = ^() {
        FMDatabase *db = [queue database];
        block(db);
        
    };
    
    if (uuidMine == uuidOther) {
        task();
    } else {
        dispatch_sync([queue queue], task);
    }
}

void asyncInDb(FMDatabaseQueue *queue, DbBlock block) {
    void *uuidMine = dispatch_get_specific(EasyDataKitThreadsafetyQueueIDKey);
    void *uuidOther = dispatch_queue_get_specific([queue queue], EasyDataKitThreadsafetyQueueIDKey);
    
    dispatch_block_t task = ^() {
        FMDatabase *db = [queue database];
        block(db);
        
    };
    
    if (uuidMine == uuidOther) {
        task();
    } else {
        dispatch_async([queue queue], task);
    }
}

dispatch_source_t CreateDispatchTimer(double interval, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, NSEC_PER_MSEC);
        dispatch_source_set_event_handler(timer, block);
    }
    return timer;
}

@implementation EDKUtilities

+ (id)dealWithObject:(id)obj {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mDictionary = [[NSMutableDictionary alloc] init];
        for (NSString *key in obj) {
            id obj2 = [obj objectForKey:key];
            id value = [self dealWithObject:obj2];
            [mDictionary setObject:value forKey:key];
        }
        obj = mDictionary;
        
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *mArray = [[NSMutableArray alloc] init];
        for (id obj2 in obj) {
            id value = [self dealWithObject:obj2];
            [mArray addObject:value];
        }
        obj = mArray;
        
    } else if ([obj isKindOfClass:[NSString class]]) {
    } else if ([obj isKindOfClass:[NSNumber class]]) {
    } else if ([obj isKindOfClass:[NSNull class]]) {
    } else {
        obj = [obj description];
    }
    return obj;
}

+ (void)parseDictionary:(NSDictionary *)dictionary columnInfoString:(NSMutableString * __autoreleasing *)columnInfoString properties:(NSMutableDictionary * __autoreleasing *)properties {
    for (NSString *key in dictionary.allKeys) {
        NSAssert([key isVaildVariableName], @"key is vaild");
        id value = dictionary[key];
        
        if ([value isKindOfClass:[NSString class]]) {
            if (columnInfoString) {
                [*columnInfoString appendFormat:@"%@ TEXT,",key];
            }
            if (properties) {
                [*properties once_setObject:value forKey:key];
            }
            
        } else if ([value isKindOfClass:[NSNumber class]]) {
            if (columnInfoString) {
                [*columnInfoString appendFormat:@"%@ NUMERIC,",key];
            }
            if (properties) {
                [*properties once_setObject:value forKey:key];
            }
            
        } else if ([value isKindOfClass:[NSNull class]]) {
            if (columnInfoString) {
                [*columnInfoString appendFormat:@"%@ TEXT,",key];
            }
            if (properties) {
                [*properties once_setObject:value forKey:key];
            }
            
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            if (columnInfoString) {
                [*columnInfoString appendFormat:@"%@ TEXT,",key];
            }
            if (properties) {
                [*properties once_setObject:[[self dealWithObject:value] jsonString] forKey:key];
            }
            
        } else if ([value isKindOfClass:[NSArray class]]) {
            if (columnInfoString) {
                [*columnInfoString appendFormat:@"%@ TEXT,",key];
            }
            if (properties) {
                [*properties once_setObject:[[self dealWithObject:value] jsonString] forKey:key];
            }
            
        } else {
            if (columnInfoString) {
                [*columnInfoString appendFormat:@"%@ TEXT,",key];
            }
            if (properties) {
                [*properties once_setObject:[value description] forKey:key];
            }
        }
    }
}

+ (void)parseArguments:(NSArray *)arguments newArguments:(NSMutableArray **)newArguments {
    for (id value in arguments) {
        if ([value isKindOfClass:[NSString class]]) {
            if (newArguments) {
                [*newArguments addObject:value];
            }
            
        } else if ([value isKindOfClass:[NSNumber class]]) {
            if (newArguments) {
                [*newArguments addObject:value];
            }
            
        } else if ([value isKindOfClass:[NSNull class]]) {
            if (newArguments) {
                [*newArguments addObject:value];
            }
            
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            if (newArguments) {
                [*newArguments addObject:[[self dealWithObject:value] jsonString]];
            }
            
        } else if ([value isKindOfClass:[NSArray class]]) {
            if (newArguments) {
                [*newArguments addObject:[[self dealWithObject:value] jsonString]];
            }
            
        } else {
            if (newArguments) {
                [*newArguments addObject:[value description]];
            }
        }
    }
}

+ (NSString *)createTableSql:(NSString *)tableName columnInfoString:(NSMutableString *)columnInfoString primaryKey:(NSString *)primaryKey hasPrimaryKey:(BOOL)hasPrimaryKey {
    if (hasPrimaryKey) {
        NSInteger location = [columnInfoString rangeOfString:primaryKey].length + [columnInfoString rangeOfString:primaryKey].location;
        NSRange range = [columnInfoString rangeOfString:@"," options:NSCaseInsensitiveSearch range:NSMakeRange(location, columnInfoString.length - location)];
        [columnInfoString insertString:@" PRIMARY KEY" atIndex:range.location];
        
    } else {
        [columnInfoString appendString:@"private_own_identity INTEGER PRIMARY KEY AUTOINCREMENT,"];
    }
    
    [columnInfoString appendString:@"private_created_time DATETIME,"];
    [columnInfoString appendString:@"private_updated_time DATETIME"];
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ( %@ )", tableName, columnInfoString];
    
    return sql;
}

+ (NSString *)createIndexesSql:(NSString *)tableName index:(NSArray *)index allColumn:(NSArray *)allColumn {
    NSMutableString *columns = [[NSMutableString alloc] init];
    for (NSInteger i = 0; i < index.count; i++) {
        id value = [index objectAtIndex:i];
        NSAssert([value isKindOfClass:[NSString class]], @"type error");
        NSAssert([allColumn containsObject:value], @"can't find index column in all columns");
        
        if (i == index.count - 1) {
            [columns appendString:value];
        } else {
            [columns appendFormat:@"%@,", value];
        }
    }
    
    NSString *indexName = [[NSString alloc] initWithFormat:@"%@_%@", tableName, [index componentsJoinedByString:@"_"]];
    NSString *sql = [[NSString alloc] initWithFormat:@"CREATE INDEX IF NOT EXISTS %@ ON %@ (%@)", indexName, tableName, columns];
    
    return sql;
}

+ (NSString *)alterTableSql:(NSString *)tableName dictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *newColumn = [[NSMutableDictionary alloc] init];
    NSMutableString *newColumnString = [[NSMutableString alloc] init];
    [self parseDictionary:dictionary columnInfoString:&newColumnString properties:&newColumn];
    
    NSString *fieldString = [newColumnString substringToIndex:newColumnString.length - 1];
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@", tableName, fieldString];
    return sql;
}

+ (NSString *)insertSql:(NSString *)tableName tableColumns:(NSArray *)tableColumns propertyDict:(NSDictionary *)propertyDict arguments:(NSMutableArray * __autoreleasing *)arguments {
    //    NSArray *tableColumns = [DataDriver tableColumns:tableName withDatabaseQueue:self.databaseQueue];
    NSMutableString *columnNameString = [[NSMutableString alloc] init];
    NSMutableString *paramString = [[NSMutableString alloc] init];
    
    for (NSInteger i = 0; i < tableColumns.count; i++) {
        NSString *columnName = [tableColumns objectAtIndex:i];
        
        if (propertyDict[columnName]) {
            [columnNameString appendString:[NSString stringWithFormat:@"%@,", columnName]];
            [paramString appendString:@"?,"];
            if (arguments) {
                [*arguments addObject:propertyDict[columnName]];
            }
        }
    }
    
    NSString *fieldString = [columnNameString substringToIndex:columnNameString.length - 1];
    NSString *parameterString = [paramString substringToIndex:paramString.length - 1];
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) values(%@)", tableName, fieldString, parameterString];
    
    return sql;
}

+ (NSString *)whereIdSql:(NSString *)pkColumn {
    return [NSString stringWithFormat:@"WHERE %@ = ?", pkColumn];
}

+ (NSMutableString *)querySql:(NSString *)tableName columns:(NSArray *)columns {
    NSString *columnSql;
    if (columns.count == 0) {
        columnSql = @"*";
    } else {
        NSMutableString *columnNames = [[NSMutableString alloc] init];
        for (NSInteger i = 0; i < columns.count; i++) {
            id column = [columns objectAtIndex:i];
            if (i == columns.count - 1) {
                [columnNames appendString:[column description]];
            } else {
                [columnNames appendString:[NSString stringWithFormat:@"%@,",[column description]]];
            }
        }
        columnSql = columnNames;
    }
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT %@ FROM %@", columnSql, tableName];
    return sql;
}

+ (NSMutableString *)deleteSql:(NSString *)tableName {
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %@", tableName];
    return sql;
}

+ (NSMutableString *)updateSql:(NSString *)tableName set:(NSDictionary *)set values:(NSMutableArray * __autoreleasing *)values {
    NSMutableString *setSql = [[NSMutableString alloc] initWithString:@"SET "];
    
    NSArray *allKeys = set.allKeys;
    for (NSInteger i = 0; i < allKeys.count; i++) {
        NSString *key = [allKeys objectAtIndex:i];
        if (i == set.count - 1) {
            [setSql appendFormat:@"%@ = ?", key];
        } else {
            [setSql appendFormat:@"%@ = ?, ", key];
        }
        if (values) {
            [*values addObject:[set objectForKey:key]];
        }
    }
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ %@", tableName, setSql];
    return sql;
}

@end

@implementation NSObject (Additions)

+ (BOOL)swizzleMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
    if (!originalMethod || !swizzledMethod) {
        return NO;
    }
    
    BOOL needAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (needAddMethod) {
        class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
    return YES;
}

@end

@implementation NSDictionary (Additions)

- (NSString *)jsonString {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:0
                                                         error:&error];
    
    if (! jsonData) {
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

- (NSDictionary *)safeObjectsForSql {
    NSMutableDictionary *safeDictionary = [[NSMutableDictionary alloc] init];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [safeDictionary setObject:[obj description] forKey:[key description]];
    }];
    return safeDictionary;
}

@end

@implementation NSMutableDictionary (Additions)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod:@selector(setObject:forKey:) withMethod:@selector(safe_setObject:forKey:)];
    });
}

- (void)safe_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (!aKey) {
        return;
    }
    if (!anObject) {
        return;
    }
    [self safe_setObject:anObject forKey:aKey];
}

- (void)once_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (![self objectForKey:aKey]) {
        [self setObject:anObject forKey:aKey];
    }
}

@end

@implementation NSArray (Additions)

- (NSString *)jsonString {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:0
                                                         error:&error];
    
    if (! jsonData) {
        return @"[]";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

- (NSArray *)safeObjectsForSql {
    NSMutableArray *safeArray = [[NSMutableArray alloc] init];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [safeArray addObject:[obj description]];
    }];
    return safeArray;
}

@end

@implementation NSMutableArray (Additions)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod:@selector(addObject:) withMethod:@selector(safe_addObject:)];
    });
}

- (void)safe_addObject:(id)anObject {
    if (!anObject) {
        return;
    }
    
    [self safe_addObject:anObject];
}

@end

@implementation NSString (Addtional)

- (BOOL)isEmptyString {
    if (!self || self == (id)[NSNull null]) return YES;
    if ([self isKindOfClass:[NSString class]]) {
        return self.length == 0;
    } else {
        return YES;
    }
}

- (BOOL)isVaildVariableName {
    char *pattern = "^[a-zA-Z_$][a-zA-Z_$0-9]*$";
    NSError  *error  = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:[NSString stringWithFormat:@"%s", pattern]
                                  options:0
                                  error:&error];
    NSArray *matches = [regex matchesInString:self options:0 range:NSMakeRange(0, [self length])];
    if (matches.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

@end

@implementation FMDatabaseQueue (ThreadSafe)

- (dispatch_queue_t)queue {
    return _queue;
}

- (void)setShouldCacheStatements:(BOOL)value {
    [_db setShouldCacheStatements:value];
}

- (FMDatabase*)database {
    if (!_db) {
        _db = FMDBReturnRetained([FMDatabase databaseWithPath:_path]);
        
        if (![_db open]) {
            FMDBRelease(_db);
            _db  = nil;
            return nil;
        }
    }
    return _db;
}

@end
