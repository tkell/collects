/**
 * New UI helpers to replace fabric.js UI functionality with standard HTML/CSS
 */
let uiHelper = {};

/**
 * Wait for a specified number of milliseconds
 * @param {number} ms - Milliseconds to wait
 * @returns {Promise} - Promise that resolves after the wait
 */
uiHelper.waitFor = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Text update functions
/**
 * Clear the text display
 */
uiHelper.clearText = function() {
  const t = document.getElementById('text');
  t.textContent = '_';
};

/**
 * Update text with artist and title
 * @param {Object} record - Record object
 */
uiHelper.updateTextWithArtistAndTitle = function(record) {
  const t = document.getElementById('text');
  t.textContent = `${record.artist} - ${record.title} [${record.label}]`;
};

/**
 * Update text with just the title
 * @param {Object} record - Record object
 */
uiHelper.updateTextWithTitle = function(record) {
  if (!uiState.bigImage.isShowing) {
    const t = document.getElementById('text');
    t.textContent = record.title;
  }
};

/**
 * Update text styling for focus
 * @param {Object} record - Record object
 */
uiHelper.updateTextForFocus = function(record) {
  // A note for my future self that "transparent" here is needed
  // for the gradient to show through.
  // So the `colorFade` steps that return to "transparent" actually show the gradient!
  const textElement = document.getElementById("text");
  const gradientString = `linear-gradient(90deg, ${record.currentVariant.colors[0]}, ${record.currentVariant.colors[1]})`;
  textElement.style.backgroundImage = gradientString;
  textElement.style.color = "transparent";
  textElement.style.backgroundClip = "text";
  
  const colorFade = [
    {color: record.currentVariant.colors[0]},
    {color: "transparent"},
    {color: record.currentVariant.colors[1]},
    {color: "transparent"},
    {color: record.currentVariant.colors[0]},
  ];
  const colorFadeTiming = {
    duration: 6000,
    iterations: 6,
  };
  const textAnimation = textElement.animate(colorFade, colorFadeTiming);
  record.textAnimation = textAnimation;
};

/**
 * Reset text styling after focus ends
 * @param {Object} record - Record object
 */
uiHelper.resetTextForFocus = function(record) {
  const textElement = document.getElementById("text");
  textElement.style.backgroundImage = "initial";
  textElement.style.color = "black";
  textElement.style.backgroundClip = "initial";
  textElement.style.webkitBackgroundClip = "initial";
  
  if (record.textAnimation) {
    record.textAnimation.cancel();
    record.textAnimation = undefined;
  }
};

/**
 * Update text for local playback
 * @param {Object} record - Record object
 */
uiHelper.updateTextForLocalPlayback = function(record) {
  const textElement = document.getElementById("text");
  const contents = textElement.innerHTML;
  record.originalTitle = contents;
  const contentsWithPlayButtons = "&#x25b6; " + contents + " &#x25b6;";
  textElement.innerHTML = contentsWithPlayButtons;
  textElement.style.cursor = "pointer";
};

/**
 * Reset text after local playback
 * @param {Object} record - Record object
 */
uiHelper.resetTextForLocalPlayback = function(record) {
  const textElement = document.getElementById("text");
  textElement.innerHTML = record.originalTitle;
  record.originalTitle = undefined;
  textElement.style.cursor = "default";
};

/**
 * Update text with track information
 * @param {Object} record - Record object
 */
uiHelper.updateTextWithTrack = function(record) {
  const t = document.getElementById('track-text');
  const track = record.tracks[record.nextTrackToShow];
  const trackString = `${track.position} - ${track.title}`;
  t.textContent = trackString;
  record.nextTrackToShow = (record.nextTrackToShow + 1) % record.tracks.length;
};

/**
 * Clear track text
 */
uiHelper.clearTrack = function() {
  const t = document.getElementById('track-text');
  t.textContent = "-";
};

/**
 * Run background gradient effect
 * @param {Object} record - Record object with color information
 */
uiHelper.runBackgroundGradient = function(record) {
  const bodyElement = document.body;
  const index = record.id % 4;
  const angles = [0, 90, 180, 270];
  const starts = ["0% 0%", "0% 0%", "0% 100%", "100% 0%"];
  const ends = ["0% 100%", "100% 0%", "0% 0%", "0% 0%"];
  
  // This depends on the body having size 600%, 600%!
  const gradientString = `linear-gradient(${angles[index]}deg, #FFF, #FFF, ${record.currentVariant.colors[0]}, ${record.currentVariant.colors[1]}, #FFF, #FFF)`;
  bodyElement.style.backgroundImage = gradientString;
  
  const keyFrames = [
    { backgroundPosition: starts[index] },
    { backgroundPosition: ends[index] }
  ];
  
  bodyElement.animate(keyFrames, {
    duration: 4000,
    iterations: 1,
  });
};

