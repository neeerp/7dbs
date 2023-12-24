import 'org.apache.hadoop.hbase.TableName'
import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'
import 'org.apache.hadoop.hbase.util.Bytes'

def put_many(table_name, row, column_values)
  connection = ConnectionFactory.createConnection(@hbase.configuration)

  table_name = TableName.valueOf(table_name)
  table = connection.getTable(table_name)

  p = Put.new(Bytes.toBytes(row))

  column_values.each do |c, v| 
    cf, cq = split_key(c)
    p.addColumn(Bytes.toBytes(cf), Bytes.toBytes(cq), Bytes.toBytes(v))
  end

  table.put(p)
end

def split_key(key)
  cf, *cq = key.split(':')
  cq = cq.length == 1 ? cq[0] : ""
  return cf, cq
end
