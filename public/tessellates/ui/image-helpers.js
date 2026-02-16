/**
 * New image helpers to replace fabric.js image functionality with standard HTML/CSS
 */
let imageHelper = {};

/**
 * Load images for all records in the data array
 * @param {Array} data - Array of record objects
 * @returns {Promise} - Promise that resolves when all images are loaded
 */
imageHelper.loadImages = function(data) {
  let promises = [];
  for (let record of data) {
    let promise = imageHelper.loadImage(record.smallImagePath)
      .then(img => {
        record.imageElement = img;
      });
    promises.push(promise);
  }
  return Promise.all(promises);
};

/**
 * Load a single image
 * @param {string} imagePath - Path to the image
 * @returns {Promise} - Promise that resolves with the image element
 */
imageHelper.loadImage = function(imagePath) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = function() {
      resolve(img);
    };
    img.onerror = function() {
      reject(new Error(`Failed to load image: ${imagePath}`));
    };
    img.src = imagePath;
  });
};

/**
 * Create the preliminary image item DOM element for a record
 * @param {Object} record - Record object containing image data
 * @returns {HTMLElement} - The created image item element
 */
imageHelper.createDivAndPlaceholder = function(record) {
  // Create container div
  const imageItem = document.createElement('div');
  imageItem.id = `image-item-${record.id}`;
  imageItem.dataset.recordId = record.id;
  
  // Apply positioning classes immediately (if they exist) for consistent placement
  // But exclude rhombus transforms for placeholders - they should be in natural grid positions
  if (record.clipPathClass && record.positionClass) {
    imageItem.className = `image-item ${record.clipPathClass} ${record.positionClass}`;
  } else {
    imageItem.className = 'image-item';
  }
  
  // Add gradient based on record colors
  const hexLoader = document.createElement('div');
  hexLoader.className = 'hex-loader';
  hexLoader.style.setProperty('--color1', record.currentVariant.colors[0]);
  hexLoader.style.setProperty('--color2', record.currentVariant.colors[1]);
  
  const timeout = Math.floor(Math.random() * 1000) + 250;
  setTimeout(() => {
    animationHelper.makeSmallBounceRaw(hexLoader);
  }, timeout);
  imageItem.appendChild(hexLoader);
  
  return imageItem;
};

/**
 * Create an image item DOM element for a record
 * @param {Object} record - Record object containing image data
 * @param {string} shapeClass - CSS class for the shape (square, circle, triangle, rhombus)
 * @returns {HTMLElement} - The created image item element
 */
imageHelper.loadImageItem = function(record, shapeClass) {
  const imageItem = record.imageItem;
  const imgClone = record.imageElement.cloneNode(true);
  const hexLoader = imageItem.children[0];
  imageItem.replaceChild(imgClone, hexLoader);
  imageItem.className = `image-item ${shapeClass}`;
  
  return imageItem;
};

/**
 * Render a grid of images
 * @param {Array} data - Array of record objects
 * @param {Object} tessellation - Tessellation configuration
 * @param {string} gridContainerId - ID of the grid container element
 */
imageHelper.renderImageGridAndPreview = function(data, tessellation, gridContainerId = 'image-grid') {
  const gridContainer = document.getElementById(gridContainerId);
  // Clear existing content
  gridContainer.innerHTML = '';
  
  // Update CSS variables for grid layout
  const gridSize = tessellation.size;
  let gridColumns, gridRows;
  
  // Handle different tessellation types
  if (tessellation.type === 'triangle') {
    gridColumns = 9; // 9 triangles per row
    gridRows = 5;    // 5 rows
  } else if (tessellation.type === 'rhombus') {
    gridColumns = 8; // 8 columns for rhombus positioning
    gridRows = 4;    // 4 overlapping rows
  } else {
    // For square, circle - use square grid
    gridColumns = Math.sqrt(tessellation.defaultItems);
    gridRows = Math.sqrt(tessellation.defaultItems);
  }
  
  document.documentElement.style.setProperty('--grid-size', `${gridSize}px`);
  document.documentElement.style.setProperty('--grid-columns', gridColumns);
  document.documentElement.style.setProperty('--grid-rows', gridRows);

  // First, add all elements to DOM sequentially (for reliable nth-child CSS)
  for (let i = 0; i < data.length; i++) {
    const record = data[i];
    const imageItem = imageHelper.createDivAndPlaceholder(record);
    imageItem.style.visibility = 'hidden'; // Hide initially
    record.imageItem = imageItem;
    gridContainer.appendChild(imageItem);
  }

  // Then use timeouts to reveal them with the original animation timing
  const timeoutFunction = renderHelper._pickTimeout(tessellation);
  const promises = []
  for (let i = 0; i < data.length; i++) {
    const record = data[i];
    timeout = timeoutFunction(i, data.length, tessellation.timeouts["slow"])
    const p = new Promise(function (resolve, reject) {
      setTimeout(() => {
        record.imageItem.style.visibility = 'visible'; // Reveal with animation timing
        resolve();
      }, timeout);
    });
    promises.push(p);
  }

  return Promise.all(promises);
}

