/**
 * New rhombus tessellation using HTML/CSS instead of fabric.js
 */
makeRhombus = function() {
  rhombus = {};
  rhombus.size = 1000;
  rhombus.defaultItems = 24;
  rhombus.closeUpIndexes = [2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14, 15, 19];
  rhombus.paging = {"small": 3, "medium": 9, "big": 24};
  rhombus.timeoutFunctions = timeoutFunctions.concat(rhombusTimeoutFunctions || []);
  rhombus.timeouts = {"slow": 625, "fast": 325};
  rhombus.type = 'rhombus'; // Add type identifier for CSS

  rhombus.prepare = function(data) {
    for (var i = 0; i < data.length; i += 3) { // Process 3 at a time
      for (var j = 0; j < 3 && i + j < data.length; j++) {
        let record = data[i + j];
        if (j === 0) {
          // Left rhombus
          record.angle = -30;
          record.rhombusType = 'left';
        } else if (j === 1) {
          // Center rhombus
          record.angle = 90;
          record.rhombusType = 'center';
        } else if (j === 2) {
          // Right rhombus
          record.angle = 30;
          record.rhombusType = 'right';
        }

        // Set close-up status
        if (rhombus.closeUpIndexes.includes(i + j)) {
          record.isCloseUp = true;
        } else {
          record.isCloseUp = false;
        }
      }
    }

    return data;
  };

  rhombus.render = function(data, previousData, paginationOffset) {
    renderHelper.render(data, rhombus, previousData, paginationOffset);
  };

  /*
   * We can make a _map_, for each pagination offset, that maps the motion per-triplet
   * e.g. {0: {x: 344, y:0}} - and then we just index into the damn map!
   * rhombus.sideLength = Math.floor((rhombus.xSize / 2) / Math.cos(Math.PI / 6)); // 192
   */
  rhombus.moveRecord = function(record, newIndex, paginationOffset) {
    var motionMap = {}
    if (paginationOffset === 3) {
      // each index is the triplet index, so we have 8 of them
      motionMap = {
        0: {x: 0, y: 0}, // fades out
        1: {x: [-333, -333, -333], y: [192, 0, 192]}, // one left, 
        2: {x: [-333, -333, -333], y: [192, 0, 192]}, 
        //
        3: {x: [500, 500, 500], y: [-98, -290, -98]}, // one and a half right and one up
        4: {x: [-333, -333, -333], y: [192, 0, 192]}, // where are these 98s and 290s coming from, argh
        //
        5: {x: [499, 499, 499], y: [-98, -290, -98]},
        6: {x: [-333, -333, -333], y: [192, 0, 192]},
        7: {x: [-333, -333, -333], y: [192, 0, 192]}
      }
    } else if (paginationOffset === -3) {
      motionMap = {
        0: {x: [333, 333, 333], y: [192, 0, 192]}, // one right
        1: {x: [333, 333, 333], y: [192, 0, 192]},
        2: {x: [-500, -500, -500], y: [482, 290, 482]}, // one and a half left and one down
        //
        3: {x: [333, 333, 333], y: [192, 0, 192]}, // one right
        4: {x: [-500, -500, -500], y: [482, 290, 482]}, // one and a half left and one down
        //
        5: {x: [333, 333, 333], y: [192, 0, 192]},
        6: {x: [333, 333, 333], y: [192, 0, 192]},
        7: {x: 0, y: 0}, // fades out
      }
    } else if (paginationOffset === 9) {
      motionMap = {
        0: {x: 0, y: 0}, // fades out
        1: {x: 0, y: 0}, // fades out
        2: {x: 0, y: 0}, // fades out
        //
        3: {x: [-166, -166, -166], y: [-98, -290, -98]}, // one-half left and one up
        4: {x: [-166, -166, -166], y: [-98, -290, -98]}, // one-half left and one up
        //
        5: {x: [666, 666, 666], y: [-388, -580, -388]}, //  two right and two up
        6: {x: [-167, -167, -167], y: [-98, -290, -98]}, // one-half left and one up
        7: {x: [-167, -167, -167], y: [-98, -290, -98]}, // one-half left and one up
      }
    } else if (paginationOffset === -9) {
      motionMap = {
        0: {x: [166, 166, 166], y: [482, 290, 482]}, // one-half right and one down
        1: {x: [166, 166, 166], y: [482, 290, 482]}, // one-half right and one down
        2: {x: [-666, -666, -666], y: [772, 580, 772]}, // two left and two down
        //
        3: {x: [166, 166, 166], y: [482, 290, 482]}, // one-half right and one down
        4: {x: [166, 166, 166], y: [482, 290, 482]}, // one-half right and one down
        //
        5: {x: 0, y: 0}, // fades out
        6: {x: 0, y: 0}, // fades out
        7: {x: 0, y: 0}, // fades out
      }
    }

    let triplet = Math.floor(record.index / 3)
    let tuplet = Math.floor(record.index % 3)
    xOffset = motionMap[triplet].x[tuplet]
    yOffset = motionMap[triplet].y[tuplet]
    if (xOffset !== 0 || yOffset !== 0) {
      const jitter = (Math.random() - 0.5) * 200
      const moveTime = this.timeouts.slow + jitter * 2
      record.imageItem.style.transition = `transform ${moveTime}ms ease-in-out`;
      record.imageItem.style.transform = `translate(${xOffset}px, ${yOffset}px)`;
      record.isAnimating = true;
    }
  }

  return rhombus;
};