// Animation wrappers
/**
 * Bounce a record with large movement
 * @param {Object} record - Record object
 */
uiHelper.bounceRecord = function(record) {
  if (!record.isAnimating) {
    animationHelper.makeBounce(record);
  }
};

/**
 * Bounce a record with small movement
 * @param {Object} record - Record object
 */
uiHelper.bounceRecordSmall = function(record) {
  if (!record.isAnimating) {
    animationHelper.makeSmallBounce(record);
  }
};

/**
 * Fade out a record
 * @param {Object} record - Record object
 */
uiHelper.fadeOutRecord = function(record) {
  return animationHelper.makeFadeOut(record);
};

/**
 * Fade in a record, hard-sets opacity
 * @param {Object} record - Record object
 * @returns {Promise} - Promise that resolves when fade-in completes
 */
uiHelper.fadeInRecord = function(record) {
  return animationHelper.makeFadeIn(record).then(() => {
    record.imageItem.style.opacity = '';
  });
};

/**
 * Move a record to a new position
 * @param {Object} record - Record object
 * @param {number} newX - New X position
 * @param {number} newY - New Y position
 */
uiHelper.moveRecordTo = function(record, newX, newY) {
  animationHelper.makeMove(record, newX, newY);
};

/**
 * Apply a random ambient animation to a record
 * @param {Object} record - Record object
 */
uiHelper.ambientAnimate = function(record) {
  // Temporarily disabled ambient animations
  return;
};

// Available ambient animations
uiHelper._ambientAnimations = [
  uiHelper.bounceRecord,
  uiHelper.bounceRecord,
  uiHelper.bounceRecordSmall,
  uiHelper.bounceRecordSmall,
  function(record) {
    if (!record.isAnimating) {
      animationHelper.makeWalkabout(record);
    }
  }
];

/**
 * Make the big image bounce
 */
uiHelper.bounceBigImage = function() {
  if (uiState.bigImage.isShowing && !uiState.bigImage.isAnimating) {
    animationHelper.bounceBigImage();
  }
};

// Image handling functions
/**
 * Hide all image items
 * @param {Array} data - Array of record objects
 */
uiHelper.hideExistingImages = function(data) {
  for (let i = 0; i < data.length; i++) {
    const element = animationHelper.getRecordElement(data[i]);
    if (element) {
      element.style.visibility = 'hidden';
    }
  }
};

/**
 * Show all image items
 * @param {Array} data - Array of record objects
 */
uiHelper.showExistingImages = function(data) {
  for (let i = 0; i < data.length; i++) {
    const element = animationHelper.getRecordElement(data[i]);
    if (element) {
      element.style.visibility = 'visible';
    }
  }
};

/**
 * Show the big image
 * @param {Object} record - Record to display
 * @param {Array} data - All records data
 * @returns {Promise} - Promise that resolves when image is displayed
 */
uiHelper.loadBigImage = function(record) {
  return imageHelper.loadBigImage(record)
    .then(imgElement => {
      // Set up event handlers for the big image
      const bigImageElement = document.getElementById('big-image-wrapper');
      
      bigImageElement.onclick = function(e) {
        record.onBigImageClose();
      };
      
      bigImageElement.onmouseover = function() {
        uiHelper.updateTextWithTrack(record);
        uiHelper.bounceBigImage();
      };
      
      return imgElement;
    });
};

/**
 * Remove the big image display
 */
uiHelper.removeBigImage = function() {
  imageHelper.removeBigImage();
  
  // Remove event handlers
  const bigImageContainer = document.getElementById('big-image-container');
  bigImageContainer.onclick = null;
  bigImageContainer.onmouseover = null;
};

/**
 * Draw preload hexagons before images load
 * @param {Object} tess - Tessellation configuration
 */
