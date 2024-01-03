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

function artistsByRandomKey(doc) {
  if ("name" in doc && "random" in doc) {
    emit(doc.random, doc.name);
  }
}

function albumsByRandomKey(doc) {
  if ("albums" in doc) {
    for (album of doc.albums) {
      if ("random" in album) {
        emit(album.random, album.name);
      }
    }
  }
}

function tracksByRandomKey(doc) {
  if ("albums" in doc) {
    for (album of doc.albums) {
      if ("tracks" in album) {
        for (track of album.tracks) {
          emit(track.random, track.name);
        }
      }
    }
  }
}

function tagsByRandomKey(doc) {
  if ("albums" in doc) {
    for (album of doc.albums) {
      if ("tracks" in album) {
        for (track of album.tracks) {
          if ("tags" in track) {
            for (tag of track.tags) {
              emit(tag.random, tag.idstr);
            }
          }
        }
      }
    }
  }
}

function tagsByRandomKey(doc) {
  if ("albums" in doc) {
    for (album of doc.albums) {
      if ("tracks" in album) {
        for (track in album.tracks) {
          if ("tags" in track) {
            for (tag in track.tags) {
              if ("random" in tag) {
                emit(tag.random, tag.name);
              }
            }
          }
        }
      }
    }
  }
}
