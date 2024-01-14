-- Modified Athena query to create a table from my Dynamo -> S3 export
CREATE EXTERNAL TABLE IF NOT EXISTS sensor_data (
    Item struct <
        sensorid:struct<s:string>,
        currenttime:struct<n:bigint>,
        temperature:struct<n:float>
    >
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES ('paths'='SensorId,CurrentTime,Temperature')
LOCATION 's3://sensor-data-david/AWSDynamoDB/01705264164004-79087cdf/data/'
