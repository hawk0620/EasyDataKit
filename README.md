# EasyDataKit

####[English Introduction](#English Introduction)

EasyDataKit 可以使数据存储、更新、查询和删除操作变得非常简单。它基于 FMDB 封装，支持了类似 ORM 的方式进行数据库操作。特别适用于获取网络请求后直接对 JSON 数据的持久化等操作。

# 特征

* 类 ORM 接口

* 自动创建库和表，支持表新增字段的修改

* 支持 where 查询语句

* 自动事务提升插入效率

# 安装
```
pod 'EasyDataKit'
```

# 使用

假设你通过网络请求获取到了数据：
```
{
    "data": {
        "id": "56d177a27cb3331100465f72",
        "messagePrefix": "饭否每日精选",
        "content": "饭否每日精选",
        "topicId": 1345,
        "briefIntro": "饭否是国内著名的小众轻博客社区，氛围独特，清新自由。关注饭否每日精选，看看尘嚣之外，大家谈论什么。",
        "keywords": "饭否 精选 短博客 社区",
        "timeForRank": "2016-02-27T11:06:30.731Z",
        "lastMessagePostTime": "2016-11-06T02:42:52.111Z",
        "topicPublishDate": "2016-02-26T16:00:00.000Z",
        "createdAt": "2016-02-27T10:17:06.295Z",
        "updatedAt": "2016-11-01T04:30:08.973Z",
        "subscribersCount": 1207100,
        "subscribedStatusRawValue": 1,
        "subscribedAt": "2016-10-18T09:57:24.424Z",
        "rectanglePicture": {
            "thumbnailUrl": "https://cdn.ruguoapp.com/o_1ach3c6o011j91ljjtmdhlhnffo.jpg?imageView2/1/w/120/h/180",
            "middlePicUrl": "https://cdn.ruguoapp.com/o_1ach3c6o011j91ljjtmdhlhnffo.jpg?imageView2/1/w/200/h/300",
            "picUrl": "https://cdn.ruguoapp.com/o_1ach3c6o011j91ljjtmdhlhnffo.jpg?imageView2/0/h/1000",
            "format": "png"
        },
        "squarePicture": {
            "thumbnailUrl": "https://cdn.ruguoapp.com/o_1ach6nm599m94re1gvj14r71jaso.jpg?imageView2/0/w/120/h/120",
            "middlePicUrl": "https://cdn.ruguoapp.com/o_1ach6nm599m94re1gvj14r71jaso.jpg?imageView2/0/w/300/h/300",
            "picUrl": "https://cdn.ruguoapp.com/o_1ach6nm599m94re1gvj14r71jaso.jpg?imageView2/0/h/1000",
            "format": "png"
        },
        "pictureUrl": "https://cdn.ruguoapp.com/o_1ach3c6o011j91ljjtmdhlhnffo.jpg?imageView2/1/w/200/h/300",
        "thumbnailUrl": "https://cdn.ruguoapp.com/o_1ach6nm599m94re1gvj14r71jaso.jpg?imageView2/0/w/300/h/300"
    }
}
```

你可将这段 JSON String 转换成 Dictionary 或 Array:

```objc
NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
NSDictionary *subscribe = dictionary[@"data"];
```

## 存储
接着便可使用 EasyDataKit 的 API 进行存储：

```objc
EDKEntity *subscribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subscribeEntity saveData:subscribe primaryColumn:@"id" relationShip:nil];
```

如果你不想使用 id 作为主键，你可以传 nil 让 EasyDataKit 自动生成每条记录的 rowId 作为主键列：

```objc
EDKEntity *subscribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subscribeEntity saveData:subscribe primaryColumn:nil relationShip:nil];
```

你可以手动为数据添加列，实现满足业务的需求：

```objc
NSMutableDictionary *subcribeInfo = [[NSMutableDictionary alloc] initWithDictionary:subscribe];
[subcribeInfo setObject:@1 forKey:@"isSubcribed"];
EDKEntity *subscribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subscribeEntity saveData:subcribeInfo primaryColumn:@"id" relationShip:nil];
```

如果你想让某纪录关联其它对象，可以将对象存储后返回的 id 作为 value，key 是该纪录原本对应该对象的字段，这相当于用 id 这个值去替换原本字段对应的对象，从而达到拆分的目的：

```objc
id rowId = [rectanglePictureEntity saveData:subscribe[@"rectanglePicture"] primaryColumn:nil relationShip:nil];

EDKEntity *subscribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subscribeEntity saveData:subscribe primaryColumn:@"id" relationShip:@{@"rectanglePicture": rowId}];
```

