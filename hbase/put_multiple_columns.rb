import 'org.apache.hadoop.hbase.TableName'
import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'
import 'org.apache.hadoop.hbase.util.Bytes'

connection = ConnectionFactory.createConnection(@hbase.configuration)

table_name = TableName.valueOf("wiki")
table = connection.getTable(table_name)

row_key = "Home"
p = Put.new(Bytes.toBytes(row_key))

p.addColumn(Bytes.toBytes("text"), Bytes.toBytes(""), Bytes.toBytes("Hello world"))
p.addColumn(Bytes.toBytes("revision"), Bytes.toBytes("author"), Bytes.toBytes("jimbo"))
p.addColumn(Bytes.toBytes("revision"), Bytes.toBytes("comment"), Bytes.toBytes("my first edit"))

table.put(p)

