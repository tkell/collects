/**
 * New triangle tessellation using HTML/CSS instead of fabric.js
 */
makeTriangle = function() {
  triangle = {};
  triangle.xSize = 200;
  triangle.ySize = 200;
  triangle.xMoveOffset = triangle.xSize / 2;
  triangle.yMoveOffset = triangle.ySize;
  triangle.size = 1000;
  triangle.defaultItems = 45;
  triangle.closeUpIndexes = [
    10, 11, 12, 13, 14, 15, 16,
    19, 20, 21, 22, 23, 24, 25,
    28, 29, 30, 31, 32, 33, 34,
  ];
  triangle.paging = {"small": 1, "medium": 9, "big": 45};
  triangle.timeoutFunctions = timeoutFunctions.concat(triangleTimeoutFunctions || []);
  triangle.timeouts = {"slow": 500, "fast": 225};
  triangle.type = 'triangle'; // Add type identifier for CSS

  triangle.prepare = function(data) {
    var angle = 0;
    for (let i = 0; i < data.length; i++) {
      let record = data[i];
      record.angle = angle;
      if (angle === 0) {
        angle = 180;
      } else if (angle === 180) {
        angle = 0;
      }
      
      // Set close-up status
      if (triangle.closeUpIndexes.includes(i)) {
        record.isCloseUp = true;
      } else {
        record.isCloseUp = false;
      }
      // reset angle when going to next row
      if (i % 9 === 8) {
        angle = 0;
      }
    }

    return data;
  };

  triangle.render = function(data, previousData, paginationOffset) {
    renderHelper.render(data, triangle, previousData, paginationOffset);
  };

  triangle.moveRecord = function(record, newIndex, paginationOffset) {
    const columns = 9; // Triangle tessellation uses 9 columns
    const itemSizeX = 200;
    const itemSizeY = 200;

    // Calculate current and new positions in the grid
    const currentIndex = record.index;
    const newRow = Math.floor(newIndex / columns);
    const newCol = newIndex % columns;
    const currentRow = Math.floor(currentIndex / columns);
    const currentCol = currentIndex % columns;

    // Calculate pixel offsets based on grid cell size
    let xOffset = (newCol - currentCol) * itemSizeX;
    let yOffset = (newRow - currentRow) * itemSizeY;

    // handle progressive margin offsets
    const currentMargin = -(currentCol * 100); // Current CSS margin offset
    const newMargin = -(newCol * 100); // New CSS margin offset
    const marginDelta = newMargin - currentMargin; // Difference in margin
    xOffset += marginDelta; // Add margin difference to our transform

    // flips!
    if ( yOffset === 0 && record.angle === 180) {
      record.imageItem.className = record.imageItem.className.replace("shape-triangle", "shape-triangle-inverted");
    } else if ( yOffset === 0 && record.angle === 0) {
      record.imageItem.className = record.imageItem.className.replace("shape-triangle-inverted", "shape-triangle");
    }

    const jitter = (Math.random() - 0.5) * 200
    const moveTime = this.timeouts.slow + jitter * 2
    const clipPathTime = this.timeouts.slow + jitter * 4
    record.imageItem.style.transform = `translate(${xOffset}px, ${yOffset}px)`;
    record.imageItem.style.transition = `transform ${moveTime}ms ease-in-out, clip-path ${clipPathTime}ms ease-in-out`;
    record.isAnimating = true;
  }


  return triangle;
};
