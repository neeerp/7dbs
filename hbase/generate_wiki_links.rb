import 'org.apache.hadoop.hbase.TableName'
import 'org.apache.hadoop.hbase.client.ConnectionFactory'
import 'org.apache.hadoop.hbase.client.Put'
import 'org.apache.hadoop.hbase.client.Scan'
import 'org.apache.hadoop.hbase.util.Bytes'

def jbytes(*args)
  return args.map { |arg| arg.to_s.to_java_bytes }
end


connection = ConnectionFactory.createConnection(@hbase.configuration)

wiki_table_name = TableName.valueOf('wiki')
links_table_name = TableName.valueOf('links')

wiki_table = connection.getTable(wiki_table_name)
links_table = connection.getTable(links_table_name)

scanner = wiki_table.getScanner(Scan.new)
linkpattern = /\[\[([^\[\]\|\:\#][^\[\]\|:]*)(?:\|([^\[\]\|]+))?\]\]/
count = 0

while (result = scanner.next())
  begin
    title = Bytes.toString(result.getRow())
    text = Bytes.toString(result.getValue(*jbytes('text', '')))

    if text
      put_to = nil
      text.scan(linkpattern) do |target, label|
        unless put_to
          put_to = Put.new(*jbytes(title))
          # put_to.setWriteToWAL(false)
        end

        target.strip!
        target.capitalize!

        label = '' unless label
        label.strip!

        put_to.addColumn(*jbytes("to", target, label))
        put_from = Put.new(*jbytes(target))
        put_from.addColumn(*jbytes("from", title, label))
        # put_from.setWriteToWAL(false)

        links_table.put(put_from)
      end
      links_table.put(put_to) if put_to
    end
    count += 1
    puts "#{count} pages processed (#{title})" if count % 500 == 0
  rescue
    puts "#{count} had an oopsie; moving on..."
  end
end

exit


