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
  input.size = size || 15;
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
  var colors = currentVariant ? currentVariant.colors : ['#888', '#ccc'];

  // --- Header ---
  var releaseHeader = document.getElementById('release-header');
  releaseHeader.textContent = release.artist + ' - ' + release.title + ' [' + release.label + ']';
  applyGradientText(releaseHeader, colors);

  var releaseDisplay = document.getElementById('release-display');
  var releaseEditForm = document.getElementById('release-edit-form');
  var releaseEditBtn = document.getElementById('release-edit-btn');
  var releaseSaveBtn = document.getElementById('release-save-btn');
  var releaseCancelBtn = document.getElementById('release-cancel-btn');

  function exitReleaseEditMode() {
    releaseEditForm.style.display = 'none';
    releaseDisplay.style.display = 'inline-block';
  }

  releaseEditBtn.addEventListener('click', function() {
    document.getElementById('edit-artist').value = release.artist;
    document.getElementById('edit-title').value = release.title;
    document.getElementById('edit-label').value = release.label;
    releaseDisplay.style.display = 'none';
    releaseEditForm.style.display = 'block';
  });

  releaseSaveBtn.addEventListener('click', function() {
    var artist = document.getElementById('edit-artist').value;
    var title = document.getElementById('edit-title').value;
    var label = document.getElementById('edit-label').value;
    putRelease(release.id, { artist: artist, title: title, label: label }).then(function(updated) {
      release.artist = updated.artist;
      release.title = updated.title;
      release.label = updated.label;
      releaseHeader.textContent = release.artist + ' – ' + release.title + ' [' + release.label + ']';
      applyGradientText(releaseHeader, colors);
      exitReleaseEditMode();
    }).catch(function(err) {
      alert('Save failed: ' + err.message);
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

  var trackEditToggle = makeSmallEmojiBtn([9999, 65039]);
  var trackSaveBtn = makeSmallBtn('save');
  var trackCancelBtn = makeSmallEmojiBtn([10060]);
  trackSaveBtn.style.display = 'none';
  trackCancelBtn.style.display = 'none';

  var trackHeader = document.createElement('div');
  trackHeader.className = 'section-header';
  var trackTitle = document.createElement('span');
  trackTitle.textContent = 'tracks';
  trackHeader.appendChild(trackTitle);
  trackHeader.appendChild(trackEditToggle);
  trackHeader.appendChild(trackSaveBtn);
  trackHeader.appendChild(trackCancelBtn);
  tracklist.appendChild(trackHeader);

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

  function enterTrackEditMode() {
    trackRows.forEach(function(r) {
      r.input.value = r.titleSpan.textContent;
      r.titleSpan.style.display = 'none';
      r.input.style.display = '';
    });
    trackEditToggle.style.display = 'none';
    trackSaveBtn.style.display = '';
    trackCancelBtn.style.display = '';
  }

  function exitTrackEditMode() {
    trackRows.forEach(function(r) {
      r.titleSpan.style.display = '';
      r.input.style.display = 'none';
    });
    trackEditToggle.style.display = '';
    trackSaveBtn.style.display = 'none';
    trackCancelBtn.style.display = 'none';
  }

  trackEditToggle.addEventListener('click', enterTrackEditMode);
  trackCancelBtn.addEventListener('click', exitTrackEditMode);
  trackSaveBtn.addEventListener('click', function() {
    Promise.all(trackRows.map(function(r) {
      return putTrack(r.track.id, { title: r.input.value }).then(function(updated) {
        r.track.title = updated.title;
        r.titleSpan.textContent = updated.title;
      });
    })).then(exitTrackEditMode).catch(function(err) {
      alert('Save failed: ' + err.message);
    });
  });

  // --- Metadata ---
  var metadata = document.getElementById('metadata');
  var metaFields = [];

  var metaEditToggle = makeSmallEmojiBtn([9999, 65039]);
  var metaSaveBtn = makeSmallBtn('save');
  var metaCancelBtn = makeSmallEmojiBtn([10060]);
  metaSaveBtn.style.display = 'none';
  metaCancelBtn.style.display = 'none';

  var metaHeader = document.createElement('div');
  metaHeader.className = 'section-header';
  var metaTitle = document.createElement('span');
  metaTitle.textContent = 'meta';
  metaHeader.appendChild(metaTitle);
  metaHeader.appendChild(metaEditToggle);
  metaHeader.appendChild(metaSaveBtn);
  metaHeader.appendChild(metaCancelBtn);
  metadata.appendChild(metaHeader);

  function metaRow(label, value) {
    var row = document.createElement('div');
    row.className = 'meta-row';

    var labelSpan = document.createElement('span');
    labelSpan.textContent = label + ': ';

    var valueSpan = document.createElement('span');
    valueSpan.textContent = value;

    var input = makeInput(value, 16);

    row.appendChild(labelSpan);
    row.appendChild(valueSpan);
    row.appendChild(input);
    return { row: row, valueSpan: valueSpan, input: input };
  }

  var purchaseDateField = metaRow('purchase date', release.purchase_date || '');
  metadata.appendChild(purchaseDateField.row);

  var releaseYearField = metaRow('release year', release.release_year || '');
  metadata.appendChild(releaseYearField.row);

  metaFields.push(purchaseDateField, releaseYearField);

  var color1Field, color2Field;
  if (currentVariant && colors.length >= 2) {
    color1Field = metaRow('color 1', colors[0]);
    color2Field = metaRow('color 2', colors[1]);
    metadata.appendChild(color1Field.row);
    metadata.appendChild(color2Field.row);
    metaFields.push(color1Field, color2Field);
  }

  function enterMetaEditMode() {
    metaFields.forEach(function(f) {
      f.input.value = f.valueSpan.textContent;
      f.valueSpan.style.display = 'none';
      f.input.style.display = '';
    });
    metaEditToggle.style.display = 'none';
    metaSaveBtn.style.display = '';
    metaCancelBtn.style.display = '';
  }

  function exitMetaEditMode() {
    metaFields.forEach(function(f) {
      f.valueSpan.style.display = '';
      f.input.style.display = 'none';
    });
    metaEditToggle.style.display = '';
    metaSaveBtn.style.display = 'none';
    metaCancelBtn.style.display = 'none';
  }

  metaEditToggle.addEventListener('click', enterMetaEditMode);
  metaCancelBtn.addEventListener('click', exitMetaEditMode);
  metaSaveBtn.addEventListener('click', function() {
    var saves = [
      putRelease(release.id, {
        purchase_date: purchaseDateField.input.value,
        release_year: releaseYearField.input.value
      }).then(function() {
        purchaseDateField.valueSpan.textContent = purchaseDateField.input.value;
        releaseYearField.valueSpan.textContent = releaseYearField.input.value;
      })
    ];

    if (color1Field && color2Field) {
      saves.push(
        putVariant(release.id, currentVariant.id, {
          colors: [color1Field.input.value, color2Field.input.value]
        }).then(function() {
          colors[0] = color1Field.input.value;
          colors[1] = color2Field.input.value;
          color1Field.valueSpan.textContent = colors[0];
          color2Field.valueSpan.textContent = colors[1];
        })
      );
    }

    Promise.all(saves).then(exitMetaEditMode).catch(function(err) {
      alert('Save failed: ' + err.message);
    });
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
    .then(renderRelease)
    .catch(function(err) {
      console.error(err);
      document.body.innerHTML = '<p class="centre">Failed to load release.</p>';
    });
});
