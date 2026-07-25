const basicGenreList = [
    "African",
    "Blues",
    "Children's",
    "Classical",
    "East Asian",
    "Electronic",
    "Folk & Country",
    "Soul / Funk",
    "Hip-Hop",
    "Indian",
    "Jazz",
    "Latin",
    "Near East",
    "Non-Music",
    "Pop",
    "Reggae",
    "Rock",
    "South Asian",
    "Stage & Screen",
];

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

function applyGradientText(el, releaseId, colors) {
  let gradient = makeGradiantString(releaseId, colors);
  el.style.backgroundImage = gradient
  el.style.color = 'transparent';
  el.style.backgroundClip = 'text';
  el.style.webkitBackgroundClip = 'text';
}

function makeGradiantString(releaseId, colors) {
  let angleStr = (releaseId % 4) * 90 + 'deg';
  return `linear-gradient(${angleStr}, ${colors[0]}, ${colors[1]})`;
}

// Only these are touched by the pulse, so only these get saved and restored.
// Snapshotting the whole style attribute instead would also revert inline
// styles set by something else mid-pulse — notably the display toggles that
// edit mode uses, which left spans and inputs both showing.
var PULSE_PROPS = ['transition', 'backgroundImage', 'backgroundClip', 'webkitBackgroundClip', 'color'];

// Restores pending from the pulse currently running, if any.
var pendingPulseRestores = [];
var pendingPulseTimers = [];

function cancelPendingPulse() {
  pendingPulseTimers.forEach(clearTimeout);
  pendingPulseTimers = [];
  pendingPulseRestores.forEach(function(restore) { restore(); });
  pendingPulseRestores = [];
}

function pulseGradientText(releaseId, colors) {
  let gradient = makeGradiantString(releaseId, colors);
  var half = 650;

  // A second pulse starting mid-flight would otherwise snapshot the first
  // one's transient values (a transparent colour) and restore those at the end.
  cancelPendingPulse();

  // Collect the leaf elements that actually render text, skipping form controls
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
    var savedProps = {};
    PULSE_PROPS.forEach(function(prop) { savedProps[prop] = el.style[prop]; });
    var originalColor = getComputedStyle(el).color;

    function restore() {
      PULSE_PROPS.forEach(function(prop) { el.style[prop] = savedProps[prop]; });
    }
    pendingPulseRestores.push(restore);

    el.style.transition = 'color ' + half + 'ms ease-in-out';
    el.style.backgroundImage = gradient;
    el.style.backgroundClip = 'text';
    el.style.webkitBackgroundClip = 'text';

    // Next frame: fade the text to transparent, revealing the gradient behind.
    requestAnimationFrame(function() {
      el.style.color = 'transparent';
    });

    // Once the gradient is showing, fade back to the original text colour.
    pendingPulseTimers.push(setTimeout(function() {
      el.style.color = originalColor;
    }, half));

    // Back to normal: put back just the properties the pulse changed.
    pendingPulseTimers.push(setTimeout(restore, half * 2));
  });

  // The restores above have all run by now; drop them so a later pulse
  // doesn't re-apply stale values.
  pendingPulseTimers.push(setTimeout(function() {
    pendingPulseRestores = [];
    pendingPulseTimers = [];
  }, half * 2));
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

var COVER_GRID_COLUMNS = 3;

// Mirror the collections page's square tessellation load-order options
// (the shared timeout functions plus the square-specific ones), but pick
// deterministically from the release id so a release always loads the same way.
function pickCoverTimeoutFunction(releaseId) {
  var functions = timeoutFunctions.concat(squareTimeoutFunctions);
  var pairIndex = releaseId % functions.length;
  var directionIndex = Math.floor(releaseId / functions.length) % 2;
  return functions[pairIndex][directionIndex];
}

// Load the cover art as a 3x3 grid of cropped sub-views that reveal one by one,
// then swap in the single full image (mirrors the square tessellation load).
function loadCoverArtProgressive(currentVariant, colors, releaseId) {
  var img = document.getElementById('cover-art');
  if (!currentVariant) { img.src = ''; return; }

  var imagePath = currentVariant.image_path_small || currentVariant.image_path || '';
  if (!imagePath) { img.src = ''; return; }

  var section = document.getElementById('cover-art-section');

  // Build the 3x3 grid where the cover art will sit, and hide the real image.
  var grid = document.createElement('div');
  grid.id = 'cover-art-grid';

  var cells = [];
  var total = COVER_GRID_COLUMNS * COVER_GRID_COLUMNS;
  for (var i = 0; i < total; i++) {
    var cell = document.createElement('div');
    cell.className = 'cover-art-cell';
    grid.appendChild(cell);
    cells.push(cell);
  }

  img.style.display = 'none';
  section.insertBefore(grid, img);

  // Load the image without displaying it, so we can measure it and build the crops.
  var loader = new Image();
  loader.onload = function() {
    revealCoverCrops(loader, imagePath, cells, grid, img, releaseId);
  };
  loader.onerror = function() {
    // Fall back to just showing the image directly.
    grid.remove();
    img.style.display = '';
    img.src = imagePath;
  };
  loader.src = imagePath;
}