## 查询

通过 id 查询:
```objc
// select by id
EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
id object = [entity queryByPrimaryKey:@"581d2fdb36a4471100e311d6" withColumns:@[@"topicId", @"commentCount", @"topic"]];
NSLog(@"%@", object);

// relationship query
EDKEntity *topicEntity = [[EDKEntity alloc] initWithTableName:@"topics" dbName:nil];
id topic = [topicEntity queryByPrimaryKey:object[@"topic"] withColumns:nil];
NSLog(@"%@",topic);
```

通过 where 条件查询:
```objc
NSArray *objects = [entity queryWithColumns:nil where:@"WHERE commentCount < ? and read = ?" arguments:@[@20, @1]];
NSLog(@"%@", objects);

查询全部纪录:
```objc
NSArray *objects = [entity queryAll];
NSLog(@"%@", objects);
```

查询嵌套对象并将其转换为 Dictionary 或 Array:
```objc
EDKEntity *subcribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
// select by id
id subcribe = [subcribeEntity queryByPrimaryKey:@"56d177a27cb3331100465f72" withColumns:@[@"squarePicture"]];
// subcribe is a json string
NSData *data = [subcribe[@"squarePicture"] dataUsingEncoding:NSUTF8StringEncoding];
NSError *error;
NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
NSLog(@"JSONDict: %@", jsonDict);
```

## 更新

普通更新:
```objc
EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
[entity updateByPrimaryKey:@"5805905a319a9c1200833660" set:@{@"read": @"0", @"commentCount": @99}];
[entity updateWithSet:@{@"messageId": @"2333333"} where:@"WHERE commentCount > ?" arguments:@[@50]];
```

使用字典更新嵌套对象:
```objc
NSDictionary *square = @{@"lisp": @"blablabla..."};
EDKEntity *subcribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subcribeEntity updateByPrimaryKey:@"56d177a27cb3331100465f72" set:@{@"squarePicture": square}];
```

## 删除
```objc
EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
// delete by id
[entity deleteByPrimaryKey:@"5805905a319a9c1200833660"];
// delete by where
[entity deleteWithWhere:@"WHERE popularity = ?" arguments:@[@"93"]];
// delete all
[entity deleteAll];
```

## 更详尽的使用请参考 Example 中的 test

# 许可证

EasyDataKit 采用 MIT 许可证，详情见 LICENSE 文件。


# English Introduction

EasyDataKit makes data store, update, query and delete easy.It is based on FMDB, and support an ORM way to deal with db.

# Features

* like ORM interface.

* auto create db and table, also alter table

* support where condition query

* auto transaction improve insert effect

# Installation

```
pod 'EasyDataKit'
```

# Usage

Assume you get a response from network such as:

```
{
    "data": {
        "id": "56d177a27cb3331100465f72",
        "messagePrefix": "饭否每日精选",
        "content": "饭否每日精选",
        "topicId": 1345,
        "briefIntro": "饭否是国内著名的小众轻博客社区，氛围独特，清新自由。关注饭否每日精选，看看尘嚣之外，大家谈论什么。",
        "keywords": "饭否 精选 短博客 社区",
        "timeForRank": "2016-02-27T11:06:30.731Z",
        "lastMessagePostTime": "2016-11-06T02:42:52.111Z",
        "topicPublishDate": "2016-02-26T16:00:00.000Z",
        "createdAt": "2016-02-27T10:17:06.295Z",
        "updatedAt": "2016-11-01T04:30:08.973Z",
        "subscribersCount": 1207100,
        "subscribedStatusRawValue": 1,
        "subscribedAt": "2016-10-18T09:57:24.424Z",
        "rectanglePicture": {
            "thumbnailUrl": "https://cdn.ruguoapp.com/o_1ach3c6o011j91ljjtmdhlhnffo.jpg?imageView2/1/w/120/h/180",
            "middlePicUrl": "https://cdn.ruguoapp.com/o_1ach3c6o011j91ljjtmdhlhnffo.jpg?imageView2/1/w/200/h/300",
            "picUrl": "https://cdn.ruguoapp.com/o_1ach3c6o011j91ljjtmdhlhnffo.jpg?imageView2/0/h/1000",
            "format": "png"
        },
        "squarePicture": {
            "thumbnailUrl": "https://cdn.ruguoapp.com/o_1ach6nm599m94re1gvj14r71jaso.jpg?imageView2/0/w/120/h/120",
            "middlePicUrl": "https://cdn.ruguoapp.com/o_1ach6nm599m94re1gvj14r71jaso.jpg?imageView2/0/w/300/h/300",
            "picUrl": "https://cdn.ruguoapp.com/o_1ach6nm599m94re1gvj14r71jaso.jpg?imageView2/0/h/1000",
            "format": "png"
        },
        "pictureUrl": "https://cdn.ruguoapp.com/o_1ach3c6o011j91ljjtmdhlhnffo.jpg?imageView2/1/w/200/h/300",
        "thumbnailUrl": "https://cdn.ruguoapp.com/o_1ach6nm599m94re1gvj14r71jaso.jpg?imageView2/0/w/300/h/300"
    }
}
```

You can convert it to Dictionary or Array

```objc
NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
NSDictionary *subscribe = dictionary[@"data"];
```

## Store

Then you can call EasyDataKit method to store:

```objc
EDKEntity *subscribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subscribeEntity saveData:subscribe primaryColumn:@"id" relationShip:nil];
```

If you don't want to use "id" as primary column, you can pass nil to use rowId as primary column:

```objc
EDKEntity *subscribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subscribeEntity saveData:subscribe primaryColumn:nil relationShip:nil];
```

If you want to add a column manually:

```objc
NSMutableDictionary *subcribeInfo = [[NSMutableDictionary alloc] initWithDictionary:subscribe];
[subcribeInfo setObject:@1 forKey:@"isSubcribed"];
EDKEntity *subscribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subscribeEntity saveData:subcribeInfo primaryColumn:@"id" relationShip:nil];
```

If you have a relation with other object, notice the related field must be in the storage's data, it likes replace a field's value:

```objc
id rowId = [rectanglePictureEntity saveData:subscribe[@"rectanglePicture"] primaryColumn:nil relationShip:nil];

