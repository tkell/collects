/**
 * Main application file
 */

/**
 * Render the tessellation with the given data
 * @param {Object} tess - Tessellation configuration object
 * @param {Array} data - Array of record objects
 * @param {Object} params - Parameters for rendering
 */
function renderTessellation(tess, data, params) {
  const start = params['offset'] - params['min_offset'];
  const end = start + tess.defaultItems;
  const previousData = tess.prepare(data.slice(start - params['offset_delta'], end - params['offset_delta']));
  const currentData = tess.prepare(data.slice(start, end));
  tess.render(currentData, previousData, params['offset_delta']);
}

/**
 * Add click handlers for pagination
 * @param {string} elementId - Element ID for the pagination button
 * @param {number} offsetDelta - Amount to change offset
 */
function addPagingClick(elementId, offsetDelta) {
  document.getElementById(elementId).addEventListener("click", function(e) {
    if (!uiState.bigImage.isShowing && params['offset'] + offsetDelta >= 0) {
      // Update paging parameters
      params['offset'] = Math.max(0, params['offset'] + offsetDelta);
      params['offset_delta'] = offsetDelta;
      const potentialNewMax = params['offset'] + (tess.defaultItems * 2);
      const potentialNewMin = Math.max(0, params['offset'] - (tess.defaultItems * 2));
      
      // Render the grid with updated data
      renderTessellation(tess, releaseData, params);

      // Load more data if needed
      if (offsetDelta > 0 && potentialNewMax > params['max_offset']) {
        const limit = potentialNewMax - params['max_offset'];
        const queryUrl = buildUrl(apiState, params['max_offset'], limit, params);
        fetch(queryUrl)
          .then(response => response.json())
          .then(newReleaseData => {
            params['max_offset'] = potentialNewMax;
            releaseData = releaseData.concat(newReleaseData);
          });
      } else if (offsetDelta < 0 & potentialNewMin < params['min_offset']) {
        const limit = params['min_offset'] - potentialNewMin;
        const queryUrl = buildUrl(apiState, potentialNewMin, limit, params);
        fetch(queryUrl)
          .then(response => response.json())
          .then(newReleaseData => {
            params['min_offset'] = potentialNewMin;
            releaseData = newReleaseData.concat(releaseData);
          });
      }
    }
  });
}

/**
 * Add click handlers for folder selection
 * @param {string} elementId - Element ID for the folder button
 * @param {string} folder - Folder name or false for all
 */
function addFolderClick(elementId, folder) {
  const element = document.getElementById(elementId);
  element.addEventListener("click", function(e) {
    if (element === uiState.currentFolderElement || uiState.bigImage.isShowing) {
      return;
    }

    let t = document.getElementById('text');
    t.textContent = "tessellates";
    params['folder'] = folder;
    params['offset'] = 0;
    params['min_offset'] = 0;
    params['max_offset'] = (tess.defaultItems * 2);
    delete params.offsetDelta;
    uiState.needsRefresh = true;

    if (folder !== false) {
      if (uiState.currentFolderElement) {
        uiState.currentFolderElement.classList.remove("emoji-button-selected");
        uiState.currentFolderElement.classList.add("emoji-button");
        uiState.currentFolderElement.disabled = false;
      }
      element.classList.remove("emoji-button");
      element.classList.add("emoji-button-selected");
      element.disabled = true;
      uiState.currentFolderElement = element;
    } else {
      uiState.currentFolderElement.classList.remove("emoji-button-selected");
      uiState.currentFolderElement.classList.add("emoji-button");
      uiState.currentFolderElement.disabled = false;
      uiState.currentFolderElement = null;
      params = setRandomView(params);
    }

    const queryUrl = buildUrl(apiState,
      params['min_offset'],
      params['max_offset'] - params['min_offset'],
      params
    );
    fetch(queryUrl)
      .then(response => response.json())
      .then(newReleaseData => {
        releaseData = newReleaseData;
        uiHelper.clearText();
        renderTessellation(tess, releaseData, params);
        params['randomize'] = undefined;
        updateBrowserUrl(params);
      });
  });
}

/**
 * Update the browser URL without reloading the page
 * @param {Object} params - Current parameters
 */
