# MongoDB

## Day 1
Interesting notes include:
- Mongo's ID generation uses a twitter snowflake-esque scheme
- The 'code query' syntax in the book is no longer valid; instead of passing a
  function directly into `find()`, it appears you _must_ pass in an object. You
  can put your function or shorthand query string under the `$where` key.

### Homework
#### Find
> 1. Bookmark the online MongoDB docs and read up on something you found intriguing today.

Here are the [docs](https://www.mongodb.com/docs/manual/).

One interesting thing I noticed is that the docs warn us that there's a
difference between `mongosh` and the mongo Node driver; we should be careful to
note when we're reading docs for one or the other.

I also see some mention in the docs on drivers about 'ODM's like Mongoose and
Prisma. I've worked with Prisma before!


> 2. Look up how to construct regular expressions in Mongo

I believe these are the
[docs](https://www.mongodb.com/docs/current/reference/operator/query/regex/) on
using regex in queries.

TLDR: `<field>: /pattern/<opts>`. 

Certain PCRE features are only supported via the Mongo `$regex` operator, with
the regex given as a string.

> 3. Acquaint yourself with the cli `db.help` and `cb.collections.help` output

Interesting... `db.help` prints out usage instructions, however `typeof
db.help` tells us it's a function. I wonder how that string output works.

At any rate, it seems like a lot of other objects have a `.help` key. Awesome,
no need to resort to Google or the docs (whose search kind of sucks btw) right
away!

> 4. Find a Mongo driver in your language of choice

Let's go with Node since a later question in the homework asks us to write a
node script to talk to the DB.

See `scripts/ping-db.js`.

#### Do
> 1. Print a JSON document containing `{"hello": "world"}`

See `./scripts/hello-db.js`.

> 2. Select a town via a case-insensitive regular expression containing the
>    word _new_

```
book> db.towns.findOne({ name: /new/i })
{
  _id: ObjectId('658c46c6a1da794d92dae5c5'),
  name: 'New York',
  population: 22200000,
  lastCensus: ISODate('2016-07-01T00:00:00.000Z'),
  famousFor: [ 'the MOMA', 'food', 'Derek Jeter' ],
  mayor: { name: 'Bill de Blasio', party: 'D' }
}
```

> 3. Find all cities whose names contain an _e_ and are famous for food or beer

```
db.towns.find({ name: /e/i, $or: [{ famousFor: 'food' }, { famousFor: 'beer' }] })
[
  {
    _id: ObjectId('658c46c6a1da794d92dae5c5'),
    name: 'New York',
    population: 22200000,
    lastCensus: ISODate('2016-07-01T00:00:00.000Z'),
    famousFor: [ 'the MOMA', 'food', 'Derek Jeter' ],
    mayor: { name: 'Bill de Blasio', party: 'D' }
  }
]
```

> 4. Create a new database named `blogger` with a collection named `articles`.
>    Insert a new article with an author name and email, creation date, and
>    text.

```
book> use blogger
switched to db blogger
blogger> db.articles.insertOne({ author: "Fred", email: "Fred@Fred.fr", createdAt: Date(), text: "Hello world" })
{
  acknowledged: true,
  insertedId: ObjectId('658c93caa1da794d92dae5c8')
}
```

> 5. Update the article with an array of comments, containing a comment with an
>    author and text.

```
blogger> db.articles.updateOne({ _id: ObjectId('658c93caa1da794d92dae5c8') }, { $set: { comments: [{ author: "Bob", text: "Actually, I disagree." }] } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
blogger> db.articles.find()
[
  {
    _id: ObjectId('658c93caa1da794d92dae5c8'),
    author: 'Fred',
    email: 'Fred@Fred.fr',
    createdAt: 'Wed Dec 27 2023 16:14:50 GMT-0500 (Eastern Standard Time)',
    text: 'Hello world',
    comments: [ { author: 'Bob', text: 'Actually, I disagree.' } ]
  }
]
```

> 6. Run a query from an external JavaScript file that you create yourself.

See `./scripts/`.
