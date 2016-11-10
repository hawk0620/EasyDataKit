//
//  EDKEntity.h
//  EasyDataKit
//
//  Copyright © 2016年 hawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDKEntity : NSObject

///-----------------------------
/// @name EDKEntity Properties
///-----------------------------

/**
 The tableName that describes the entity in which table.
 */
@property (nonatomic, strong, readonly) NSString *tableName;
/**
 The dbName that describes the entity in which database.
 */
@property (nonatomic, strong, readonly) NSString *dbName;

// store
/**
 The store data.
 */
@property (nonatomic, strong, readonly) NSDictionary *data;
/**
 The primary cloumn name.
 */
@property (nonatomic, strong, readonly) NSString *primaryColumn;
/**
 The relation with other data.
 */
@property (nonatomic, strong, readonly) NSDictionary *relationShip;

/**
 The column type prepare to generate sql.
 */
@property (nonatomic, strong, readonly) NSMutableString *columnInfoString;

/**
 The table's indexes.
 */
@property (nonatomic, strong, readonly) NSArray *indexes;
/**
 The data that will be stored is has primary key, if no, use rowId as its primary key by defalut.
 */
@property (nonatomic, assign, readonly) BOOL hasPrimaryKey;
/**
 The store data's arguments.
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *properties;

// query
/**
 The columns that espect to be query.
 */
@property (nonatomic, strong, readonly) NSArray *columns;

// query delete update
/**
 The where condition's arguments.
 */
@property (nonatomic, strong, readonly) NSArray *arguments;
/**
 The where condition's.
 */
@property (nonatomic, strong, readonly) NSString *where;

// update
/**
 The update data's arguments.
 */
@property (nonatomic, strong, readonly) NSDictionary *set;

///----------------------------------
/// @name Initializing an EDKEntity
///----------------------------------

/**
 Initializes a new EDKEntity.
 
 @param tableName The tableName that describes this entity's table name.
 
 @param dbName The dbName that describes the table in which db file.
 
 @return A new EDKEntity.
 
 @warning `EDKEntity` raises an exception if `tableName` is `nil`.
 */
- (instancetype)initWithTableName:(NSString *)tableName dbName:(NSString *)dbName;

///-----------------------------------------------------------
/// @name Storing, Retrieving, Deleting And Updating Entries
///-----------------------------------------------------------

/**
 Stores data in the table.
 
 @param data The data will store in table. Must not be `nil`.
 
 @param primaryColumn The primary column of the table, if `nil`, use rowId as priamry key by default.
 
 @param relationShip The relation that relate other data, if data dosen't need relate, set `nil`.
 
 @param indexes The table's indexes, if doesn't need indexes, pass `nil`.
 
 */
- (id)saveData:(NSDictionary *)data primaryColumn:(NSString *)primaryColumn relationShip:(NSDictionary *)relationShip indexes:(NSArray *)indexes;

/**
 Returns data in the table.
 
 @param primaryKey The data in table's primary key value.
 
 @param columns The espect query's columns , if `nil`, it will query all column.
 
 @discussion The data what you retrive is a dictionary type, if you have nest object in it, the nest object will be parsed to json string in the dictionary, you can use `NSJSONSerialization` to convert to `NSDictionary` or `NSArray` object.
 
 */
- (id)queryByPrimaryKey:(id)primaryKey withColumns:(NSArray *)columns;

/**
 Returns data in the table.
 
 @param columns The espect query's columns , if `nil`, it will query all column.
 
 @param where The where condition.
 
 @param arguments The where condition's arguments.
 
 @discussion The data what you retrive is a dictionary type, if you have nest object in it, the nest object will be parsed to json string in the dictionary, you can use `NSJSONSerialization` to convert to `NSDictionary` or `NSArray` object.
 
 */
- (NSArray *)queryWithColumns:(NSArray *)columns where:(NSString *)where arguments:(NSArray *)arguments;

/**
 Returns all data in the table.
 
 @discussion The data what you retrive is a dictionary type, if you have nest object in it, the nest object will be parsed to json string in the dictionary, you can use `NSJSONSerialization` to convert to `NSDictionary` or `NSArray` object.
 
 */
- (NSArray *)queryAll;

/**
 Deletes data in the table.
 
 @param primaryKey The data in table's primary key value.
 
 */
- (void)deleteByPrimaryKey:(id)primaryKey;

/**
 Deletes data in the table.
 
 @param where The where condition.
 
 @param arguments The where condition's arguments.
 
 */
- (void)deleteWithWhere:(NSString *)where arguments:(NSArray *)arguments;

/**
 Deletes all data in the table.
 
 */
- (void)deleteAll;

/**
 Updates data in the table.
 
 @param primaryKey The data in table's primary key value.
 
 @param set The update data's arguments.
 
 @discussion The set can nest `NSDictionary` and `NSArray`, just feel free to nest object. You can also convert them to json string as you like.
 
 */
- (void)updateByPrimaryKey:(id)primaryKey set:(NSDictionary *)set;

/**
 Updates data in the table.
 
 @param set The update data's arguments.
 
 @param where The where condition.
 
 @param arguments The where condition's arguments.
 
 @discussion The set can nest `NSDictionary` and `NSArray`, just feel free to nest object. You can also convert them to json string as you like.
 
 */
- (void)updateWithSet:(NSDictionary *)set where:(NSString *)where arguments:(NSArray *)arguments;

@end