imageHelper.addImages = function(data, tessellation, gridContainerId = 'image-grid') {
  const timeoutFunction = renderHelper._pickTimeout(tessellation);
  const promises = [];
  for (let i = 0; i < data.length; i++) {
    const record = data[i];
    timeout = timeoutFunction(i, data.length, tessellation.timeouts["slow"])
    const p = new Promise(function (resolve, reject) {
      setTimeout(() => {
        // Use record's specific classes instead of generic shape class
        const classes = `${record.clipPathClass} ${record.positionClass}`.trim();
        const imageItem = imageHelper.loadImageItem(record, classes);
        resolve();
      }, timeout);
    });
    promises.push(p);
  }
  return Promise.all(promises);
};

/**
 * Clear the grid of all elements (like canvas.clear() in fabric.js)
 * @param {string} gridContainerId - ID of the grid container
 * @returns {Promise} - Promise that resolves immediately after clearing
 */
imageHelper.clearGrid = function(gridContainerId = 'image-grid') {
  const gridContainer = document.getElementById(gridContainerId);
  gridContainer.innerHTML = '';
  return Promise.resolve();
};

/**
 * Add images instantly without timeout delays (for pagination)
 * Sets up DOM structure first, then adds all images immediately
 * @param {Array} data - Array of record objects
 * @param {Object} tessellation - Tessellation configuration
 * @param {string} gridContainerId - ID of the grid container
 * @returns {Promise} - Promise that resolves when all images are added
 */
imageHelper.addImagesInstantly = function(data, tessellation, gridContainerId = 'image-grid') {
  const gridContainer = document.getElementById(gridContainerId);

  // First, set up the grid structure and CSS variables (like renderImageGridAndPreview)
  const gridSize = tessellation.size;
  let gridColumns, gridRows;

  if (tessellation.type === 'triangle') {
    gridColumns = 9;
    gridRows = 5;
  } else if (tessellation.type === 'rhombus') {
    gridColumns = 8;
    gridRows = 4;
  } else {
    gridColumns = Math.sqrt(tessellation.defaultItems);
    gridRows = Math.sqrt(tessellation.defaultItems);
  }

  document.documentElement.style.setProperty('--grid-size', `${gridSize}px`);
  document.documentElement.style.setProperty('--grid-columns', gridColumns);
  document.documentElement.style.setProperty('--grid-rows', gridRows);

  // Create DOM elements and add images immediately
  for (let i = 0; i < data.length; i++) {
    const record = data[i];

    // Create the DOM structure
    const imageItem = imageHelper.createDivAndPlaceholder(record);
    record.imageItem = imageItem;
    gridContainer.appendChild(imageItem);

    // Immediately add the image (no timeout)
    const classes = `${record.clipPathClass} ${record.positionClass}`.trim();
    imageHelper.loadImageItem(record, classes);
  }

  return Promise.resolve();
};

/**
 * Display a large image in the big image container
 * @param {Object} record - Record object containing image data
 * @returns {Promise} - Promise that resolves when the image is displayed
 */
imageHelper.loadBigImage = function(record) {
  return new Promise((resolve, reject) => {
    const bigImageContainer = document.getElementById('big-image-container');
    const bigImageWrapper = document.getElementById('big-image-wrapper');
    
    // Clear existing content
    bigImageWrapper.innerHTML = '';
    
    imageHelper.loadImage(record.imagePath)
      .then(img => {
        record.bigImageElement = img;
        record.bigImage = img;
        bigImageWrapper.className = `big-image-wrapper ${record.bigClipPathClass}`;
        
        // Add image to container, but don't show it yet
        bigImageWrapper.appendChild(img);
        resolve(img);
      })
      .catch(error => {
        console.error(error);
        reject(error);
      });
  });
};

/**
 * Remove the big image display
 */
imageHelper.removeBigImage = function() {
  const bigImageContainer = document.getElementById('big-image-container');
  bigImageContainer.classList.remove('active');
};

/**
 * Preload an image
 * @param {string} imagePath - Path to the image
 * @returns {Promise} - Promise that resolves when the image is loaded
 */
imageHelper.preloadImage = function(imagePath) {
  return imageHelper.loadImage(imagePath);
};
