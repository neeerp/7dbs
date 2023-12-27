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


> 2. Look up how to construct regular expressions in Mongo

> 3. Acquaint yourself with the cli `db.help` and `cb.collections.help` output

> 4. Find a Mongo driver in your language of choice

#### Do
> 1. Print a JSON document containing `{"hello": "world"}`

> 2. Select a town via a case-insensitive regular expression containing the
>    word _new_

> 3. Find all cities whose names contain an _e_ and are famous for food or beer

> 4. Create a new database named `blogger` with a collection named `articles`.
>    Insert a new article with an author name and email, creation date, and
>    text.

> 5. Update the article with an array of comments, containing a comment with an
>    author and text.

> 6. Run a query from an external JavaScript file that you create yourself.
