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


## Day 2
### Homework
#### Find

> 1. Find a discussion or article describing the pros and cons of compression in HBase

Here's a
[paper](https://www.academia.edu/download/75146228/Paper_47-Impact_of_Data_Compression_on_the_Performance_of_Column.pdf)
discussing different compression algorithms used by HBase, and here's an
[article](https://community.cloudera.com/t5/Community-Articles/Compression-in-HBase/ta-p/247244)
on Cloudera's community website contrasting the differnet compression
algorithms.

The obvious upside of compression is the reduced memory and storage
requirements. Apparently, CPU usage does not increase significantly when
compression is used, and many operations can be performed directly on the
compressed data!

Downsides may include increased difficulty in use. For example, the LZO
algorithm cannot be bundled with HBase by default, and this has apparently
caused problems/outages when spinning up new clusters! Moreover, one must
reason about which algorithm to use for the data at hand, as poor choices may
have negative performance (and even space usage) implications. It looks like
the use of compression shifts additional complexity and considerations on the
programmer.

> 2. Find an article explaining how Bloom filters work in General and how they benefit HBase.

I found this random Linked In article in my top google results:
[link](https://www.linkedin.com/pulse/bloom-filters-hbase-kuldeep-deshpande/).

From the sounds of it, HBase uses bloom filters in-memory when trying to
determine where a row is stored in order to avoid having to perform disk IO to
check whether a file contains the row.

As for how Bloom Filters work in general... I think the book described them
already, though I already knew from an undergrad data structures course. The
gist of it is that it's a probabilistic membership test; it has no false
negatives but instead may produce false positives. To insert a value, you hash
the value and flip the corresponding bits in a long bit array to 1. To test
membership of a value, you hash the value and check if the corresponding bits
are already all 1.

> 3. Aside from the algorithm, what other column family options relate to compression?

The Data Block Encoding option (`DATA_BLOCK_ENCODING`) is directly relevant; see the [HBase Docs on Compression](https://hbase.apache.org/book.html#compression).

> 4. How does the type of data and expected usage patterns inform column family compression options?

See ['Which Compressor or Data Block Encoder To Use'](https://hbase.apache.org/book.html#data.block.encoding.types) in the HBase Docs. This [message](https://lists.apache.org/thread/85ymv1vnw13szxq1o1mhkm815pv47t73) in an email thread gives a very brief summary:

> So as a general guideline I'd say:
> o If you have long keys (compared to the values) or many columns, use a prefix encoder. Only use FAST_DIFF.
> o If the values are large (and not precompressed as in images), use a block compressor (SNAPPY, LZO, GZIP, etc)
> o Use GZIP for cold data
> o Use SNAPPY or LZO for hot data.
> o In most cases you do want to enable SNAPPY or LZO by default (low perf overhead + space savings).

#### Do

> Downlad the food pyramid dataset
> [here](https://inventory.data.gov/dataset/794cd3d7-4d28-4408-8f7d-84b820dbf7f2/resource/6b78ec0c-4980-4ad8-9cbd-2d6eb9eda8e7/download/myfoodapediadata.zip)
> (the link in the book was dead).
> 
> This data consists of pairs of `<Food_Display_Row>` tags; each row has an
> integer `<Food_Code>` and string `Display_Name`, and other facts in various
> tags.

> 1. Create a table called `foods` with a single column family to store facts.
>    What should be the row key? What column family options make sense for this
>    data?

The row key should probably be the `Display_Name` attribute.

```
hbase:001:0> create 'foods', { NAME => 'fact', VERSIONS => 1, BLOOMFILTER => 'ROWCOL' }
Created table foods
Took 0.9145 seconds
=> Hbase::Table - foods
hbase:002:0>
```


> 2. Create a new JRuby script to import the food data; use the streaming XML parsing style we used earlier.

See `parse_food.rb`.

> 3. Using the HBase shell, query the `foods` table for information about your favourite foods.
I had to enumerate the row keys using `count 'foods', { INTERVAL => 1 }` (per
[Stack
Overflow](https://stackoverflow.com/questions/5218085/how-to-list-all-row-keys-in-an-hbase-table)) to find
the row key for a food. Not my favourite food, but check out sesame seeds:

```
hbase:006:0> get 'foods', 'Sesame seeds'
COLUMN                                                 CELL
 fact:Added_Sugars                                     timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Alcohol                                          timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Calories                                         timestamp=2023-12-26T11:57:49.697, value=212.62500
 fact:Display_Name                                     timestamp=2023-12-26T11:57:49.697, value=Sesame seeds
 fact:Drkgreen_Vegetables                              timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Drybeans_Peas                                    timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Factor                                           timestamp=2023-12-26T11:57:49.697, value=.25000
 fact:Food_Code                                        timestamp=2023-12-26T11:57:49.697, value=43103000
 fact:Fruits                                           timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Grains                                           timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Increment                                        timestamp=2023-12-26T11:57:49.697, value=.25000
 fact:Meats                                            timestamp=2023-12-26T11:57:49.697, value=2.64562
 fact:Milk                                             timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Multiplier                                       timestamp=2023-12-26T11:57:49.697, value=1.00000
 fact:Oils                                             timestamp=2023-12-26T11:57:49.697, value=2.45383
 fact:Orange_Vegetables                                timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Other_Vegetables                                 timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Portion_Amount                                   timestamp=2023-12-26T11:57:49.697, value=.25000
 fact:Portion_Default                                  timestamp=2023-12-26T11:57:49.697, value=1.00000
 fact:Portion_Display_Name                             timestamp=2023-12-26T11:57:49.697, value=cup
 fact:Saturated_Fats                                   timestamp=2023-12-26T11:57:49.697, value=2.52000
 fact:Solid_Fats                                       timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Soy                                              timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Starchy_vegetables                               timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Vegetables                                       timestamp=2023-12-26T11:57:49.697, value=.00000
 fact:Whole_Grains                                     timestamp=2023-12-26T11:57:49.697, value=.00000
1 row(s)
Took 0.0329 seconds
```

## Day 3
We get to set up our own EMR cluster! Fun!

### Homework
#### Find
> 1. Use the help interface `aws` for the CLI tool to see which commands
>    are available for the `emr` subcommand. Read through the help
>    material for some of these commands to get a sense of some of the
>    capabilities offered by EMR that we didn't cover in today's cluster
>    building exercise. Pay special attention to scaling-related commands.

Running `aws emr help` gives us a man page on EMR. Running `aws emr <command>
help` in turn gives us a man page on the subcommands. I looked up some commands
while waiting for my cluster to spin up.


> 2. Go to the EMR documentation and read up on how to use S3 as a data
>    store for HBase clusters.


#### DO

> 1. In your HBase shell that you're accessing via SSH, run some of the
>    cluster metadata commands we explored on Day 2 such as `scan
>    'hbase:meta'`. MAke note of anything that's fundamentally different
>    from what we saw on the locally running standalone HBase.

> 2. Navigate around the EMR section of your AWS browser console and find
>    the console specific to your running HBase cluster. Resize your
>    cluster down to just two machiens by removing one of the slave nodes
>    (aka 'core' nodes). Then increase the cluster size back to three.

> 3. Resizing a cluster in the AWS console is nice, but that's not an
>    automatable approach. The `aws` CLI tool enables you to resize a
>    cluster programmatically. Consult the docs for `emr
>    modify-instance-groups` to find out how it works. Remove a machine
>    from your cluster using that command!
