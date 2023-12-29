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

async function populatePhones(area, start, stop) {
  const db = client.db("book");
  const phones = db.collection("phones");

  for (let i = start; i < stop; i++) {
    const country = 1 + ((Math.random() * 8) << 0);
    const num = country * 1e10 + area * 1e7 + i;
    const fullNumber = `+${country} ${area}-${i}`;
    const doc = {
      _id: num,
      components: {
        country: country,
        area: area,
        prefix: (i * 1e-4) << 0,
        number: i,
      },
      display: fullNumber,
    };

    await phones.insertOne(doc);
  }
}

async function run() {
  try {
    await client.connect();
    await populatePhones(800, 5550000, 5650000);
  } finally {
    client.close();
  }
}

run().catch(console.dir);
