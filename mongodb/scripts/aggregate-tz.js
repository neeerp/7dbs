const { MongoClient, ServerApiVersion } = require("mongodb");

const uri =
  "mongodb://127.0.0.1:27017/book?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.1.1";

const client = new MongoClient(uri, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  },
});

async function printAgg(dbName, collectionName, pipeline) {
  const db = client.db(dbName);
  const collection = db.collection(collectionName);

  const aggregateCursor = await collection.aggregate(pipeline);

  for await (const doc of aggregateCursor) {
    console.log(doc);
  }
}

async function averagePopInLondonTZ() {
  const pipeline = [
    {
      $match: {
        timezone: {
          $eq: "Europe/London",
        },
      },
    },
    {
      $group: {
        _id: "averagePopulation",
        avgPop: {
          $avg: "$population",
        },
      },
    },
  ];

  await printAgg("book", "cities", pipeline);
}

async function londonTZByPopulation() {
  const pipeline = [
    {
      $match: {
        timezone: {
          $eq: "Europe/London",
        },
      },
    },
    {
      $sort: {
        population: -1,
      },
    },
    {
      $project: {
        _id: 0,
        name: 1,
        population: 1,
      },
    },
  ];

  await printAgg("book", "cities", pipeline);
}

async function sandboxAggregation() {
  const pipeline = [
    {
      $bucket: {
        groupBy: "$population",
        boundaries: [0, 10000, 100000, 250000, 500000, 1000000],
        default: "Unknown",
        output: {
          count: { $sum: 1 },
          timezones: {
            $push: {
              name: "$name",
              timezone: "$timezone",
              population: "$population",
            },
          },
          averagePopulation: { $avg: "$population" },
        },
      },
    },
    {
      $sort: {
        averagePopulation: -1,
      },
    },
  ];

  await printAgg("book", "cities", pipeline);
}

async function run() {
  try {
    await client.connect();
    // console.log("Average population of cities in London Time Zone:");
    // await averagePopInLondonTZ();
    //
    // console.log();
    //
    // console.log("Cities in London Time Zone sorted by Population:");
    // await londonTZByPopulation();
    await sandboxAggregation();
  } finally {
    client.close();
  }
}

run().catch(console.dir);
