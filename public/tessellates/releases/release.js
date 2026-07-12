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

// Briefly sweep every piece of text on the page from its default colour into
// the release gradient and back again — used as a "saved!" flourish.
function pulseGradientText(colors) {
  var gradient = 'linear-gradient(90deg, ' + colors[0] + ', ' + colors[1] + ')';
  var half = 650; // ms spent fading each direction

  // Collect the leaf elements that actually render text, skipping form
  // controls (their backgrounds/emoji don't play well with background-clip).
  var elements = [];
  var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null);
  var node;
  while ((node = walker.nextNode())) {
    var parent = node.parentElement;
    if (!parent || !node.textContent.trim()) continue;
    var tag = parent.tagName;
    if (tag === 'BUTTON' || tag === 'INPUT' || tag === 'SCRIPT' || tag === 'STYLE') continue;
    if (elements.indexOf(parent) === -1) elements.push(parent);
  }

  elements.forEach(function(el) {
    var savedStyle = el.getAttribute('style');
    var originalColor = getComputedStyle(el).color;

    el.style.transition = 'color ' + half + 'ms ease-in-out';
    el.style.backgroundImage = gradient;
    el.style.backgroundClip = 'text';
    el.style.webkitBackgroundClip = 'text';

    // Next frame: fade the text to transparent, revealing the gradient behind.
    requestAnimationFrame(function() {
      el.style.color = 'transparent';
    });

    // Once the gradient is showing, fade back to the original text colour.
    setTimeout(function() {
      el.style.color = originalColor;
    }, half);

    // Back to normal: restore whatever inline styles the element started with.
    setTimeout(function() {
      if (savedStyle === null) el.removeAttribute('style');
      else el.setAttribute('style', savedStyle);
    }, half * 2);
  });
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
      color1Field.valueSpan.style.color = colors[0];
      color2Field.valueSpan.style.color = colors[1];
      applyGradientText(releaseTitle, colors);
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
      applyGradientText(releaseTitle, colors);
      exitReleaseEditMode();
      pulseGradientText([color1Field.input.value, color2Field.input.value]);
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

    var input = makeInput(track.title, track.title.length + 2);

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
  color1Field.valueSpan.style.color = colors[0];
  color2Field.valueSpan.style.color = colors[1];
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

    var column = document.createElement('div');
    column.className = 'annotation-column';

    var label = document.createElement('div');
    label.className = 'annotation-title';
    label.textContent = annotationType;
    column.appendChild(label);

    var inputRow = document.createElement('div');
    inputRow.className = 'annotation-input-row';

    var input = document.createElement('input');
    input.type = 'text';
    input.className = 'edit-input';
    input.size = 12;

    var tagList = document.createElement('div');
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

    function saveAnnotation() {
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
    }

    input.addEventListener('keydown', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        saveAnnotation();
      }
    });

    inputRow.appendChild(input);
    column.appendChild(inputRow);

    typeAnnotations.forEach(addTagToList);
    column.appendChild(tagList);

    container.appendChild(column);
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