uiHelper.drawPreloadHexagons = function(tess) {
  const gridContainer = document.getElementById('image-grid');
  
  // Clear existing content
  gridContainer.innerHTML = '';
  
  // Update CSS variables for grid layout
  const gridSize = tess.size;
  const gridColumns = Math.sqrt(tess.defaultItems);
  const gridRows = Math.sqrt(tess.defaultItems);
  
  document.documentElement.style.setProperty('--grid-size', `${gridSize}px`);
  document.documentElement.style.setProperty('--grid-columns', gridColumns);
  document.documentElement.style.setProperty('--grid-rows', gridRows);
  
  // Create placeholder items
  for (let i = 0; i < tess.defaultItems; i++) {
    const placeholder = document.createElement('div');

    // Apply tessellation-specific positioning classes
    if (tess.type === 'circle') {
      placeholder.className = `image-item shape-circle circle-item-${i % 12}`;
    } else {
      placeholder.className = 'image-item';
    }
    
    const hexLoader = document.createElement('div');
    hexLoader.className = 'hex-loader';
    
    // Randomize the hex loader appearance
    const timeout = Math.floor(Math.random() * 3000) + 250;
    
    placeholder.appendChild(hexLoader);
    gridContainer.appendChild(placeholder);
    
    // Add animation after random timeout
    setTimeout(() => {
      placeholder.classList.add('small-bounce');
    }, timeout);
  }
};

/**
 * Set up mouse event listeners for a record
 * @param {Object} record - Record object
 * @param {Array} data - Array of all records
 */
uiHelper.setupEventListeners = function(record, data) {
  const element = animationHelper.getRecordElement(record);
  if (!element) return;
  
  element.onmouseover = function() {
    uiHelper.updateTextWithTitle(record);
    uiHelper.bounceRecord(record)
  };
  
  element.onclick = function() {
    record.onMouseDown();
  };
};

/**
 * Replace close-up images
 * @param {Object} record - Selected record
 * @param {Array} data - All records data
 * @param {number} maxTimeMs - Maximum animation time
 * @returns {Promise} - Promise that resolves when all replacements are done
 */
uiHelper.replaceCloseUpImage = function(record, data, maxTimeMs) {
  const promises = [];
  
  for (let i = 0; i < data.length; i++) {
    const otherRecord = data[i];
    if (!otherRecord.isCloseUp) continue;
    
    const timeoutMs = record.timeoutFunction(i, data.length, maxTimeMs);
    const p = promiseToLoadCloseUpImage(record, otherRecord, timeoutMs, data.length);
    promises.push(p);
  }
  
  return Promise.all(promises);
};

function promiseToLoadCloseUpImage(record, otherRecord, timeoutMs, dataLength) {
  return new Promise(function(resolve, reject) {
    setTimeout(() => {
      return uiHelper.loadCloseUpReplacementImage(record, otherRecord, dataLength).then(() => resolve());
    }, timeoutMs);
  });
}

uiHelper.loadCloseUpReplacementImage = function(record, otherRecord, dataLength) {
  return new Promise((resolve) => {
    const closeUpElement = document.createElement('div');
    closeUpElement.className = 'close-up-image';
    closeUpElement.style.position = 'absolute';
    closeUpElement.style.backgroundImage = `url(${record.imagePath})`;
    closeUpElement.style.zIndex = '15';
    
    // Get the position of the grid item we're replacing
    const otherElement = animationHelper.getRecordElement(otherRecord);
    const rect = otherElement.getBoundingClientRect();
    const gridContainer = document.getElementById('image-grid');
    const gridRect = gridContainer.getBoundingClientRect();
    
    // Position at the grid item location
    closeUpElement.style.left = `${rect.left - gridRect.left}px`;
    closeUpElement.style.top = `${rect.top - gridRect.top}px`;
    closeUpElement.style.width = `${rect.width}px`;
    closeUpElement.style.height = `${rect.height}px`;

    // Calculate where this image should be positioned relative to this grid item,
    // and position the background image so it appears correctly when clipped
    const itemLeftX = rect.left - gridRect.left;
    const itemTopY = rect.top - gridRect.top;
    const bigImageWrapper = document.getElementById('big-image-wrapper');
    const bigImgElement = bigImageWrapper.querySelector('img');
    const bigImgRect = bigImgElement.getBoundingClientRect();
    const tessellationRect = document.querySelector('.tessellation-container').getBoundingClientRect();

    // Calculate where the center of the big image is relative to the tessellation container
    const bigImageCenterX = (bigImgRect.left + bigImgRect.width / 2) - tessellationRect.left;
    const bigImageCenterY = (bigImgRect.top + bigImgRect.height / 2) - tessellationRect.top;
    const offsetX = bigImageCenterX - (bigImgRect.width / 2) - itemLeftX;
    const offsetY = bigImageCenterY - (bigImgRect.height / 2) - itemTopY;

    // Set styles
    closeUpElement.style.backgroundSize = 'auto auto';
    closeUpElement.style.backgroundPosition = `${offsetX}px ${offsetY}px`;
    closeUpElement.style.backgroundRepeat = 'no-repeat';
    closeUpElement.style.clipPath = otherRecord.clipPath;
    
    // Add to grid container
    const container = document.getElementById('image-grid');
    container.appendChild(closeUpElement);
    
    // Store reference for cleanup
    if (!uiState.closeUpImages) {
      uiState.closeUpImages = [];
    }
    uiState.closeUpImages.push({
      element: closeUpElement,
      index: otherRecord.index
    });
    
    resolve(closeUpElement);
  });
};


