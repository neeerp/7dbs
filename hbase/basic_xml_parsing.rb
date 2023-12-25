require 'time'

import 'org.apache.hadoop.hbase.TableName'
import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'
import 'org.apache.hadoop.hbase.util.Bytes'
import 'javax.xml.stream.XMLStreamConstants'

factory = javax.xml.stream.XMLInputFactory.newInstance()
reader = factory.createXMLStreamReader(java.lang.System.in)

document = nil
buffer = nil
count = 0

connection = ConnectionFactory.createConnection(@hbase.configuration)

table_name = TableName.valueOf('wiki')
table = connection.getTable(table_name)

while reader.has_next
  type = reader.next

  if type == XMLStreamConstants::START_ELEMENT
    case reader.local_name
    when 'page' then document = {}
    when /title|timestamp|username|comment|text/ then buffer = []
    end
  elsif type == XMLStreamConstants::CHARACTERS
    buffer << reader.text unless buffer.nil?
  elsif type == XMLStreamConstants::END_ELEMENT
    case reader.local_name
    when /title|timestamp|username|comment|text/
      document[reader.local_name] = buffer.join
    when 'revision'
      key = document['title'].to_java_bytes
      ts = (Time.parse document['timestamp']).to_i

      p = Put.new(key, ts)
      p.addColumn(Bytes.toBytes("text"), Bytes.toBytes(""), Bytes.toBytes(document['text']))
      p.addColumn(Bytes.toBytes("revision"), Bytes.toBytes("author"), Bytes.toBytes(document['username'].to_s))

      p.addColumn(Bytes.toBytes("revision"), Bytes.toBytes("comment"), Bytes.toBytes(document['comment'].to_s))
      table.put(p)

      count += 1
      if count % 500 == 0
        puts "#{count} records inserted (#{document['title']})"
      end
    end
    # Same as start
  end
end

exit
