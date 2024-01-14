const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({ region: "us-east-1" });

const ddbDocClient = DynamoDBDocumentClient.from(client);

exports.kinesisHandler = async function (event) {
  for (const kinesisRecord of event.Records) {
    console.debug(kinesisRecord);
    let data = Buffer.from(kinesisRecord.kinesis.data, "base64").toString(
      "ascii",
    );
    console.debug(data);

    try {
      const obj = JSON.parse(data);

      const sensorId = obj.sensor_id;
      const currentTime = obj.current_time;
      const temperature = obj.temperature;
      const humidity = obj.humidity;

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

      if (humidity !== undefined) {
        item.Item.Humidity = {
          N: humidity.toString(),
        };
      }

      data = await ddbDocClient.send(new PutItemCommand(item));
      console.log(data);
    } catch (e) {
      console.error(e, e.stack);
    }
  }
};