uiHelper.hideCloseUpImages = function(record, data) {
  if (uiState.closeUpImages) {
    for (let tempImage of uiState.closeUpImages) {
      tempImage.element.style.visibility = "hidden";
    }
  }
}

/**
 * Remove close-up images
 * @param {Object} record - Record object
 * @param {Array} data - All records data
 * @param {number} maxTimeMs - Maximum animation time
 * @returns {Promise} - Promise that resolves when all images are removed
 */
uiHelper.removeCloseUpImages = function(record, data, maxTimeMs) {
  const promises = [];
  
  if (uiState.closeUpImages) {
    for (let tempImage of uiState.closeUpImages) {
      tempImage.element.style.visibility = "visible";
      const timeoutMs = record.reverseTimeoutFunction(tempImage.index, data.length, maxTimeMs);
      const p = promiseToRemoveCloseUpImage(tempImage.element, timeoutMs);
      promises.push(p);
    }
    uiState.closeUpImages = [];
  }
  
  return Promise.all(promises);
};

function promiseToRemoveCloseUpImage(element, timeoutMs) {
  return new Promise(function(resolve, reject) {
    setTimeout(() => {
      if (element && element.parentNode) {
        element.parentNode.removeChild(element);
      }
      resolve();
    }, timeoutMs);
  });
}

/**
 * Handle replacing other records during big image view
 * @param {Object} record - Selected record
 * @param {Array} data - All records data
 * @param {number} maxTimeMs - Maximum animation time
 * @returns {Promise} - Promise that resolves when replacement is complete
 */
uiHelper.replaceOtherRecords = function(record, data, maxTimeMs) {
  const promises = [];
  
  for (let i = 0; i < data.length; i++) {
    const otherRecord = data[i];
    const timeoutMs = record.timeoutFunction(i, data.length, maxTimeMs);
    const p = new Promise((resolve) => {
      setTimeout(() => {
        const otherElement = animationHelper.getRecordElement(otherRecord);
        if (otherElement) {
          // Create overlay element with the selected record's image
          const overlay = document.createElement('div');
          overlay.className = 'temp-image-overlay';
          overlay.style.backgroundImage = `url(${record.smallImagePath})`;
          overlay.style.backgroundSize = 'cover';
          overlay.style.backgroundPosition = 'center';
          overlay.style.position = 'absolute';
          overlay.style.top = '0';
          overlay.style.left = '0';
          overlay.style.width = '100%';
          overlay.style.height = '100%';
          overlay.style.zIndex = '10';
          
          otherElement.style.position = 'relative';
          otherElement.appendChild(overlay);
          otherRecord.tempImageOverlay = overlay;
        }
        resolve();
      }, timeoutMs);
    });
    promises.push(p);
  }
  
  return Promise.all(promises);
};

/**
 * Restore other records after closing big image
 * @param {Object} record - Selected record
 * @param {Array} data - All records data
 * @param {number} maxTimeMs - Maximum animation time
 * @returns {Promise} - Promise that resolves when restoration is complete
 */
uiHelper.restoreOtherRecords = function(record, data, maxTimeMs) {
  const promises = [];
  
  for (let i = 0; i < data.length; i++) {
    const otherRecord = data[i];
    const timeoutMs = record.reverseTimeoutFunction(i, data.length, maxTimeMs);
    const p = new Promise((resolve) => {
      setTimeout(() => {
        if (otherRecord.tempImageOverlay) {
          otherRecord.tempImageOverlay.remove();
          otherRecord.tempImageOverlay = undefined;
        }
        resolve();
      }, timeoutMs);
    });
    promises.push(p);
  }
  
  return Promise.all(promises);
};