function updateBrowserUrl(params) {
  const urlParams = new URLSearchParams();

  // Add collection name
  if (apiState.collectionName) {
    urlParams.set('c', apiState.collectionName);
  }

  // Add tessellation type
  if (params['t']) {
    urlParams.set('t', params['t']);
  }

  // Add filter params if set
  if (params['filter']) {
    urlParams.set('filter', params['filter']);
  }
  if (params['release_year']) {
    urlParams.set('release_year', params['release_year']);
  }
  if (params['purchase_date']) {
    urlParams.set('purchase_date', params['purchase_date']);
  }
  if (params['sort']) {
    urlParams.set('sort', params['sort']);
  }
  if (params['folder']) {
    urlParams.set('folder', params['folder']);
  }

  const newUrl = `${window.location.pathname}?${urlParams.toString()}`;
  history.pushState(null, '', newUrl);
}

/**
 * Build a URL for the API request
 * @param {Object} apiState - API state object
 * @param {number} offset - Offset for API request
 * @param {number} limit - Limit for API request
 * @param {Object} params - Parameters for the request
 * @returns {string} - Constructed URL
 */
function buildUrl(apiState, offset, limit, params) {
  const backendParams = {
    'offset': offset,
    'limit': limit,
  };
  const backendKeys = ['filter', 'folder', 'release_year', 'purchase_date', 'sort', 'randomize']
  for (let i = 0; i < backendKeys.length; i++) {
    const key = backendKeys[i];
    backendParams[key] = params[key];
  }
  const paramsString = transformToString(backendParams);
  let url = `${apiState.protocol}://${apiState.host}/collections/${apiState.collectionName}${paramsString}`;

  return url;
}

/**
 * Set random view parameters
 * @param {Object} params - Current parameters
 * @returns {Object} - Updated parameters
 */
function setRandomView(params) {
  const randomKey = Math.floor(Math.random() * 100_000)
  params['filter'] = undefined;
  params['release_year'] = undefined;
  params['randomize'] = randomKey;
  params['min_offset'] = 0
  params['max_offset'] = tess.defaultItems * 3;
  delete params.offsetDelta;
  return params;
}

/**
 * Add collection flip handler
 * @param {string} elementId - Element ID for the button
 */
function addCollectionFlip(elementId) {
  document.getElementById(elementId).addEventListener("click", function(e) {
    if (uiState.bigImage.isShowing) {
      return;
    }

    let nextName = "vinyl";
    if (apiState.collectionName === "vinyl") {
      nextName = "digital";
    }
    const url = `https://tide-pool.ca/tessellates/collections?c=${nextName}&t=${params['t']}`;
    window.location.href = url;
  });
}

/**
 * Add random view interaction
 * @param {string} elementId - Element ID for the button
 */
function addRandomInteraction(elementId) {
  document.getElementById(elementId).addEventListener("click", function(e) {
    if (uiState.bigImage.isShowing) {
      return;
    }
    params = setRandomView(params);
    document.getElementById("release-year-input").value = "";
    document.getElementById("purchase-date-input").value = "";
    document.getElementById("filter-input").value = "";
    document.getElementById("sort-input").value = "";
    uiState.needsRefresh = true;

    const queryUrl = buildUrl(apiState,
      params['min_offset'],
      params['max_offset'] - params['min_offset'],
      params
    );
    fetch(queryUrl)
      .then(response => response.json())
      .then(newReleaseData => {
        releaseData = newReleaseData;
        uiHelper.clearText();
        renderTessellation(tess, releaseData, params);
        params['randomize'] = undefined;
        updateBrowserUrl(params);
      });
  });
}

/**
 * Update parameters on keypress
 * @param {string} elementId - Element ID for the input
 * @param {string} paramsField - Field in params to update
 */
function updateParamsOnKeypress(elementId, paramsField) {
  document.getElementById(elementId).addEventListener("keyup", function(e) {
    if (e.target.value === "") {
      delete params[paramsField];
    } else
    if (paramsField === "release_year" || paramsField === "purchase_date") {
      const re = /^\d{4}(?:\s*-\s*\d{4})?$/;
      if (re.test(e.target.value)) {
        params[paramsField] = e.target.value;
      }
    } else if (paramsField === "sort") {
      const re = /^[atylp]{0,4}$/;
      if (re.test(e.target.value)) {
        params[paramsField] = e.target.value;
      }
    }
    else {
      params[paramsField] = e.target.value;
    }
  });
}

/**
 * Check if any filter parameters are set
 * @param {Object} params - Parameters object
 * @returns {boolean} - True if any filter parameter is set
 */
