/**
 * New circle tessellation using HTML/CSS instead of fabric.js
 */
makeCircle = function() {
  circle = {};
  circle.size = 1000;
  circle.defaultItems = 12;
  circle.closeUpIndexes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  circle.paging = {"small": 1, "medium": 6, "big": 12};
  circle.timeoutFunctions = timeoutFunctions.concat(circleTimeoutFunctions);
  circle.timeouts = {"slow": 600, "fast": 275};
  circle.type = 'circle'; // Add type identifier for CSS

  circle.prepare = function(data) {
    const rootStyles = getComputedStyle(document.documentElement);
    const magicOffset = rootStyles.getPropertyValue('--circle-magic-offset');
    if (!magicOffset) {
      let offset = Math.floor(Math.random() * 12);
      window.CSS.registerProperty({
        name: "--circle-magic-offset",
        inherits: false,
        initialValue: `${offset}`,
      });
    }

    for (let i = 0; i < data.length; i++) {
      let record = data[i];
      record.index = i;
      record.angle = 0;
      record.isCloseUp = true;
    }

    return data;
  }

  circle.render = function(data, previousData, paginationOffset) {
    renderHelper.render(data, circle, previousData, paginationOffset);
  }

  circle.moveRecord = function(record, newIndex, paginationOffset) {
    const jitter = (Math.random() - 0.5) * 200
    const moveTime = this.timeouts.slow + jitter
    record.imageItem.style.transition = `transform ${moveTime}ms ease-in-out`;
    record.imageItem.className = record.imageItem.className.replace(/circle-item-\d+/, `circle-item-${newIndex % 12}`);
    record.isAnimating = true;
  }

  return circle;
}
