/**
 * Login page functionality
 */

// Store fetched collections for validation
let userCollections = [];

/**
 * Generate a random hex color
 * @returns {string} - Random hex color
 */
function getRandomColor() {
  const letters = '0123456789ABCDEF';
  let color = '#';
  for (let i = 0; i < 6; i++) {
    color += letters[Math.floor(Math.random() * 16)];
  }
  return color;
}

/**
 * Draw decorative hexagons on the login page
 */
function drawLoginHexagons() {
  const container = document.getElementById('hexagons-container');

  for (let i = 0; i < 6; i++) {
    const hexWrapper = document.createElement('div');
    hexWrapper.className = 'login-hex-wrapper';

    const hex = document.createElement('div');
    hex.className = 'hex-loader';

    // Generate random colors for this hexagon
    const color1 = getRandomColor();
    const color2 = getRandomColor();
    hex.style.setProperty('--color1', color1);
    hex.style.setProperty('--color2', color2);

    hexWrapper.appendChild(hex);
    container.appendChild(hexWrapper);
  }
}

/**
 * Update login hexagon gradients to match release colors
 * @param {string[]} colors - Array of hex color strings [color1, color2]
 */
function updateHexagonColors(colors) {
  const hexLoaders = document.querySelectorAll('#hexagons-container .hex-loader');
  const hexLoader = hexLoaders[Math.floor(Math.random() * hexLoaders.length)];
  hexLoader.style.setProperty('--color1', colors[0]);
  hexLoader.style.setProperty('--color2', colors[1]);
}

/**
 * Animate hexagons bouncing in different directions
 */
function bounceHexagons() {
  const hexWrappers = document.querySelectorAll('.login-hex-wrapper');
  const bounceDirections = ['bounce-up', 'bounce-down', 'bounce-left', 'bounce-right'];

  hexWrappers.forEach((hexWrapper, i) => {
    const timeout = Math.floor(Math.random() * 500) + 100;
    const direction = bounceDirections[i % bounceDirections.length];
    setTimeout(() => {
      hexWrapper.classList.add(direction);
    }, timeout);
  });
}

/**
 * Request a password reset email
 * @param {string} elementId - Element ID for the button or input
 * @param {string} eventType - Event type (click or keypress)
 */
function addResetPasswordRequestInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") return;

    const email = document.getElementById('forgot-password-email').value;
    if (!email) {
      alert('Please enter your email address');
      return;
    }

    bounceHexagons();

    try {
      const url = `${apiState.protocol}://${apiState.host}/password_resets`;
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
        credentials: 'include'
      });

      const data = await response.json();
      alert(data.message || 'If that email exists, a reset link has been sent.');
    } catch (error) {
      alert('Error requesting password reset: ' + error.message);
    }
  });
}

/**
 * Submit a new password using the reset token from the URL
 * @param {string} elementId - Element ID for the button or input
 * @param {string} eventType - Event type (click or keypress)
 */
function addResetPasswordSubmitInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") return;

    const password = document.getElementById('reset-new-password').value;
    const password_confirmation = document.getElementById('reset-new-password-confirm').value;

    if (!password || !password_confirmation) {
      alert('Please fill in both password fields');
      return;
    }

    if (password !== password_confirmation) {
      alert('Passwords do not match');
      return;
    }

    const token = new URLSearchParams(window.location.search).get('reset_token');

    bounceHexagons();

    try {
      const url = `${apiState.protocol}://${apiState.host}/password_resets/${token}`;
      const response = await fetch(url, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password, password_confirmation }),
        credentials: 'include'
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || (data.errors && data.errors.join(', ')) || 'Reset failed');
      }

      alert('Password updated! You can now log in.');
      window.history.replaceState({}, document.title, window.location.pathname);
      document.getElementById('reset-password-container').style.display = 'none';
      document.getElementById('login-fields').style.display = '';
    } catch (error) {
      alert('Error resetting password: ' + error.message);
    }
  });
}

