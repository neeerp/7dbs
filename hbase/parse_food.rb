require 'time'

import 'org.apache.hadoop.hbase.TableName'
import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'
import 'org.apache.hadoop.hbase.util.Bytes'
import 'javax.xml.stream.XMLStreamConstants'

ROW_TAG = 'Food_Display_Row'
DISPLAY_NAME = 'Display_Name'
FACT_CF = Bytes.toBytes('fact')

factory = javax.xml.stream.XMLInputFactory.newInstance()
reader = factory.createXMLStreamReader(java.lang.System.in)

document = nil
buffer = nil
count = 0

connection = ConnectionFactory.createConnection(@hbase.configuration)

table_name = TableName.valueOf('foods')
table = connection.getTable(table_name)

while reader.has_next
  type = reader.next

  if type == XMLStreamConstants::START_ELEMENT
    case reader.local_name
    when ROW_TAG then document = {}
    else buffer = []
    end
  elsif type == XMLStreamConstants::CHARACTERS
    buffer << reader.text unless buffer.nil?
  elsif type == XMLStreamConstants::END_ELEMENT
    case reader.local_name
    when ROW_TAG
      key = document[DISPLAY_NAME].to_java_bytes
      p = Put.new(key)

      document.each do |k, v|
        p.addColumn(FACT_CF, Bytes.toBytes(k), Bytes.toBytes(v))
      end
      table.put(p)

      count += 1
      if count % 500 == 0
        puts "#{count} records inserted (#{document['title']})"
      end
    else
      document[reader.local_name] = buffer.join
    end
  end
end
