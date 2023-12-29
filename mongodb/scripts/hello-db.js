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

    const database = client.db("homework");
    const hello = database.collection("hello");

    const doc = {
      hello: "world",
    };

    const result = await hello.insertOne(doc);
    console.log(`A document was inserted with the _id: ${result.insertedId}`);
    console.log(
      await hello.findOne(
        { _id: result.insertedId },
        { projection: { hello: true, _id: false } },
      ),
    );

    console.log(await hello.createIndex("hello"));
  } finally {
    client.close();
  }
}

run().catch(console.dir);
