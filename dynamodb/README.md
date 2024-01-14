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

## Day 2
### Homework
#### Find
> 1. Read some docs for the DynamoDB Streams Feature; can you think of a
>    compelling use case for this feature?

One use case could be to audit changes in the table. Another use case
could be to trigger workflows upon a change in the database (regardless of
the originator of the change). As an example, once some item is updated,
you could trigger a notification to be published to an SNS topic to
broadcast to whoever might care about that item.

> 2. Find one or more DynamoDB client libraries for your favorite
>    programming language. Explore how to perform CRUD operations using
>    that library.

Actually, we've already done this today. In fact, I had to migrate the
book's script from the JS AWS SDK v2 to v3! Take a look at the
`ProcessKinesisRecord.js` script; the same way we used the `PutCommand`,
we can also run other commands such as `DeleteCommand`, `QueryCommand`,
`ScanCommand`, etc... See several examples
[here](https://docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/javascript_dynamodb_code_examples.html).

> 3. DynamoDB supports object expiry using TTL. Find some docs on TTL and
>    think of some use cases for it.

I've used TTL here when storing metadata for open websocket connections.
Generally speaking, it can be useful any time you're storing temporary
data for some process that might fail in such a way that it cannot clean
up after itself. The docs also mention it's a more cost effective way to
delete things, which is true given that you don't need to send an explicit
delete command!

See the [docs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html).

#### Do
> 1. One way to improve the performance of Kinesis is to write records to
>    different partitions. Find some docs on partitioning Kinesis and
>    think of a stream partitioning scheme that would work with our sensor
>    data model.


Here's some
[docs](https://docs.aws.amazon.com/streams/latest/dev/key-concepts.html#partition-key)
on Kinesis partition keys. I think a natural partitioning scheme would be
to partition on the sensorId.

> 2. Modify various elements of our data pipeline - the `SensorData` table
>    definition, lambda function, and so on - to enable sensors to write
>    humidity related data to the pipeline (as a percentage).

All I needed to do here was add the following snippet to the ingestion Lambda:

```js
  const humidity = obj.humidity;
  if (humidity !== null) {
    item.Item.Humidity = {
      N: humidity.toString(),
    };
  }
```


## Day 3
### Homework
#### Find
> 1. We added a GSI to our table. Read some docs to se how much space GSIs use.

According to the DDB docs, the space used by a GSI is the sum of:
- The size of the base table primary key (partition && sort)
- The size of the index key attribute
- The size of the projected attributes
- 100 bytes of overhead per index item

> 2. Which commands are and aren't supported in Athena SQL?

The
[docs](https://docs.aws.amazon.com/athena/latest/ug/other-notable-limitations.html)
explicitly say `CREATE TABLE LIKE`, `DESCRIBE INPUT`, `DESCRIBE OUTPUT`, and
`UPDATE` are not supported, while `MERGE` is only supported for transactional
table formats. Stored procedures are also unsupported.

You also can't sort more than the 32 bit max int with an `ORDER BY`, nor
statically initialize an array with more than 254 arguments.

#### Do
> 1. In Day 2, we added humidity data to the mix. Make our input script spit
>    out humidities too. Then create a new table in Athena and query it!

Updated the script and I can see my new readings in DynamoDB... however I don't
want to create a new Athena table. The export is going to take a while.

> 2. Try modifying the data pipeline so that we write to a new table each day.

// TODO (Skipping this for now; we'd probably want to either create some job
that runs periodically to create new tables in advance, OR we check in the
ingestion lambda if today's table exists yet and create it... (I wonder if you
end up with races here though)).