/**
 * Add login interaction
 * @param {string} elementId - Element ID for the button or input
 * @param {string} eventType - Event type (click or keypress)
 */
function addLoginInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }
    const email = document.getElementById('login-input').value;
    const password = document.getElementById('password-input').value;

    bounceHexagons();

    try {
      const url= `${apiState.protocol}://${apiState.host}/login`;
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
        credentials: 'include' // need this for cookies
      });

      if (!response.ok) {
        throw new Error('Login failed');
      }

      const data = await response.json();
      const expires_at = new Date(data.expires_at);
      const username = data.username;
      const user_id = data.user_id;
      // Set our own baby cookies for UI stuff
      document.cookie = `loggedInUser=${username}; expires=${expires_at.toUTCString()}; path=/`;
      document.cookie = `loggedInUserId=${user_id}; expires=${expires_at.toUTCString()}; path=/`;
      displayLoggedIn();
      fetchAndDisplayCollections();
    } catch (error) {
      alert('Login error: ' + error);
    }
  });
}

function addSettingsToggleInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }

    if (displaySettings === false) {
      document.getElementById("settings-container").classList.remove("is-hidden");
      document.getElementById("settings-container").classList.add("is-visible");
      document.getElementById("settings-toggle").innerHTML = "&#x25B2;";
      displaySettings = true;
    } else {
      document.getElementById("settings-container").classList.add("is-hidden");
      document.getElementById("settings-container").classList.remove("is-visible");
      document.getElementById("settings-toggle").innerHTML = "&#x2314;";
      displaySettings = false;
    }
  });
}


/**
 * Add create user interaction
 * @param {string} elementId - Element ID for the button or input
 * @param {string} eventType - Event type (click or keypress)
 */
function addCreateUserInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }
    const username = document.getElementById('create-username').value;
    const email = document.getElementById('create-email').value;
    const password = document.getElementById('create-password').value;
    const password_confirmation = document.getElementById('create-password-confirm').value;

    if (!username || !email || !password || !password_confirmation) {
      alert('Please fill in all fields');
      return;
    }

    if (password !== password_confirmation) {
      alert('Passwords do not match');
      return;
    }

    bounceHexagons();

    try {
      const url = `${apiState.protocol}://${apiState.host}/users`;
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user: { username, email, password, password_confirmation } }),
        credentials: 'include'
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.errors ? data.errors.join(', ') : 'User creation failed');
      }

      alert('Account created! You can now log in.');
      document.getElementById('create-username').value = '';
      document.getElementById('create-email').value = '';
      document.getElementById('create-password').value = '';
      document.getElementById('create-password-confirm').value = '';
      document.getElementById('login-input').value = email;
    } catch (error) {
      alert('Error creating account: ' + error.message);
    }
  });
}

/**
 * Add new collection interaction
 * @param {string} elementId - Element ID for the button or input
 * @param {string} eventType - Event type (click or keypress)
 */
function addNewCollectionInteraction(elementId, eventType) {
  let fileStepActive = false;

  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }

    const name = document.getElementById('new-collection-name').value;
    const releaseSource = document.getElementById('new-collection-source').value;
    const fileInput = document.getElementById('new-collection-file');

    if (!name) {
      alert('Please enter a collection name');
      return;
    }

    if (releaseSource === 'json_file' && !fileStepActive) {
      fileInput.style.display = '';
      fileStepActive = true;
      return;
    }

    bounceHexagons();

    try {
      const url = `${apiState.protocol}://${apiState.host}/collections`;
      const body = { name, release_source: releaseSource };

      if (releaseSource === 'json_file') {
        const file = fileInput.files[0];
        if (!file) {
          alert('Please select a JSON file');
          return;
        }
        const text = await file.text();
        body.releases = JSON.parse(text);
      }

      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        credentials: 'include'
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Collection creation failed');
      }

      fileInput.style.display = 'none';
      fileInput.value = '';
      fileStepActive = false;
      document.getElementById('new-collection-name').value = '';

      fetchAndDisplayCollections();
    } catch (error) {
      alert('Error creating collection: ' + error.message);
    }
  });
}

