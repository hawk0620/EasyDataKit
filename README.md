# EasyDataKit

### Initializes
Create EDKEntity with tableName and dbName.
- (instancetype)initWithTableName:(NSString *)tableName dbName:(NSString *)dbName;

### Store
Store Object.
- (void)saveData:(NSDictionary *)data primaryColumn:(NSString *)primaryColumn relationShip:(NSDictionary *)relationShip;

### Query
Query by primary key.
- (id)queryByPrimaryKey:(id)primaryKey withColumns:(NSArray *)columns;
  
Query by where condition.
- (NSArray *)queryWithColumns:(NSArray *)columns where:(NSString *)where arguments:(NSArray *)arguments;
  
Query All.
- (NSArray *)queryAll;

### Delete
Delete by primary key
- (void)deleteByPrimaryKey:(id)primaryKey;
  
Delete by where condition.
- (void)deleteWithWhere:(NSString *)where arguments:(NSArray *)arguments;
  
Delete All.
- (void)deleteAll;

### Update
Update by primary key with set collection.
- (void)updateByPrimaryKey:(id)primaryKey set:(NSDictionary *)set;

Update by where condition with set collection.
- (void)updateWithSet:(NSDictionary *)set where:(NSString *)where arguments:(NSArray *)arguments;