EDKEntity *subscribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subscribeEntity saveData:subscribe primaryColumn:@"id" relationShip:@{@"rectanglePicture": rowId}];
```

## Query

Query by id:
```objc
// select by id
EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
id object = [entity queryByPrimaryKey:@"581d2fdb36a4471100e311d6" withColumns:@[@"topicId", @"commentCount", @"topic"]];
NSLog(@"%@", object);

// relationship query
EDKEntity *topicEntity = [[EDKEntity alloc] initWithTableName:@"topics" dbName:nil];
id topic = [topicEntity queryByPrimaryKey:object[@"topic"] withColumns:nil];
NSLog(@"%@",topic);
```

Query by where:
```objc
NSArray *objects = [entity queryWithColumns:nil where:@"WHERE commentCount < ? and read = ?" arguments:@[@20, @1]];
NSLog(@"%@", objects);

Query all:
```objc
NSArray *objects = [entity queryAll];
NSLog(@"%@", objects);
```

Query a nest object then convert it to Dictionary or Array:
```objc
EDKEntity *subcribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
// select by id
id subcribe = [subcribeEntity queryByPrimaryKey:@"56d177a27cb3331100465f72" withColumns:@[@"squarePicture"]];
// subcribe is a json string
NSData *data = [subcribe[@"squarePicture"] dataUsingEncoding:NSUTF8StringEncoding];
NSError *error;
NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
NSLog(@"JSONDict: %@", jsonDict);
```

## Update

Normal update:
```objc
EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
[entity updateByPrimaryKey:@"5805905a319a9c1200833660" set:@{@"read": @"0", @"commentCount": @99}];
[entity updateWithSet:@{@"messageId": @"2333333"} where:@"WHERE commentCount > ?" arguments:@[@50]];
```

Update with dictionary:
```objc
NSDictionary *square = @{@"lisp": @"blablabla..."};
EDKEntity *subcribeEntity = [[EDKEntity alloc] initWithTableName:@"subcribes" dbName:nil];
[subcribeEntity updateByPrimaryKey:@"56d177a27cb3331100465f72" set:@{@"squarePicture": square}];
```

## Delete
```objc
EDKEntity *entity = [[EDKEntity alloc] initWithTableName:@"messages" dbName:nil];
// delete by id
[entity deleteByPrimaryKey:@"5805905a319a9c1200833660"];
// delete by where
[entity deleteWithWhere:@"WHERE popularity = ?" arguments:@[@"93"]];
// delete all
[entity deleteAll];
```

# License

EasyDataKit is available under the MIT license. See the LICENSE file for more info.