/**
 * Add update user interaction
 * @param {string} elementId - Element ID for the button or input
 * @param {string} eventType - Event type (click or keypress)
 */
function addUpdateUserInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }
    const username = document.getElementById('update-username').value;
    const password = document.getElementById('update-password').value;
    const password_confirmation = document.getElementById('update-password-confirm').value;

    if (!username && !password) {
      alert('Please fill in at least one field to update');
      return;
    }

    if (password && password !== password_confirmation) {
      alert('Passwords do not match');
      return;
    }

    const user_id = getCookieValue('loggedInUserId');
    if (!user_id) {
      alert('Not logged in');
      return;
    }

    bounceHexagons();

    const updateData = {};
    if (username) updateData.username = username;
    if (password) {
      updateData.password = password;
      updateData.password_confirmation = password_confirmation;
    }

    try {
      const url = `${apiState.protocol}://${apiState.host}/users/${user_id}`;
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user: updateData }),
        credentials: 'include'
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.errors ? data.errors.join(', ') : 'Update failed');
      }

      alert('Account updated!');
      document.getElementById('update-username').value = '';
      document.getElementById('update-password').value = '';
      document.getElementById('update-password-confirm').value = '';

      if (username) {
        const expires_at = new Date(Date.now() + 300 * 24 * 60 * 60 * 1000);
        document.cookie = `loggedInUser=${username}; expires=${expires_at.toUTCString()}; path=/`;
      }
    } catch (error) {
      alert('Error updating account: ' + error.message);
    }
  });
}


/**
 * Open a native WebSocket to the Action Cable endpoint and subscribe to
 * CollectionImportChannel for the given collection id.  Calls onRelease for
 * each broadcast message, then resolves the returned promise once the
 * subscription is confirmed so callers can sequence work after it.
 *
 * @param {number|string} collectionId
 * @param {function} onRelease - called with each incoming release object
 * @returns {{ ws: WebSocket, ready: Promise<void> }}
 */
function connectCollectionImportSocket(collectionId, onRelease) {
  const wsProtocol = apiState.protocol === 'https' ? 'wss' : 'ws';
  const ws = new WebSocket(`${wsProtocol}://${apiState.host}/cable`);
  const identifier = JSON.stringify({ channel: 'CollectionImportChannel', collection_id: collectionId });

  let resolveReady, resolveDone;
  const ready = new Promise((resolve) => { resolveReady = resolve; });
  const done = new Promise((resolve) => { resolveDone = resolve; });

  ws.onopen = () => {
    ws.send(JSON.stringify({ command: 'subscribe', identifier }));
  };

  ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.type === 'welcome' || data.type === 'ping') return;
    if (data.type === 'confirm_subscription') { resolveReady(); return; }
    if (data.message?.type === 'done') { ws.close(); resolveDone(data.message.level); return; }
    if (data.message?.type === 'start') { console.log('Start message', data.message); return; }
    if (data.message) onRelease(data.message);
  };

  return { ws, ready, done };
}

/**
 * Add per-collection update interaction to a button element
 * @param {HTMLElement} button - The update button element
 * @param {HTMLElement} fileInput - The file input element for this collection
 * @param {Object} collection - The collection object with id, name, etc.
 */
