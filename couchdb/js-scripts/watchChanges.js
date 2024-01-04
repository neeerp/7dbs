const http = require("http");
const events = require("events");

exports.createWatcher = function (options) {
  const watcher = new events.EventEmitter();

  watcher.host = options.host || "localhost";
  watcher.port = options.port || 5984;
  watcher.last_seq = options.last_seq || 0;
  watcher.db = options.db || "_users";

  watcher.start = function () {
    // Feed specific impl
    const httpOptions = {
      host: watcher.host,
      port: watcher.port,
      path: `/${watcher.db}/_changes?feed=longpoll&include_docs=true&since=${watcher.last_seq}`,
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
        });
        res.on("end", function () {
          const output = JSON.parse(buffer);
          if (output.results) {
            watcher.last_seq = output.last_seq;
            for (change of output.results) {
              watcher.emit("change", change);
            }
            watcher.start();
          } else {
            watcher.emit("error".output);
          }
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
