/**
 * Octagon tessellation: rows of 4, 3, 4, 3, 4, 3, 4 octagons, with the small squares between them left blank
 */

/**
 * Position of an octagon in half-step units: rows of 4 sit on even tracks, rows of 3 on odd tracks.
 * @param {number} index - Index in the data array
 * @returns {Object} - {row: 0-6, track: 0-6}
 */
octagonPosition = function(index) {
  const pair = Math.floor(index / 7);
  const indexInPair = index % 7;
  if (indexInPair < 4) {
    return {row: pair * 2, track: indexInPair * 2};
  } else {
    return {row: pair * 2 + 1, track: (indexInPair - 4) * 2 + 1};
  }
};

makeOctagon = function() {
  octagon = {};
  octagon.size = 1000;
  octagon.halfStep = 134.88; // matches .image-grid-octagon in main.css
  octagon.defaultItems = 25;
  octagon.closeUpIndexes = [
    0, 1, 2, 3,
      4, 5, 6,
    7, 8, 9, 10,
      11, 12, 13,
    14, 15, 16, 17,
      18, 19, 20,
    21, 22, 23, 24,
  ];
  octagon.paging = {"small": 1, "medium": 7, "big": 25};
  octagon.timeoutFunctions = timeoutFunctions.concat(octagonTimeoutFunctions);
  octagon.timeouts = {"slow": 550, "fast": 250};
  octagon.type = 'octagon'; // Add type identifier for CSS

  octagon.prepare = function(data) {
    for (let i = 0; i < data.length; i++) {
      let record = data[i];
      record.angle = 0;
      record.isCloseUp = octagon.closeUpIndexes.includes(i);
    }

    return data;
  };

  octagon.render = function(data, previousData, paginationOffset) {
    renderHelper.render(data, octagon, previousData, paginationOffset);
  };

  octagon.moveRecord = function(record, newIndex, paginationOffset) {
    const currentPosition = octagonPosition(record.index);
    const newPosition = octagonPosition(newIndex);

    const xOffset = (newPosition.track - currentPosition.track) * this.halfStep;
    const yOffset = (newPosition.row - currentPosition.row) * this.halfStep;

    const jitter = (Math.random() - 0.5) * 200
    const moveTime = this.timeouts.slow + jitter
    record.imageItem.style.transition = `transform ${moveTime}ms ease-in-out`;
    record.imageItem.style.transform = `translate(${xOffset}px, ${yOffset}px)`;
    record.isAnimating = true;
  }

  return octagon;
};
