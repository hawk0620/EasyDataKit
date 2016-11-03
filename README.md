# EasyDataKit

### Initializes
Create EDKEntity with tableName and dbName.
```objc
- (instancetype)initWithTableName:(NSString *)tableName dbName:(NSString *)dbName;
```

### Store
Store Object.
```objc
- (void)saveData:(NSDictionary *)data primaryColumn:(NSString *)primaryColumn relationShip:(NSDictionary *)relationShip;
```

### Query
Query by primary key.
```objc
- (id)queryByPrimaryKey:(id)primaryKey withColumns:(NSArray *)columns;
```

Query by where condition.
```objc
- (NSArray *)queryWithColumns:(NSArray *)columns where:(NSString *)where arguments:(NSArray *)arguments;
```

Query All.
```objc
- (NSArray *)queryAll;
```

### Delete
Delete by primary key
```objc
- (void)deleteByPrimaryKey:(id)primaryKey;
```

Delete by where condition.
```objc
- (void)deleteWithWhere:(NSString *)where arguments:(NSArray *)arguments;
```

Delete All.
```objc
- (void)deleteAll;
```

### Update
Update by primary key with set collection.
```objc
- (void)updateByPrimaryKey:(id)primaryKey set:(NSDictionary *)set;
```

Update by where condition with set collection.
```objc
- (void)updateWithSet:(NSDictionary *)set where:(NSString *)where arguments:(NSArray *)arguments;
```