function filterParamsAreSet(params) {
  const hasFilter = params['filter'] && params['filter'].length > 0;
  const hasReleaseYear = params['release_year'] && params['release_year'].length > 0;
  const hasPurchaseDate = params['purchase_date'] && params['purchase_date'].length > 0;
  const hasSort = params['sort'] && params['sort'].length > 0;

  return (hasFilter || hasReleaseYear || hasPurchaseDate || hasSort);
}

/**
 * Add filter interaction
 * @param {string} elementId - Element ID for the button or input
 * @param {string} eventType - Event type (click or keypress)
 */
function addFilterInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, function(e) {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }
    if (!uiState.bigImage.isShowing) {
      if (filterParamsAreSet(params)) {
        params['offset'] = 0;
        params['min_offset'] = 0;
        params['max_offset'] = (tess.defaultItems * 2);
        delete params.offsetDelta;
      } else {
        params = setRandomView(params);
      }

      uiState.needsRefresh = true;
      const queryUrl = buildUrl(apiState,
        params['min_offset'],
        params['max_offset'] - params['min_offset'],
        params
      );
      fetch(queryUrl)
        .then(response => response.json())
        .then(newReleaseData => {
          releaseData = newReleaseData;
          uiHelper.clearText();
          renderTessellation(tess, releaseData, params);
          params['randomize'] = undefined;
          updateBrowserUrl(params);
        });
    }
  });
}

/**
 * Add local playback enable button
 */
function addLocalPlaybackClick() {
  const enableButton = document.getElementById("enable-local-playback");
  if (enableButton) {
    enableButton.addEventListener("click", function(e) {
      console.log("local playback enabled");
      uiState.localPlayback = true;
      
      const pauseButton = document.getElementById("pause-local-playback");
      if (pauseButton) pauseButton.disabled = false;
      
      const clearButton = document.getElementById("clear-local-playback");
      if (clearButton) clearButton.disabled = false;
    });
  }
}

/**
 * Add local playback pause button
 */
function addLocalPauseClick() {
  const pauseButton = document.getElementById("pause-local-playback");
  if (pauseButton) {
    pauseButton.addEventListener("click", function(e) {
      vlcHelper.pause();
    });
  }
}

/**
 * Add local playback clear button
 */
function addLocalClearClick() {
  const clearButton = document.getElementById("clear-local-playback");
  if (clearButton) {
    clearButton.addEventListener("click", function(e) {
      vlcHelper.clearAllTracks();
    });
  }
}

/**
 * Display login-related UI elements if logged in
 */
function displayLogin() {
  if (checkCookieExistence('loggedInUser')) {
    document.getElementById('annotation-span').style.visibility = 'visible';
    const playbackDiv = document.getElementById('playback-div');
    if (playbackDiv) {
      playbackDiv.style.visibility = 'visible';
    }
  }
}

/**
 * Check if a cookie exists
 * @param {string} cookie_name - Name of the cookie to check
 * @returns {boolean} - True if cookie exists
 */
function checkCookieExistence(cookie_name) {
  let decodedCookie = decodeURIComponent(document.cookie);
  let cookies = decodedCookie.split(';');
  for (let i = 0; i < cookies.length; i++) {
    const name = cookies[i].split('=')[0].trim();
    if (name === cookie_name) {
      return true;
    }
  }
  return false;
}

// ---- Entrypoint is here:
var releaseData = [];
var uiState = {
  hasPreloaded: false,
  needRefresh: false,
  preloadedObjects: [],
  closeUpImages: [],
  bigImage: {
    image: null,
    isShowing: false,
    isAnimating: false
  },
  localPlayback: false,
  currentFolderElement: null
};
let params = getSearchParameters();

// Pick the collection from the URL parameter ?c=<collection-name>
apiState.collectionName = params['c'] || null;

// Set collection-specific properties
if (apiState.collectionName === "digital") {
  apiState.filePathPrefix = "/Volumes/Mimir/Music/Albums/"
} else if (apiState.collectionName === "vinyl") {
  apiState.filePathPrefix = undefined;
} else if (apiState.collectionName === "productions") {
  apiState.filePathPrefix = "/Volumes/Mimir/Productions/"
}

