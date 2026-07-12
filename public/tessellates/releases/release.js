function fetchWithCredentials(url, options) {
  options = options || {};
  return fetch(url, Object.assign({ credentials: 'include', headers: { 'Content-Type': 'application/json' } }, options))
    .then(function(r) {
      if (r.ok) return r.json();
      throw new Error('Request failed: ' + r.status);
    });
}

function putRelease(releaseId, data) {
  return fetchWithCredentials(
    apiState.protocol + '://' + apiState.host + '/releases/' + releaseId,
    { method: 'PUT', body: JSON.stringify(data) }
  );
}

function putTrack(trackId, data) {
  return fetchWithCredentials(
    apiState.protocol + '://' + apiState.host + '/tracks/' + trackId,
    { method: 'PUT', body: JSON.stringify(data) }
  );
}

function postAnnotation(releaseId, annotationType, body) {
  return fetchWithCredentials(
    apiState.protocol + '://' + apiState.host + '/releases/' + releaseId + '/annotations',
    { method: 'POST', body: JSON.stringify({ annotation_type: annotationType, body: body }) }
  );
}

function deleteAnnotation(releaseId, annotationId) {
  return fetchWithCredentials(
    apiState.protocol + '://' + apiState.host + '/releases/' + releaseId + '/annotations/' + annotationId,
    { method: 'DELETE' }
  );
}

function putVariant(releaseId, variantId, data) {
  return fetchWithCredentials(
    apiState.protocol + '://' + apiState.host + '/releases/' + releaseId + '/variants/' + variantId,
    { method: 'PUT', body: JSON.stringify(data) }
  );
}

function applyGradientText(el, colors) {
  el.style.backgroundImage = 'linear-gradient(90deg, ' + colors[0] + ', ' + colors[1] + ')';
  el.style.color = 'transparent';
  el.style.backgroundClip = 'text';
  el.style.webkitBackgroundClip = 'text';
}

function makeSmallBtn(label) {
  var btn = document.createElement('button');
  btn.textContent = label;
  btn.className = 'small-btn';
  return btn;
}

function makeSmallEmojiBtn(emojiDecimalCode) {
  var btn = document.createElement('button');
  btn.textContent = String.fromCodePoint(...emojiDecimalCode);
  btn.className = 'small-btn';
  return btn;
}

function makeInput(value, size) {
  var input = document.createElement('input');
  input.type = 'text';
  input.value = value;
  input.size = size;
  input.className = 'edit-input';
  input.style.display = 'none';
  return input;
}

// Wraps a value span with inline edit/save controls.
// onSave(newValue) should return a promise.
function makeEditableField(valueSpan, input, onSave) {
  var editBtn = makeSmallEmojiBtn([9999, 65039]);
  var saveBtn = makeSmallBtn('save');
  var cancelBtn = makeSmallEmojiBtn([10060]);
  saveBtn.style.display = 'none';
  cancelBtn.style.display = 'none';

  function exitEditMode() {
    valueSpan.style.display = '';
    input.style.display = 'none';
    editBtn.style.display = '';
    saveBtn.style.display = 'none';
    cancelBtn.style.display = 'none';
  }

  editBtn.addEventListener('click', function() {
    input.value = valueSpan.textContent;
    valueSpan.style.display = 'none';
    input.style.display = '';
    editBtn.style.display = 'none';
    saveBtn.style.display = '';
    cancelBtn.style.display = '';
  });

  saveBtn.addEventListener('click', function() {
    onSave(input.value).then(function() {
      valueSpan.textContent = input.value;
      exitEditMode();
    }).catch(function(err) {
      alert('Save failed: ' + err.message);
    });
  });

  cancelBtn.addEventListener('click', exitEditMode);

  return { editBtn: editBtn, saveBtn: saveBtn, cancelBtn: cancelBtn };
}