function revealCoverCrops(loadedImg, imagePath, cells, grid, img, releaseId) {
  // Size the grid to the square cover-art box, then replicate object-fit: cover.
  var gridSize = grid.clientWidth;
  var cellSize = gridSize / COVER_GRID_COLUMNS;

  var nw = loadedImg.naturalWidth || gridSize;
  var nh = loadedImg.naturalHeight || gridSize;
  var scale = Math.max(gridSize / nw, gridSize / nh);
  var dispW = nw * scale;
  var dispH = nh * scale;
  var originX = (gridSize - dispW) / 2;
  var originY = (gridSize - dispH) / 2;

  var total = cells.length;
  var maxMs = 725;
  var timeoutFn = pickCoverTimeoutFunction(releaseId);
  var promises = [];

  cells.forEach(function(cell, i) {
    var row = Math.floor(i / COVER_GRID_COLUMNS);
    var col = i % COVER_GRID_COLUMNS;
    var delay = timeoutFn(i, total, maxMs);

    var p = new Promise(function(resolve) {
      setTimeout(function() {
        // Each cell shows its slice of the image, positioned as if it were the
        // full cover cropped down to this cell.
        cell.style.backgroundImage = 'url("' + imagePath + '")';
        cell.style.backgroundSize = dispW + 'px ' + dispH + 'px';
        cell.style.backgroundPosition = (originX - col * cellSize) + 'px ' + (originY - row * cellSize) + 'px';
        resolve();
      }, delay);
    });
    promises.push(p);
  });

  Promise.all(promises).then(function() {
    // Once every crop is showing, swap in the single full image.
    setTimeout(function() {
      img.src = imagePath;
      img.style.display = '';
      grid.remove();
    }, 350);
  });
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
  applyGradientText(releaseTitle, release.id, colors);

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
    let newColors = [color1Field.input.value, color2Field.input.value]
    putVariant(release.id, currentVariant.id, {colors: newColors}).then(function() {
      color1Field.valueSpan.textContent = newColors[0];
      color2Field.valueSpan.textContent = newColors[1];
      color1Field.valueSpan.style.color = newColors[0];
      color2Field.valueSpan.style.color = newColors[1];
      applyGradientText(releaseTitle, release.id, newColors);
    }).catch(function(err) {
      console.log(err);
      alert('Color save to variant failed: ' + err.message);
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
      applyGradientText(releaseTitle, release.id, newColors);
      exitReleaseEditMode();
      pulseGradientText(release.id, newColors);
    }).catch(function(err) {
      alert('Release save failed: ' + err.message);
    });
  });

  releaseCancelBtn.addEventListener('click', exitReleaseEditMode);

  // --- Cover art ---
  loadCoverArtProgressive(currentVariant, colors, release.id);

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

  var colorsRow = document.createElement('span');
  colorsRow.className = 'meta-row';

  var colorsLabelSpan = document.createElement('span');
  colorsLabelSpan.textContent = 'colors: ';
  colorsRow.appendChild(colorsLabelSpan);

  var color1ValueSpan = document.createElement('span');
  color1ValueSpan.textContent = colors[0];
  color1ValueSpan.style.color = colors[0];
  var color1Input = makeInput(colors[0], colors[0].length);
  colorsRow.appendChild(color1ValueSpan);
  colorsRow.appendChild(color1Input);

  var colorsCommaSpan = document.createElement('span');
  colorsCommaSpan.textContent = ', ';
  colorsRow.appendChild(colorsCommaSpan);

  var color2ValueSpan = document.createElement('span');
  color2ValueSpan.textContent = colors[1];
  color2ValueSpan.style.color = colors[1];
  var color2Input = makeInput(colors[1], colors[1].length);
  colorsRow.appendChild(color2ValueSpan);
  colorsRow.appendChild(color2Input);

  var color1Field = { row: colorsRow, valueSpan: color1ValueSpan, input: color1Input };
  var color2Field = { row: colorsRow, valueSpan: color2ValueSpan, input: color2Input };
  metadata.appendChild(colorsRow);

  metaFields.push(purchaseDateField, releaseYearField, color1Field, color2Field);
}

var ANNOTATION_TYPES = ['genre', 'vibe', 'freeform'];

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

    var input;
    if (annotationType === 'genre') {
      input = document.createElement('select');
      input.className = 'edit-input';

      var placeholderOption = document.createElement('option');
      placeholderOption.value = '';
      placeholderOption.textContent = '-----> ∞';
      placeholderOption.disabled = true;
      placeholderOption.selected = true;
      input.appendChild(placeholderOption);

      basicGenreList.forEach(function(genre) {
        var option = document.createElement('option');
        option.value = genre;
        option.textContent = genre;
        input.appendChild(option);
      });
    } else {
      input = document.createElement('input');
      input.type = 'text';
      input.className = 'edit-input';
      input.size = 12;
      if (annotationType === 'vibe') {
        input.placeholder = 'vibe / style';
      } else if (annotationType === 'freeform') {
        input.placeholder = 'free as in';
      }
    }

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

    if (annotationType === 'genre') {
      input.addEventListener('change', function() {
        saveAnnotation();
        input.value = '';
      });
    } else {
      input.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') {
          e.preventDefault();
          saveAnnotation();
        }
      });
    }

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