function addCollectionItemUpdateInteraction(button, fileInput, collection, updateControls, releaseTickerDiv, levelSpan, expandButton) {
  button.addEventListener('click', async () => {
    const file = fileInput.files[0];
    if (!file) {
      alert('Please select a JSON file');
      return;
    }
    bounceHexagons();

    try {
      const text = await file.text();
      const releases = JSON.parse(text);

      const releaseQueue = [];
      let tickerActive = false;
      let drainPromise = Promise.resolve();

      function showNextRelease() {
        return new Promise(resolve => {
          function tick() {
            if (releaseQueue.length === 0) { tickerActive = false; resolve(); return; }
            const release = releaseQueue.shift();
            releaseTickerDiv.style.display = '';
            releaseTickerDiv.textContent = `${release.artist} - ${release.title} [${release.label}]`;
            setTimeout(tick, 500);
          }
          tick();
        });
      }

      const { ws, ready, done } = connectCollectionImportSocket(collection.id, (release) => {
        if (release.colors && !release.artist) {
          updateHexagonColors(release.colors);
          return;
        }
        console.log('New release added:', release);
        updateControls.style.display = 'none';
        releaseQueue.push(release);
        if (!tickerActive) { tickerActive = true; drainPromise = showNextRelease(); }
      });
      await ready;

      done.then(async (newLevel) => {
        await drainPromise;
        releaseTickerDiv.textContent = 'Collection updated!';
        if (newLevel !== undefined) levelSpan.textContent = ` / level ${newLevel} `;
        setTimeout(() => {
          releaseTickerDiv.style.display = 'none';
          releaseTickerDiv.textContent = '';
          updateControls.style.display = 'none';
          expandButton.innerHTML = '&#x2314;';
        }, 2000);
      });

      const url = `${apiState.protocol}://${apiState.host}/collections/${collection.id}`;
      const response = await fetch(url, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ releases, overwrite_strategy: 'only_new' }),
        credentials: 'include'
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Update failed');
      }

      fileInput.value = '';
      // fetchAndDisplayCollections();
    } catch (error) {
      alert('Error updating collection: ' + error.message);
    }
  });
}

/**
 * Add delete collection interaction
 * @param {string} elementId - Element ID for the button or input
 * @param {string} eventType - Event type (click or keypress)
 */
function addDeleteCollectionInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }
    const collectionName = document.getElementById('delete-collection-name').value;

    if (!collectionName) {
      alert('Please enter a collection name');
      return;
    }

    const collectionExists = userCollections.some(
      c => c.name.toLowerCase() === collectionName.toLowerCase()
    );
    if (!collectionExists) {
      alert('That collection does not exist');
      return;
    }

    const confirmed = confirm(`Are you sure you want to delete the collection "${collectionName}"? This will delete all releases and gardens in this collection. This action cannot be undone.`);
    if (!confirmed) {
      return;
    }

    bounceHexagons();

    try {
      const url = `${apiState.protocol}://${apiState.host}/collections/${collectionName.toLowerCase()}`;
      const response = await fetch(url, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include'
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Delete failed');
      }

      alert('Collection deleted!');
      document.getElementById('delete-collection-name').value = '';
      fetchAndDisplayCollections();
    } catch (error) {
      alert('Error deleting collection: ' + error.message);
    }
  });
}

/**
 * Add delete user interaction
 * @param {string} elementId - Element ID for the button or input
 * @param {string} eventType - Event type (click or keypress)
 */
function addDeleteUserInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }

    const user_id = getCookieValue('loggedInUserId');
    if (!user_id) {
      alert('Not logged in');
      return;
    }

    if (!window.confirm("Are you sure you want to delete this user and all of their data?  There is no undo !")) {
      return;
    }

    if (!window.confirm("Seriously, there's no undo, you're about to delete everything.  Are you *sure* ??")) {
      return;
    }

    try {
      const url = `${apiState.protocol}://${apiState.host}/users/${user_id}`;
      const response = await fetch(url, {
        method: 'DELETE',
        credentials: 'include'
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.errors ? data.errors.join(', ') : 'User Delete failed');
      }

      alert('User deleted, we will miss you!');
    } catch (error) {
      alert('Error deleting account: ' + error.message);
    }
  });
}
/**
 * Add dark mode / light mode toggle 
 * @param {string} elementId - Element ID for the logout button
 * @param {string} eventType - Event type (click or keypress)
 */
function addModeChangeInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }
    var currentTheme = localStorage.getItem('theme') || "light-mode";

    if (currentTheme === "light-mode") {
      currentTheme = "dark-mode";
    } else {
      currentTheme = "light-mode";
    }
    document.documentElement.setAttribute('data-theme', currentTheme);
    localStorage.setItem('theme', currentTheme);
  });
}

