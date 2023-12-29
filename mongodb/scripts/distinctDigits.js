distinctDigits = function (phone) {
  const number = phone.components.number + "";
  const seen = [];
  const result = [];
  let i = number.length;

  while (i--) {
    seen[+number[i]] = 1;
  }

  for (let i = 0; i < 10; i++) {
    if (seen[i]) {
      result[result.length] = i;
    }
  }

  return result;
};

map = function () {
  const digits = distinctDigits(this);
  emit(
    {
      digits: digits,
      country: this.components.country,
    },
    {
      count: 1,
    },
  );
};

reduce = function (k, values) {
  let total = 0;
  for (let i = 0; i < values.length; i++) {
    total += values[i].count;
  }

  return { count: total };
};

db.system.js.updateOne(
  { _id: "distinctDigits" },
  { $set: { value: distinctDigits } },
  { upsert: true },
);

// Make sure to clean up the last run.
db.phones.report.drop();

results = db.runCommand({
  mapReduce: "phones",
  map: map,
  reduce: reduce,
  finalize: function (key, reducedValue) {
    return { total: reducedValue.count };
  },
  out: "phones.report",
});
