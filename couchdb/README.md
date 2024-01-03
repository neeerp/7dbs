# CouchDB

## Day 1
Some notes...
- The book was written when CouchDB 2.x was current; with CouchDB 3.x, we need
  to specify our credentials in every cURL request. This can be done using
  `curl -u [user]:[pw] [url]`.
- The JSON returned in every request is much easier to read using a
  pretty-printer (I usually use `jq`).

### Homework
#### Find

> 1. Find the CouchDB HHTTP API refrence documentation online.

Here's the [API Reference](https://docs.couchdb.org/en/stable/api/index.html).


> 2. We've alreadyt used `GET`, `POST`, `PUT`, and `DELETE`. What other HTTP
>    methods are supported?

Per the [Request Format and
Responses](https://docs.couchdb.org/en/stable/api/basics.html#request-format-and-responses)
section of the HTTP API Ref, CouchDB recognizes the following HTTP Methods:

- `GET`: Requests the specified resource
- `HEAD`: Retrieve the HTTP header of a `GET` request without the body of the response
- `POST`: Upload data and set values
- `PUT`: Put resources (create new objects)
    - I'm a bit confused by the wording relative to `POST`...
- `DELETE`: Delete a specified resource
- `COPY`: Copies documents and objects

To be honest, these descriptions are a bit unsatisfying. Yes, I truncated them
from what's in the actual ref, but even the actual ref left me with more
questions than answers.

#### Do
> 1. Use cURL to `PUT` a new document into the music database with a specific `_id` of your choice.

```sh
curl -u admin:couchdb -XPOST ${COUCH_ROOT_URL}/music/ -H "Content-Type: application/json" -d '{ "_id": "my-custom-id", "name": "My favourite band" }' | jq
{
  "ok": true,
  "id": "my-custom-id",
  "rev": "1-ffa5d8cb2b56d51032f224690e789a45"
}

curl -u admin:couchdb ${COUCH_ROOT_URL}/music/my-custom-id | jq                         13:33:55
{
  "_id": "my-custom-id",
  "_rev": "2-394b123df2970768dde5f165d530674a",
  "name": "My favourite band"
}
```

Interestingly, I somehow ended up with a second revision!


> 2. Use cURL to create a new database with a name of your choice, and then delete that database also via cURL.

First we create the DB: 
```sh
curl -u admin:couchdb -XPUT ${COUCH_ROOT_URL}/my-db | jq                                13:36:45
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    12  100    12    0     0    785      0 --:--:-- --:--:-- --:--:--   800
{
  "ok": true
}
curl -u admin:couchdb ${COUCH_ROOT_URL}/my-db | jq                                      13:38:02
{
  "instance_start_time": "1704134282",
  "db_name": "my-db",
  "purge_seq": "0-g1AAAABVeJzLYWBgYMpgLhdMzi9NzkhJcjA0MtczAELDHJBMHguQZGgAUv-BICuRAbfSRIakeoiaLACuiRhq",
  "update_seq": "0-g1AAAACXeJzLYWBgYMpgLhdMzi9NzkhJcjA0MtczAELDHJBMHguQZGgAUv-BICuDOZEhFyjAnmJuZp5ikIRFG26zEhmS6lEMMbG0NLdMMcOiPgsAuF0ogA",
  "sizes": {
    "file": 16686,
    "external": 0,
    "active": 0
  },
  "props": {},
  "doc_del_count": 0,
  "doc_count": 0,
  "disk_format_version": 8,
  "compact_running": false,
  "cluster": {
    "q": 2,
    "n": 1,
    "w": 1,
    "r": 1
  }
}
```

And then we delete it:
```sh
curl -u admin:couchdb -XDELETE ${COUCH_ROOT_URL}/my-db | jq                      ✘ INT  13:38:26
{
  "ok": true
}
curl -u admin:couchdb ${COUCH_ROOT_URL}/my-db | jq                                      13:38:48
{
  "error": "not_found",
  "reason": "Database does not exist."
}
```



> 3. CouchDB supports _attachments_, which are arbitrary files you can save
>    with documents (akin to email attachments). Using cURL, create a new
>    document that contains a text document as an attachment. Craft and execute
>    a cURL request that will return just that document's attachment.

```sh
curl -u admin:couchdb -XPOST ${COUCH_ROOT_URL}/music/ -H "Content-Type: application/json" -d '{ "name": "See Attached" }' | jq
{
  "ok": true,
  "id": "1f89a45e8a4d600a5c50907a3c0076fa",
  "rev": "1-59ec79dac3fd2af769207e032e29f1ec"
}
curl -u admin:couchdb -XPUT ${COUCH_ROOT_URL}/music/1f89a45e8a4d600a5c50907a3c0076fa/attached.txt -H "Content-Type: text/plain" -H "If-Match: 1-59ec79dac3fd2af769207e032e29f1ec" -d 'This is my attachment!\nCool, huh?'
{"ok":true,"id":"1f89a45e8a4d600a5c50907a3c0076fa","rev":"2-503766be1a7be41672141f9575c2ce2f"}
curl -u admin:couchdb ${COUCH_ROOT_URL}/music/1f89a45e8a4d600a5c50907a3c0076fa/attached.txt 
This is my attachment!\nCool, huh?%
```

## Day 2
Some notes include...
- I was unable to get the XML Album dump from the URL in the book, but
  luckily the wayback machine had a backup:
  [link](https://archive.org/download/JamendoXMLDump).
- I lost my mind trying to install `libxml-ruby`, and later, different versions
  of `ruby` in general. Both fail to compile, and nothing I've tried works. I
  ended up using `nokogiri` instead, since I can at least install the gem and
  use it with my system ruby.

### Homework
#### Find
> 1. We've seen `emit` outputting string keys. What other keys types can it
>    support? What happens when you emit an array as a key?

According to the docs on views... "...you can place whatever you like in the
key parameter to the `emite()` function."
([source](https://docs.couchdb.org/en/stable/ddocs/views/intro.html#find-one)).

When you use an array in the key, you've created a "complex key". CouchDB still
has a well defined sort order on such keys, though the docs literally say the
rules for this are not documented:
[source](https://docs.couchdb.org/en/stable/ddocs/views/joins.html#optimization-using-the-power-of-view-collation).



> 2. Find a list of available URL parameters that can be appended to view
>    requests. What do they do?

Here's the [api ref](https://docs.couchdb.org/en/stable/api/ddoc/views.html)
for the view resource. There are quite a lot of parameters, though some are
aliases (e.g. `startkey` and `start_key`). Here's a few options:
- `startkey`/`endkey`: returns records with keys in the given range
- `startkey_docid`/`endkey_docid`: are similar, but based off document ids instead
- `conflicts`: include conflicts information in the response
- `descending`: does the obvious
- `group`: Groups results using a `reduce`
- `attachments`: include base64 encoded content of any attachments in the documents
- `att_encoding_info`: include attachment encoding info
- `inclusive_end`: whether the specified end key should be included in the result
- `skip`: offset into the result list
- `sorted`: whether to sort returned rows

#### Do
> 1. The import script `import_from_jamendo.rb` assigned a random number to
>    each artist. Create a mapper function that emits key/value pairs where hte
>    key is the random number and the value is the band's name; save this in a
>    new design document named `_design/random` with the index name `artist`.

Done using the function `artistsByRandomKey` in `js-scripts/mappers.js`.

> 2. Craft a cURL request that will retrieve a random arist.

See the `d2-hw-q2` case in `./curl_helper.sh`.

> 3. The import script also added a `random` property for each album, track,
>    and tag. Create three additional views in the `_design/random` design
>    document with the index names `album`, `track`, and `tag` to match the
>    earlier `artist` view.