/**
 * Add logout interaction
 * @param {string} elementId - Element ID for the logout button
 * @param {string} eventType - Event type (click or keypress)
 */
function addLogoutInteraction(elementId, eventType) {
  document.getElementById(elementId).addEventListener(eventType, async (e) => {
    if (eventType === "keypress" && e.key !== "Enter") {
      return;
    }

    try {
      const url= `${apiState.protocol}://${apiState.host}/logout`;
      const response = await fetch(url, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include'
      });

      if (!response.ok) {
        throw new Error('Logout failed');
      }
    } catch (error) {
      alert('Logout error: ' + error);
    }

    document.cookie = "loggedInUser=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    document.cookie = "loggedInUserId=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    displayLoggedOut();
  });
}

/**
 * Reset UI when logged out
 */
function displayLoggedOut() {
  if (!checkCookieExistence('loggedInUser')) {
    document.getElementById('login-fields').style.display = '';
    document.getElementById('login-input').disabled = false;
    document.getElementById('login-input').value = "";
    document.getElementById('password-input').disabled = false;
    document.getElementById('password-input').value = "";
    document.getElementById('login-submit').disabled = false;

    document.getElementById('logout-fields').style.display = 'none';
    document.getElementById('logout-button').disabled = true;

    document.getElementById('login-submit').style.display = '';
    document.getElementById('reset-password-container').style.display = 'none';
    document.getElementById('collections-container').style.display = 'none';
    document.getElementById('collections-list').innerHTML = '';
    document.getElementById('create-user-container').style.display = '';
    document.getElementById('forgot-password-container').style.display = '';
    document.getElementById('update-user-container').style.display = 'none';
    document.getElementById('new-collection-container').style.display = 'none';
    document.getElementById('delete-collection-container').style.display = 'none';

    document.getElementById('settings-toggle-container').style.display = 'none';
    document.getElementById('settings-container').classList.add("is-hidden")
  }
}

/**
 * Display login-related UI elements if logged in
 */