// Pick a tessellation
let tess = null;
if (params['t'] == 'square') {
  tess = makeSquare();
} else if (params['t']== 'rhombus') {
  tess = makeRhombus();
} else if (params['t']== 'triangle') {
  tess = makeTriangle();
} else if (params['t']== 'circle') {
  tess = makeCircle();
} else {
  let random = Math.floor(Math.random() * 4);
  if (random == 0) {
    tess = makeSquare();
    params['t'] = 'square';
  } else if (random == 1) {
    tess = makeRhombus();
    params['t'] = 'rhombus';
  } else if (random == 2) {
    tess = makeTriangle();
    params['t'] = 'triangle';
  } else {
    tess = makeCircle();
    params['t'] = 'circle';
  }
}
params = parseTessellatesParams(params, tess);

// Initialize on window load
window.addEventListener("load", (event) => {
  gridElement = document.getElementById("image-grid")
  gridElement.classList.add(`image-grid-${params['t']}`);

  // Draw preload hexagons
  uiHelper.drawPreloadHexagons(tess);

  // Show folders section only for vinyl collection
  const foldersDiv = document.getElementById('folders-div');
  if (foldersDiv) {
    if (apiState.collectionName === 'vinyl') {
      foldersDiv.style.display = '';
    } else {
      foldersDiv.style.display = 'none';
    }
  }

  // Pre-populate input fields from URL params
  if (params['release_year']) {
    document.getElementById('release-year-input').value = params['release_year'];
  }
  if (params['purchase_date']) {
    document.getElementById('purchase-date-input').value = params['purchase_date'];
  }
  if (params['filter']) {
    document.getElementById('filter-input').value = params['filter'];
  }
  if (params['sort']) {
    document.getElementById('sort-input').value = params['sort'];
  }

  displayLogin();
});

// Load a random view of the collection, unless filter params are set
if (!filterParamsAreSet(params)) {
  params = setRandomView(params);
} else {
  // Set offset params for filtered view
  params['offset'] = params['offset'] || 0;
  params['min_offset'] = params['min_offset'] || 0;
  params['max_offset'] = params['max_offset'] || (tess.defaultItems * 2);
}

const queryUrl = buildUrl(apiState,
  params['min_offset'],
  params['max_offset'] - params['min_offset'],
  params
);

fetch(queryUrl)
  .then(response => response.json())
  .then(data => {
    releaseData = data;
    renderTessellation(tess, releaseData, params);
    params['randomize'] = undefined;
    updateBrowserUrl(params);

    addPagingClick("back-small", tess.paging.small * -1);
    addPagingClick("back-medium", tess.paging.medium * -1);
    addPagingClick("back-big", tess.paging.big * -1);
    addPagingClick("forward-small", tess.paging.small);
    addPagingClick("forward-medium", tess.paging.medium);
    addPagingClick("forward-big", tess.paging.big);

    updateParamsOnKeypress('release-year-input', 'release_year');
    updateParamsOnKeypress('purchase-date-input', 'purchase_date');
    updateParamsOnKeypress('filter-input', 'filter');
    updateParamsOnKeypress('sort-input', 'sort');

    addFilterInteraction("release-year-input", "keypress");
    addFilterInteraction("purchase-date-input", "keypress");
    addFilterInteraction("filter-input", "keypress");
    addFilterInteraction("sort-input", "keypress");
    addFilterInteraction("filter-submit", "click");
    addFilterInteraction("filter-submit", "keypress");
    addRandomInteraction("random");
    addCollectionFlip("collection-flip");

    // If we have folders, add some folder filters!
    let testItem = releaseData[0];
    if (testItem.folder) {
      addFolderClick("balearic", '\"Balearic\"');
      addFolderClick("world", '\"World Music\" / Exotica');
      addFolderClick("seven-inches", '7\"');
      addFolderClick("battletech", 'Battletech');
      addFolderClick("breaks", 'Breaks');
      addFolderClick("classical", 'Classical');
      addFolderClick("disco", 'Disco');
      addFolderClick("ambient-albums", 'Electronic Albums / Ambient');
      addFolderClick("house-tech-dance", 'House/Tech/Dance');
      addFolderClick("progressive", 'Progressive');
      addFolderClick("swing-rock-albums", 'Swing / Rock / Soul Albums');
      addFolderClick("techno", 'Techno');
      addFolderClick("trance", 'Trance');
      addFolderClick("wall-records", 'Wall Records');
      addFolderClick("all", false);
    } else {
      addLocalPlaybackClick();
      addLocalPauseClick();
      addLocalClearClick();
    }
  });
