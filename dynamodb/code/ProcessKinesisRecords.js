const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({ region: "us-east-1" });

const ddbDocClient = DynamoDBDocumentClient.from(client);

exports.kinesisHandler = async function (event, context, callback) {
  const kinesisRecord = event.Records.at(-1);
  console.log(kinesisRecord);
  const data = Buffer.from(kinesisRecord.kinesis.data, "base64").toString(
    "ascii",
  );

  console.log(data);

  const obj = JSON.parse(data);

  const sensorId = obj.sensor_id;
  const currentTime = obj.current_time;
  const temperature = obj.temperature;

  const item = {
    TableName: "SensorData",
    Item: {
      SensorId: {
        S: sensorId,
      },
      CurrentTime: {
        N: currentTime.toString(),
      },
      Temperature: {
        N: temperature.toString(),
      },
    },
  };

  const humidity = obj.humidity;
  if (humidity !== null) {
    item.Item.Humidity = {
      N: humidity.toString(),
    };
  }

  try {
    const data = await ddbDocClient.send(new PutItemCommand(item));
    console.log(data);
    callback(null, data);
  } catch (e) {
    console.log(e, e.stack);
    callback(e.stack);
  }
};
