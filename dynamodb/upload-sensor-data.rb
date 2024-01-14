require 'aws-sdk'
require 'random-walk'
require 'time'
require 'base64'

STREAM_NAME = 'temperature-sensor-data'
if ARGV.length != 2
  abort("Must specify a sensor ID and N")
end

@sensor_id = ARGV[0]
@iterator_limit = ARGV[1].to_i

@kinesis_client = Aws::Kinesis::Client.new(region: 'us-east-1')

@temp_walk_array = RandomWalk.generate(6000..10000, @iterator_limit, 1)
@humidity_walk_array = RandomWalk.generate(1500..10000, @iterator_limit, 1)
@iterator = 0

def write_temp_reading_to_kinesis
  current_temp = @temp_walk_array[@iterator] / 100.0
  current_humidity = @humidity_walk_array[@iterator] / 100.0
  data = {
    :sensor_id => @sensor_id,
    :current_time => Time.now.to_i,
    :temperature => current_temp,
    :humidity => current_humidity
  }

  kinesis_record = {
    :stream_name => STREAM_NAME,
    :data => data.to_json,
    :partition_key => 'sensor-data'
  }

  @kinesis_client.put_record(kinesis_record)
  puts "Sensor #{@sensor_id} sent a temperature reading of #{current_temp} and humidity of #{current_humidity}"
  @iterator += 1
  if @iterator == @iterator_limit
    puts "The sensor has gone offline"
    exit(0)
  end
end

while true
  write_temp_reading_to_kinesis
  sleep 2
end