function renderRelease(release) {
  var currentVariant = release.variants.find(function(v) { return v.id === release.current_variant_id; });
  var colors = currentVariant.colors;

  // --- Header ---
  let releaseString = release.artist + ' - ' + release.title + ' [' + release.label + ']';
  let releaseTitle = document.getElementById('release-title');
  let releaseHeader = document.getElementById('release-header');
  releaseTitle.textContent = releaseString;
  releaseHeader.textContent = releaseString;
  applyGradientText(releaseTitle, colors);

  var releaseDisplay = document.getElementById('release-display');
  var releaseEditForm = document.getElementById('release-edit-form');
  var releaseEditBtn = document.getElementById('release-edit-btn');
  var releaseSaveBtn = document.getElementById('release-save-btn');
  var releaseCancelBtn = document.getElementById('release-cancel-btn');

  function exitReleaseEditMode() {
    releaseEditForm.style.display = 'none';
    releaseDisplay.style.display = 'inline-block';
    trackRows.forEach(function(r) {
      r.titleSpan.style.display = '';
      r.input.style.display = 'none';
    });
    metaFields.forEach(function(f) {
      f.valueSpan.style.display = '';
      f.input.style.display = 'none';
    });
  }

  releaseEditBtn.addEventListener('click', function() {
    releaseDisplay.style.display = 'none';
    releaseEditForm.style.display = 'block';
    document.getElementById('edit-artist').value = release.artist;
    document.getElementById('edit-artist').size = release.artist.length;
    document.getElementById('edit-title').value = release.title;
    document.getElementById('edit-title').size = release.title.length;
    document.getElementById('edit-label').value = release.label;
    document.getElementById('edit-label').size = release.label.length;
    trackRows.forEach(function(r) {
      r.input.value = r.titleSpan.textContent;
      r.titleSpan.style.display = 'none';
      r.input.style.display = '';
    });
    metaFields.forEach(function(f) {
      f.input.value = f.valueSpan.textContent;
      f.valueSpan.style.display = 'none';
      f.input.style.display = '';
    });
  });

  releaseSaveBtn.addEventListener('click', function() {
    let artist = document.getElementById('edit-artist').value;
    let title = document.getElementById('edit-title').value;
    let label = document.getElementById('edit-label').value;
    let purchaseDate = purchaseDateField.input.value;
    let releaseYear = releaseYearField.input.value;

    // Colors save to varient
    putVariant(release.id, currentVariant.id, {
      colors: [color1Field.input.value, color2Field.input.value]
    }).then(function() {
      colors[0] = color1Field.input.value;
      colors[1] = color2Field.input.value;
      color1Field.valueSpan.textContent = colors[0];
      color2Field.valueSpan.textContent = colors[1];
    }).catch(function(err) {
      console.log(err);
      // alert('Color save to variant failed: ' + err.message);
    });

    // Tracks need multiple PUTs
    Promise.all(trackRows.map(function(r) {
      return putTrack(r.track.id, { title: r.input.value }).then(function(updated) {
        r.track.title = updated.title;
        r.titleSpan.textContent = updated.title;
      });
    })).catch(function(err) {
      alert('Tracks save failed: ' + err.message);
    });
    
    putRelease(release.id, { artist: artist, title: title, label: label, release_year: releaseYear, purchase_date: purchaseDate}).then(function(updated) {
      release.artist = updated.artist;
      release.title = updated.title;
      release.label = updated.label;
      release.purchase_date = updated.purchase_date;
      release.release_year = updated.release_year;

      purchaseDateField.valueSpan.textContent = release.purchase_date
      releaseYearField.valueSpan.textContent = release.release_year;
      releaseHeader.textContent = release.artist + ' – ' + release.title + ' [' + release.label + ']';
      applyGradientText(releaseHeader, colors);
      exitReleaseEditMode();
    }).catch(function(err) {
      alert('Release save failed: ' + err.message);
    });
  });

  releaseCancelBtn.addEventListener('click', exitReleaseEditMode);

  // --- Cover art ---
  var img = document.getElementById('cover-art');
  img.src = currentVariant ? (currentVariant.image_path_small || currentVariant.image_path || '') : '';

  // --- Tracklist ---
  var tracklist = document.getElementById('tracklist');
  var tracks = release.tracks.slice().sort(function(a, b) {
    return (parseInt(a.position) || 0) - (parseInt(b.position) || 0);
  });

  var trackRows = [];
  tracks.forEach(function(track) {
    var row = document.createElement('div');
    row.className = 'track-row';

    var pos = document.createElement('span');
    pos.className = 'track-position';
    pos.textContent = track.position + '.';

    var titleSpan = document.createElement('span');
    titleSpan.textContent = track.title;

    var input = makeInput(track.title, 32);

    row.appendChild(pos);
    row.appendChild(titleSpan);
    row.appendChild(input);
    tracklist.appendChild(row);

    trackRows.push({ track: track, titleSpan: titleSpan, input: input });
  });

  // --- Metadata ---
  var metadata = document.getElementById('metadata');
  var metaFields = [];

  function metaRow(label, value) {
    var row = document.createElement('span');
    row.className = 'meta-row';

    var labelSpan = document.createElement('span');
    labelSpan.textContent = label + ': ';

    var valueSpan = document.createElement('span');
    valueSpan.textContent = value;

    var input = makeInput(value, valueSpan.textContent.length);

    row.appendChild(labelSpan);
    row.appendChild(valueSpan);
    row.appendChild(input);
    return { row: row, valueSpan: valueSpan, input: input };
  }

  var purchaseDateField = metaRow('purchase date', release.purchase_date);
  metadata.appendChild(purchaseDateField.row);
  var releaseYearField = metaRow('release year', release.release_year);
  metadata.appendChild(releaseYearField.row);

  var color1Field = metaRow('color 1', colors[0]);
  var color2Field = metaRow('color 2', colors[1]);
  metadata.appendChild(color1Field.row);
  metadata.appendChild(color2Field.row);

  metaFields.push(purchaseDateField, releaseYearField, color1Field, color2Field);
}

