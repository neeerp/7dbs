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

async function run() {
  try {
    await client.connect();

    await client.db("admin").command({ ping: 1 });
    console.log("You've successfully connected to MongoDB!");
  } finally {
    client.close();
  }
}

run().catch(console.dir);
