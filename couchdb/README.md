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
