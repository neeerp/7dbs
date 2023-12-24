# HBase

## Day 1
I was somewhat deterred during the setup. I got standalone HBase running just
fine initially... in fact, I did it in less than the 10 minutes that's claimed
in the [setup guide](https://hbase.apache.org/book.html#quickstart)!

Then I somehow managed to break everything (likely when I tried to change the
disk it lived on, or maybe because I killed it using `kill` instead of the
corresponding shell script) and I spent a couple of hours trying to get things
working again to no avail. Eventually, deleting everything and starting again
from the tar archive "fixed" things...

Moving on, when I came across the first JRuby example in the book, it wouldn't
work because it relied on deprecated/removed APIs. After struggling to
half-figure things out reading the [API
docs](https://hbase.apache.org/2.5/devapidocs/overview-summary.html) and having
the interpreter crash every other time I try to run my script, I caved and had
[Chat GPT
help](https://chat.openai.com/share/cdcbc63c-b271-4e45-99de-931f97fa1d33). Chat
GPT also told me to use the same deprecated APIs the book did, so I had to give
it a nudge...

```
hbase:001:0> require "../put_multiple_columns.rb"
=> true
hbase:002:0> get 'wiki', 'Home'
COLUMN                      CELL                                                                          
 revision:author            timestamp=2023-12-23T21:49:54.237, value=jimbo                                
 revision:comment           timestamp=2023-12-23T21:49:54.237, value=my first edit                        
 text:                      timestamp=2023-12-23T21:49:54.237, value=Hello world                          
1 row(s)
Took 0.0692 seconds
```

Huzzah!

### Reflections

I think this is my first time touching a NoSQL database (save for a little bit
of DynamoDB at work). I just read a paper on C-Store (a column oriented DB), so
it's cool that I'm getting to play with a column oriented database here.

Some noteworthy things:
- To alter a table schema, we need to literally "disable" the table!
- Row scoped operations are atomic
- "Column Families" have an advantage over direct columns in that each column
  family is stored together, and one may enable performance optimizations
  specific to column families

I don't quite get how the map of maps data representation works yet (I mean I
"get" it, but I don't think I understand how this gets physically
represented... granted, I still need to read up on HDFS as well...)

### Homework

#### Find
> 1. Figure out how to use the shell to do the following:
>   - Delete individual column values in a row
>   - Delete an entire row

Before going further, one 'interesting' thing to note: 
 - `hbase> help delete` spits out the generic help text
 - `hbase> help "delete"` spits out the help text for delete


 ```
 hbase:016:0> help "delete"
Put a delete cell value at specified table/row/column and optionally
timestamp coordinates.  Deletes must match the deleted cell's
coordinates exactly.  When scanning, a delete cell suppresses older
versions. To delete a cell from  't1' at row 'r1' under column 'c1'
marked with the time 'ts1', do:

  hbase> delete 'ns1:t1', 'r1', 'c1', ts1
  hbase> delete 't1', 'r1', 'c1', ts1
  hbase> delete 't1', 'r1', 'c1', ts1, {VISIBILITY=>'PRIVATE|SECRET'}

The same command can also be run on a table reference. Suppose you had a reference
t to table 't1', the corresponding command would be:

  hbase> t.delete 'r1', 'c1',  ts1
  hbase> t.delete 'r1', 'c1',  ts1, {VISIBILITY=>'PRIVATE|SECRET'}
```

Interesting... deletes are a 'suppression of data'. Anyhow, it looks to delete
an individual column value we'd do something like:

```
hbase> delete 'table', 'row_key', 'column_family:column_qualifier'
```

To delete the whole row, we'd just do
```
hbase> delete 'table', 'row_key'
```


> 2. Bookmark the HBase API documentation for the version of HBase you're using.
I'm ahead of the book on this one (I found the [API
docs](https://hbase.apache.org/2.5/devapidocs/overview-summary.html) in my
struggles above).


#### Do
> 1. Create a function called put_many that creates a Put instance, adds any
>    number of column-value pairs to it, and commits it to a table. The
>    signature should look like this:
>    ```ruby
>    def put_many(table_name, row, column_values)
>     # code
>    end
>    ```

We can more or less use the code we wrote in the `put_multiple_column`
script we modified earlier. See the `put_many.rb` script.

> 2. Define your put_many function by pasting it in the HBase shell and then call it like so:
> ```
> hbase> put_many 'wiki', 'Some title', {
> hbase*   "text:" => "Some article text",
> hbase*   "revision:author" => "jschmoe",
> hbase*   "revision:comment" => "no comment" }
> ```

Instead of pasting it, I can just `require` it:

```
hbase:018:0> require "../put_many.rb"
=> true
hbase:019:0> put_many 'wiki', 'Some title', {
hbase:020:1*   "text:" => "Some article text",
hbase:021:1*   "revision:author" => "jschmoe",
hbase:022:1*   "revision:comment" => "no comment" }
hbase:023:0> get 'wiki', 'Some title'
COLUMN                      CELL                                                                          
 revision:author            timestamp=2023-12-23T22:58:52.183, value=jschmoe                              
 revision:comment           timestamp=2023-12-23T22:58:52.183, value=no comment                           
 text:                      timestamp=2023-12-23T22:58:52.183, value=Some article text                    
1 row(s)
Took 0.0090 seconds                                                                                       
hbase:024:0>
```