var ANNOTATION_TYPES = ['genre', 'vibe', 'epoch', 'freeform'];

function renderAnnotations(release) {
  var container = document.getElementById('annotations');
  ANNOTATION_TYPES.forEach(function(annotationType) {
    var typeAnnotations = release.annotations.filter(function(a) {
      return a.annotation_type === annotationType;
    });

    var row = document.createElement('div');
    row.className = 'meta-row';

    var label = document.createElement('span');
    label.textContent = annotationType + ': ';
    row.appendChild(label);

    var tagList = document.createElement('span');
    tagList.className = 'annotation-tag-list';

    function addTagToList(annotation) {
      var btn = document.createElement('button');
      btn.textContent = annotation.body;
      btn.className = 'small-btn';
      btn.addEventListener('click', function() {
        deleteAnnotation(release.id, annotation.id).then(function() {
          tagList.removeChild(btn);
        }).catch(function(err) {
          alert('Delete failed: ' + err.message);
        });
      });
      tagList.appendChild(btn);
    }

    typeAnnotations.forEach(addTagToList);
    row.appendChild(tagList);

    var input = document.createElement('input');
    input.type = 'text';
    input.className = 'edit-input';
    input.style.display = 'inline';
    input.size = 18;

    var saveBtn = makeSmallBtn('save');
    saveBtn.addEventListener('click', function() {
      var val = input.value.trim();
      if (!val) return;
      postAnnotation(release.id, annotationType, val).then(function(created) {
        created.forEach(function(annotation) {
          release.annotations.push(annotation);
          addTagToList(annotation);
        });
        input.value = '';
      }).catch(function(err) {
        alert('Save failed: ' + err.message);
      });
    });

    row.appendChild(input);
    row.appendChild(saveBtn);
    container.appendChild(row);
  });
}

window.addEventListener('DOMContentLoaded', function() {
  var params = new URLSearchParams(window.location.search);
  var releaseId = params.get('r');
  if (!releaseId) {
    document.body.innerHTML = '<p class="centre">No release specified.</p>';
    return;
  }

  var url = apiState.protocol + '://' + apiState.host + '/releases/' + releaseId;
  fetchWithCredentials(url)
    .then(function(release) {
      renderRelease(release);
      renderAnnotations(release);
    })
    .catch(function(err) {
      console.error(err);
      document.body.innerHTML = '<p class="centre">Failed to load release.</p>';
    });
});