function displayLoggedIn() {
  if (checkCookieExistence('loggedInUser')) {
    document.getElementById('login-fields').style.display = 'none';
    document.getElementById('login-input').disabled = true;
    document.getElementById('password-input').disabled = true;
    document.getElementById('login-submit').disabled = true;

    document.getElementById('logout-fields').style.display = '';
    document.getElementById('logout-button').disabled = false;

    document.getElementById('create-user-container').style.display = 'none';
    document.getElementById('forgot-password-container').style.display = 'none';
    document.getElementById('update-user-container').style.display = '';
    document.getElementById('new-collection-container').style.display = '';
    document.getElementById('delete-collection-container').style.display = '';

    displaySettings = false;
    document.getElementById('settings-toggle-container').style.display = '';
    document.getElementById('settings-container').classList.add("is-hidden")
    document.getElementById("settings-container").classList.remove("is-visible");
    fetchAndDisplayCollections();
  } else {
    document.getElementById('settings-toggle-container').style.display = 'none';
    document.getElementById('settings-container').classList.add("is-hidden")
    document.getElementById("settings-container").classList.remove("is-visible");
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

/**
 * Get a cookie value by name
 * @param {string} cookie_name - Name of the cookie
 * @returns {string|null} - Cookie value or null if not found
 */
function getCookieValue(cookie_name) {
  let decodedCookie = decodeURIComponent(document.cookie);
  let cookies = decodedCookie.split(';');
  for (let i = 0; i < cookies.length; i++) {
    const parts = cookies[i].split('=');
    const name = parts[0].trim();
    if (name === cookie_name) {
      return parts[1];
    }
  }
  return null;
}

/**
 * Display collections in a list
 * @param {Array} collections - Array of collection objects
 */
function displayCollections(collections) {
  const collectionsList = document.getElementById('collections-list');
  const collectionsContainer = document.getElementById('collections-container');

  collectionsList.innerHTML = '';

  if (collections && collections.length > 0) {
    collections.forEach(collection => {
      const li = document.createElement('li');
      const link = document.createElement('a');

      const expandButton = document.createElement('button');
      expandButton.innerHTML = '&#x2314;';
      expandButton.title = 'Expand';

      const updateControls = document.createElement('span');
      updateControls.style.display = 'none';

      const fileInput = document.createElement('input');
      fileInput.type = 'file';

      const releaseTickerDiv = document.createElement('div');
      releaseTickerDiv.style.display = 'none';

      const levelSpan = document.createElement('span');
      levelSpan.textContent = ` / level ${collection.level} `;

      const updateButton = document.createElement('button');
      updateButton.innerText = 'Update';
      addCollectionItemUpdateInteraction(updateButton, fileInput, collection, updateControls, releaseTickerDiv, levelSpan, expandButton);

      updateControls.appendChild(fileInput);
      updateControls.appendChild(updateButton);

      expandButton.addEventListener('click', () => {
        const expanded = updateControls.style.display !== 'none';
        updateControls.style.display = expanded ? 'none' : '';
        expandButton.innerHTML = expanded ? '&#x2314;' : '&#x25B2;';
      });

      link.href = `/collections?c=${collection.name.toLowerCase()}`;
      link.textContent = collection.name;
      li.appendChild(link);
      li.appendChild(levelSpan);
      li.appendChild(expandButton);
      li.appendChild(document.createElement('br'));
      li.appendChild(updateControls);
      li.appendChild(releaseTickerDiv);
      collectionsList.appendChild(li);
    });
    collectionsContainer.style.display = '';
  } else {
    collectionsContainer.style.display = 'none';
  }
}

/**
 * Fetch and display user's collections
 */
function fetchAndDisplayCollections() {
  const url = `${apiState.protocol}://${apiState.host}/collections`;
  fetch(url, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
    credentials: 'include'
  })
    .then(response => {
      if (response.ok) {
        return response.json();
      } else {
        console.error('Failed to fetch collections:', response.status);
        return [];
      }
    })
    .then(collections => {
      userCollections = collections || [];
      displayCollections(collections);
    })
    .catch(error => {
      console.error('Error fetching collections:', error);
    });
}



// Globals
var displaySettings = false;

// Entrypoint
window.addEventListener("load", (event) => {
  drawLoginHexagons();
  addLoginInteraction("password-input", "keypress");
  addLoginInteraction("login-submit", "keypress");
  addLoginInteraction("login-submit", "click");
  addLogoutInteraction("logout-button", "click");
  addLogoutInteraction("logout-button", "keypress");

  addModeChangeInteraction("dark-mode-button", "click");
  addModeChangeInteraction("dark-mode-button", "keypress");

  addCreateUserInteraction("create-password-confirm", "keypress");
  addCreateUserInteraction("create-user-submit", "click");
  addUpdateUserInteraction("update-password-confirm", "keypress");
  addUpdateUserInteraction("update-user-submit", "click");
  addDeleteUserInteraction("delete-user-submit", "click");

  addNewCollectionInteraction("new-collection-submit", "click");
  addDeleteCollectionInteraction("delete-collection-submit", "click");

  addResetPasswordRequestInteraction("forgot-password-submit", "click");
  addResetPasswordRequestInteraction("forgot-password-email", "keypress");
  addResetPasswordSubmitInteraction("reset-new-password-confirm", "keypress");
  addResetPasswordSubmitInteraction("reset-password-submit", "click");

  addSettingsToggleInteraction("settings-toggle", "click");
  addSettingsToggleInteraction("settings-toggle", "keypress");

  const resetToken = new URLSearchParams(window.location.search).get('reset_token');
  if (resetToken) {
    document.getElementById('login-fields').style.display = 'none';
    document.getElementById('create-user-container').style.display = 'none';
    document.getElementById('forgot-password-container').style.display = 'none';
    document.getElementById('reset-password-container').style.display = '';
  }

  displayLoggedIn();
});
