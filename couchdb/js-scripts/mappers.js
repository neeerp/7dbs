function artistsByNameMapper(doc) {
  if ("name" in doc) {
    emit(doc.name, doc._id);
  }
}

function albumsByNameMapper(doc) {
  if ("name" in doc && "albums" in doc) {
    for (album of doc.albums) {
      const key = album.title || album.name;
      const value = { by: doc.name, album: album };
      emit(key, value);
    }
  }
}
