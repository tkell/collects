/**
 * New animation helpers to replace fabric.js animations with CSS animations
 */
let animationHelper = {};
animationHelper.bouncePicker = {0: 'bounce-up', 1: 'bounce-left', 2: 'bounce-down', 3: 'bounce-right'}

/**
 * Get the HTML element for a record
 * @param {Object} record - Record object
 * @returns {HTMLElement} - The image item element
 */
animationHelper.getRecordElement = function(record) {
  return document.getElementById(`image-item-${record.id}`);
};

/**
 * Apply an animation to an element by adding and removing a class
 * @param {HTMLElement} element - Element to animate
 * @param {string} animationClass - CSS class for the animation
 * @param {number} duration - Duration of the animation in milliseconds
 * @returns {Promise} - Promise that resolves when the animation is complete
 */
animationHelper.animate = function(element, animationClass, duration) {
  return new Promise((resolve) => {
    if (!element) {
      resolve();
      return;
    }
    
    // Set record as animating
    if (element.dataset && element.dataset.recordId) {
      const recordId = element.dataset.recordId;
      const record = findRecordById(recordId);
      if (record) {
        // Skip if already animating to avoid conflicts
        if (record.isAnimating) {
          resolve();
          return;
        }
        record.isAnimating = true;
      }
    }
    
    // Add animation class
    element.classList.add(animationClass);
    
    // Set timeout to remove class after animation completes
    setTimeout(() => {
      element.classList.remove(animationClass);
      
      // Reset record animation state
      if (element.dataset && element.dataset.recordId) {
        const recordId = element.dataset.recordId;
        const record = findRecordById(recordId);
        if (record) {
          record.isAnimating = false;
        }
      }
      
      resolve();
    }, duration);
  });
};

/**
 * Make a record bounce
 * @param {Object} record - Record object
 * @returns {Promise} - Promise that resolves when the animation is complete
 */
animationHelper.makeBounce = function(record) {
  const element = animationHelper.getRecordElement(record);
  const bounceIndex = Math.floor(Math.random() * 4)

  const bounceDirection = animationHelper.bouncePicker[bounceIndex];
  return animationHelper.animate(element, bounceDirection, 725);
};

/**
 * Make any element bounce, in a random direction
 * @param {Object} element - any element, e.g. preload Hexes
 * @returns {Promise} - Promise that resolves when the animation is complete
 */
animationHelper.makeSmallBounceRaw = function(element) {
  const bounceIndex = Math.floor(Math.random() * 4);
  const bounceDirection = animationHelper.bouncePicker[bounceIndex]
  return animationHelper.animate(element, bounceDirection, 350);
};

/**
 * Make a record bounce with a smaller movement
 * @param {Object} record - Record object
 * @returns {Promise} - Promise that resolves when the animation is complete
 */
animationHelper.makeSmallBounce = function(record) {
  const element = animationHelper.getRecordElement(record);
  return animationHelper.animate(element, 'small-bounce', 350);
};

/**
 * Fade out a record
 * @param {Object} record - Record object
 * @returns {Promise} - Promise that resolves when the animation is complete
 */
animationHelper.makeFadeOut = function(record) {
  const element = animationHelper.getRecordElement(record);
  return animationHelper.animate(element, 'fade-out', 725);
};

/**
 * Fade in a record
 * @param {Object} record - Record object
 * @returns {Promise} - Promise that resolves when the animation is complete
 */
animationHelper.makeFadeIn = function(record) {
  const element = animationHelper.getRecordElement(record);
  return animationHelper.animate(element, 'fade-in', 725);
};

/**
 * Move a record element to a new position
 * @param {Object} record - Record object
 * @param {number} newX - New X position
 * @param {number} newY - New Y position
 * @returns {Promise} - Promise that resolves when the animation is complete
 */
animationHelper.makeMove = function(record, newX, newY) {
  const element = animationHelper.getRecordElement(record);
  
  if (!element) {
    return Promise.resolve();
  }
  
  record.isAnimating = true;
  
  // Create a custom animation using Web Animations API
  const animation = element.animate([
    { transform: `translate(0, 0)` },
    { transform: `translate(${newX}px, ${newY}px)` }
  ], {
    duration: 600,
    easing: 'ease-in-out',
    fill: 'forwards'
  });
  
  return new Promise((resolve) => {
    animation.onfinish = () => {
      // Update element's position permanently after animation
      element.style.transform = `translate(${newX}px, ${newY}px)`;
      record.isAnimating = false;
      resolve();
    };
  });
};

/**
 * Create a walkabout animation (random movement)
 * @param {Object} record - Record object
 * @returns {Promise} - Promise that resolves when the animation is complete
 */
animationHelper.makeWalkabout = function(record) {
  const element = animationHelper.getRecordElement(record);
  
  if (!element) {
    return Promise.resolve();
  }
  
  record.isAnimating = true;
  
  // Random distance and direction
  const distance = getRandomInt(20, 50);
  const angle = Math.random() * Math.PI * 2;
  const xOffset = Math.cos(angle) * distance;
  const yOffset = Math.sin(angle) * distance;
  
  // Create walkabout animation
  const animation = element.animate([
    { transform: 'translate(0, 0)' },
    { transform: `translate(${xOffset}px, ${yOffset}px)` },
    { transform: 'translate(0, 0)' }
  ], {
    duration: 2000,
    easing: 'ease-in-out'
  });
  
  return new Promise((resolve) => {
    animation.onfinish = () => {
      record.isAnimating = false;
      resolve();
    };
  });
};

/**
 * Make the big image bounce
 * @returns {Promise} - Promise that resolves when the animation is complete
 */
animationHelper.bounceBigImage = function() {
  const element = document.getElementById('big-image-wrapper');
  const num = Math.floor(Math.random() * 4);
  const bounceDirection = animationHelper.bouncePicker[num]
  uiState.bigImage.isAnimating = true;
  return animationHelper.animate(element, bounceDirection, 725)
    .then(() => uiState.bigImage.isAnimating = false)
};

/**
 * Helper function to get a random integer between min and max
 * @param {number} min - Minimum value
 * @param {number} max - Maximum value
 * @returns {number} - Random integer
 */
function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * Helper function to find a record by id in the global releaseData array
 * @param {string} id - Record ID
 * @returns {Object|null} - Found record or null
 */
function findRecordById(id) {
  if (!window.releaseData) {
    return null;
  }
  
  return window.releaseData.find(record => record.id == id) || null;
}
