//
//  EDKEntity.m
//  EasyDataKit
//
//  Copyright © 2016年 hawk. All rights reserved.
//

#import "EDKEntity.h"
#import "EDKUtilities.h"
#import "EDKManager.h"

@interface EDKEntity ()

@property (nonatomic, strong, readwrite) NSString *tableName;
@property (nonatomic, strong, readwrite) NSString *dbName;
@property (nonatomic, strong, readwrite) NSDictionary *data;
@property (nonatomic, strong, readwrite) NSString *primaryColumn;
@property (nonatomic, strong, readwrite) NSDictionary *relationShip;
@property (nonatomic, strong, readwrite) NSMutableString *columnInfoString;
@property (nonatomic, strong, readwrite) NSArray *indexes;
@property (nonatomic, assign, readwrite) BOOL hasPrimaryKey;
@property (nonatomic, strong, readwrite) NSMutableDictionary *properties;
@property (nonatomic, strong, readwrite) NSArray *columns;
@property (nonatomic, strong, readwrite) NSArray *arguments;
@property (nonatomic, strong, readwrite) NSString *where;
@property (nonatomic, strong, readwrite) NSDictionary *set;

@end

@implementation EDKEntity

- (instancetype)initWithTableName:(NSString *)tableName dbName:(NSString *)dbName {
    if (self = [super init]) {
        NSAssert(tableName != nil, @"tablename empty");
        NSAssert(![tableName isEmptyString], @"tablename empty");
        _tableName = tableName;
        if (dbName && ![dbName isEmptyString]) {
            _dbName = dbName;
        } else {
            _dbName = @"EasyDataKit";
        }
    }
    return self;
}

- (instancetype)init {
    return [self initWithTableName:nil dbName:nil];
}

- (id)saveData:(NSDictionary *)data primaryColumn:(NSString *)primaryColumn relationShip:(NSDictionary *)relationShip indexes:(NSArray *)indexes {
    NSAssert([data isKindOfClass:[NSDictionary class]], @"type error");
    NSAssert(data.count != 0, @"data empty");
    self.data = data;
    self.primaryColumn = primaryColumn;
    self.hasPrimaryKey = YES;
    NSDictionary *m_relationShip;
    NSArray *m_Indexes;
    if (relationShip) {
        NSAssert([relationShip isKindOfClass:[NSDictionary class]], @"type error");
        m_relationShip = relationShip;
    }
    if (indexes) {
        NSAssert([indexes isKindOfClass:[NSArray class]], @"type error");
        m_Indexes = indexes;
    }
    
    NSMutableString *columnInfoString = [[NSMutableString alloc] init];
    if ([self.primaryColumn isEmptyString] || ![data.allKeys containsObject:self.primaryColumn]) {
        self.hasPrimaryKey = NO;
    }
    
    NSMutableDictionary *newRelationShip = [[NSMutableDictionary alloc] init];
    [EDKUtilities parseDictionary:m_relationShip columnInfoString:nil properties:&newRelationShip];
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:newRelationShip];
    [EDKUtilities parseDictionary:data columnInfoString:&columnInfoString properties:&properties];
    
    self.columnInfoString = columnInfoString;
    self.properties = properties;
    self.relationShip = newRelationShip;
    self.indexes = m_Indexes;
    
    return [[EDKManager sharedInstance] saveObject:self];
}

- (id)queryByPrimaryKey:(id)primaryKey withColumns:(NSArray *)columns {
    NSAssert(primaryKey != nil, @"primaryKey cannot be nil");
    
    NSString *pkColumn = [[EDKManager sharedInstance] getPkColumn:self];
    NSAssert(![pkColumn isEmptyString], @"primary key column empty");
    
    self.where = [EDKUtilities whereIdSql:pkColumn];
    self.arguments = [@[primaryKey] safeObjectsForSql];
    self.columns = columns;
    
    NSArray *objects = [[EDKManager sharedInstance] queryObjects:self];
    return [objects firstObject];
}

- (NSArray *)queryWithColumns:(NSArray *)columns where:(NSString *)where arguments:(NSArray *)arguments {
    NSMutableArray *newArguments = [[NSMutableArray alloc] init];
    [EDKUtilities parseArguments:arguments newArguments:&newArguments];
    self.arguments = newArguments;
    self.where = where;
    self.columns = columns;
    
    return [[EDKManager sharedInstance] queryObjects:self];
}

- (NSArray *)queryAll {
    return [self queryWithColumns:nil where:nil arguments:nil];
}

- (void)deleteByPrimaryKey:(id)primaryKey {
    NSAssert(primaryKey != nil, @"primaryKey cannot be nil");
    
    NSString *pkColumn = [[EDKManager sharedInstance] getPkColumn:self];
    NSAssert(![pkColumn isEmptyString], @"primary key column empty");
    
    self.where = [EDKUtilities whereIdSql:pkColumn];
    self.arguments = [@[primaryKey] safeObjectsForSql];
    
    [[EDKManager sharedInstance] deleteObjects:self];
}

- (void)deleteWithWhere:(NSString *)where arguments:(NSArray *)arguments {
    NSMutableArray *newArguments = [[NSMutableArray alloc] init];
    [EDKUtilities parseArguments:arguments newArguments:&newArguments];
    self.arguments = newArguments;
    self.where = where;
    
    [[EDKManager sharedInstance] deleteObjects:self];
}

- (void)deleteAll {
    [self deleteWithWhere:nil arguments:nil];
}

- (void)updateByPrimaryKey:(id)primaryKey set:(NSDictionary *)set {
    NSAssert(primaryKey != nil, @"primaryKey cannot be nil");
    
    if (set) {
        NSAssert([set isKindOfClass:[NSDictionary class]], @"type error");
        NSAssert([set count], @"'set' should not be nil.");
    }
    
    NSString *pkColumn = [[EDKManager sharedInstance] getPkColumn:self];
    NSAssert(![pkColumn isEmptyString], @"primary key column empty");
    
    self.set = set;
    self.where = [EDKUtilities whereIdSql:pkColumn];
    self.arguments = [@[primaryKey] safeObjectsForSql];
    
    [[EDKManager sharedInstance] updateObjects:self];
}

- (void)updateWithSet:(NSDictionary *)set where:(NSString *)where arguments:(NSArray *)arguments {
    if (set) {
        NSAssert([set isKindOfClass:[NSDictionary class]], @"type error");
        NSAssert([set count], @"'set' should not be nil.");
    }
    
    NSMutableArray *newArguments = [[NSMutableArray alloc] init];
    [EDKUtilities parseArguments:arguments newArguments:&newArguments];
    
    self.arguments = newArguments;
    self.set= set;
    self.where = where;
    
    [[EDKManager sharedInstance] updateObjects:self];
}

@end
