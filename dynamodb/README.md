# DynamoDB
## Day 1
Some miscellaneous notes:
- Dynamo has 5 basic 'scalar' types:
    - `S`: String of length >= 1
    - `N`: Numeric (Int or float; delivered as a string)
    - `B`: Base64-encoded binary data
    - `BOOL`
    - `NULL`
- Dynamo also has set types; note that "set" implies the elements are unique:
    - `SS`: String set
        - e.g. `["Hello", "World"]`
    - `NS`: Number set
        - e.g. `["123", "4.56"]`
    - `BS`: Binary set (base 64)
        - e.g. `["TGFycnkK", "TW9lCg=="]`
    - `L`: List of multiple types
        - e.g. `[{"S": "foo"}, {"N": "42"}]`
    - `M`: Map with string keys and any type values:
        - e.g. `{"FavouriteBook": {"S": "Seven Databases in Seven Weeks"}}`

- Dynamo also lets you store any arbitrary JSON.
- Dynamo has an item size limit of 400KB
- You can modify global secondary indexes after a table is created, however _you cannot modify local secondary indexes (i.e. within a partition)_.

### Homework
#### Find
> 1. DynamoDB does have a specific formula that's used to calculate the
>    number of partitions for a table. Do some googling and find the
>    formula.

It's the number of RCUs and WCUs as well as data stored:
```
num_partitions = RCUs / 3000 + WCUs / 1000 + D/10GB // Rounded up
```

> 2. Browse the
>    [documentation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html)
>    for the DynamoDB streams feature.

DynamoDB streams capture every modification to a table, recording the
primary key of the modified item. Some notes:
- A stream record can also include a 'before' and 'after' of the entire item. 
- Stream records are stored for 24h. 
- There's no performance overhead; streams are asynchronous
- Stream records are organized into _shards_; a shard contains metadata
  required to access and iterate its contained records.
    - Shards are hierarchical; an application processing a stream must
      first process a parent shard before processing a child shard.

> 3. We mentioned limits on item sizes. Read the limits in the DynamoDB
>    [documentation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ServiceQuotas.html)
>    to see which other limitations apply.


- One RCU = One strongly consistent read per second, or two eventually
  consistent reads per second for items up to 4KB
- One WCU = One write per second, for items up to 1KB in size
- Transactional reads/writes require two RCUs/WCUs for one operation/second
- You can have up to 50 concurrent import jobs via S3; with a total import
  source object size of no more than 15TB. Each import job may take up to
  5000 S3 objects (see also [S3 import blog announcement](https://aws.amazon.com/blogs/database/amazon-dynamodb-can-now-import-amazon-s3-data-into-a-new-table/)).
- You can have up to 2.5k tables, or 10k tables if you ask politely
- You can have up to 5 local secondary indexes and 20 global secondary indexes per table
- You can project up to 100 attributes into all of a table's local and global secondary indexes
- Partition keys must be between 1 and 2KB
- Sort keys must be between 1 and 1KB
- Partitions cannot exceed 10GB (this impacts things like indexes too)
- The 400KB limit is shared with both the item's data and entries in indexes.
- Attributes can be nested at most 32 layers deep
- Expression strings cannot exceed 4KB
- Expressions can have at most 300 operators/functions (and only up to 100 `IN` operands).
- Transactions cannot contain more than 100 unique items and 4MB of data
- You can't have more than 500 `CreateTable`, `UpdateTable`, and
  `DeleteTable` requests running simultaneously
- You can't `BatchGetItem` more than 100 items at a time, and their total size cannot exceed 16MB.
- You can't `BatchWriteItem` more than 25 items at a time, and their total size cannot exceed 16MB.
- Scans will return no more than 1MB per call



#### Do
> 1. Using the formula you found above for number of partitions for a
>    table, calculate how many partitions would be used for a table
>    holding 100GB of data and assigned 2000 RCUs and 3000 WCUs.

`2000/3000 + 3000/1000 + 100/10 = 2/3 + 3 + 10 ~= 14`



> 2. If you were storing tweets in DynamoDB, how would you do so using
>    DynamoDB's supported data types?

Maybe something like
```
S - URL (Local Secondary Index?)
S - Text (Sort key?)
S - Author (Hash Key?)
N - Date (Sort key?)
```

I'm not really sure what I'm doing though. Author seems like something
reasonable to partition on, and date and text seem like things you'd want
to search by. Not sure if URL should actually be the hash key...




> 3. In addition to `PutItem` operations, DynamoDB offers _update item_
>    operations that enable you to modify an item if a conditional
>    expression is satisfied. Take a look at the
>    [documentation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.ConditionExpressions.html)
>    for conditional expressions and perform a conditional update
>    operation on an item in the `ShoppingCart` table from earlier.

Here, we use a conditional expression to ensure we don't write the same item twice:

```sh
$ aws dynamodb put-item --table-name ShoppingCart --item {"ItemName": {"S": "Tickle Me Ernie"}} --condition-expression attribute_not_exists(ItemName)
$ aws dynamodb put-item --table-name ShoppingCart --item {"ItemName": {"S": "Tickle Me Ernie"}} --condition-expression attribute_not_exists(ItemName)
An error occurred (ConditionalCheckFailedException) when calling the PutItem operation: The conditional 
request failed
```

