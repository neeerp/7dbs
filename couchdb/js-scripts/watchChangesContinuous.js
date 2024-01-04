const http = require("http");
const events = require("events");

exports.createWatcher = function (options) {
  const watcher = new events.EventEmitter();

  watcher.host = options.host || "localhost";
  watcher.port = options.port || 5984;
  watcher.last_seq = options.last_seq || 0;
  watcher.db = options.db || "_users";

  watcher.start = function () {
    const FEED_TYPE = "continuous";
    // Feed specific impl
    const httpOptions = {
      host: watcher.host,
      port: watcher.port,
      path: `/${watcher.db}/_changes?feed=${FEED_TYPE}&include_docs=true&since=${watcher.last_seq}`,
      headers: {
        Authorization: `Basic ${new Buffer("admin:couchdb").toString(
          "base64",
        )}`,
      },
    };

    http
      .get(httpOptions, function (res) {
        let buffer = "";
        res.on("data", function (chunk) {
          buffer += chunk;
          let boundary = buffer.indexOf("\n");
          while (boundary !== -1) {
            const jsonStr = buffer.substring(0, boundary);
            buffer = buffer.substring(boundary + 1);

            try {
              const jsonObj = JSON.parse(jsonStr);
              watcher.emit("change", jsonObj);
            } catch (e) {
              watcher.emit("error", `Error parsing JSON: ${e}`);
            }

            boundary = buffer.indexOf("\n");
          }
        });
        res.on("end", function () {
          console.log("Stream end");
        });
      })
      .on("error", function (err) {
        watcher.emit("error", err);
      });
  };

  return watcher;
};

// If this script is run directly, start watching couchdb
if (!module.parent) {
  exports
    .createWatcher({
      db: process.argv[2],
      last_seq: process.argv[3],
    })
    .on("change", console.log)
    .on("error", console.error)
    .start();
}
