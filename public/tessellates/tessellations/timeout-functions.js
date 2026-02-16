/**
 * Timeout functions for tessellation animations
 * These determine the order and timing of animations
 */

// Base timeout functions shared by all tessellations
var timeoutFunctions = [
  [
    // Forward function
    function(index, total, maxMs) {
      return (index / total) * maxMs;
    },
    // Reverse function
    function(index, total, maxMs) {
      return ((total - index) / total) * maxMs;
    }
  ],
  [
    // Function for diagonal animation (top-left to bottom-right)
    function(index, total, maxMs) {
      const row = Math.floor(index / Math.sqrt(total));
      const col = index % Math.sqrt(total);
      return ((row + col) / (2 * Math.sqrt(total))) * maxMs;
    },
    // Reverse function (bottom-right to top-left)
    function(index, total, maxMs) {
      const row = Math.floor(index / Math.sqrt(total));
      const col = index % Math.sqrt(total);
      return ((2 * Math.sqrt(total) - row - col) / (2 * Math.sqrt(total))) * maxMs;
    }
  ],
  [
    // Function for spiral animation (outside to inside)
    function(index, total, maxMs) {
      const distance = Math.abs(index - total / 2);
      return (distance / (total / 2)) * maxMs;
    },
    // Reverse function (inside to outside)
    function(index, total, maxMs) {
      const distance = Math.abs(index - total / 2);
      return ((total / 2) - distance) / (total / 2) * maxMs;
    }
  ]
];

// Square-specific timeout functions
var squareTimeoutFunctions = [
  [
    // Checkerboard pattern
    function(index, total, maxMs) {
      const row = Math.floor(index / Math.sqrt(total));
      const col = index % Math.sqrt(total);
      return ((row + col) % 2 === 0 ? 0 : 1) * maxMs / 2;
    },
    // Inverse checkerboard pattern
    function(index, total, maxMs) {
      const row = Math.floor(index / Math.sqrt(total));
      const col = index % Math.sqrt(total);
      return ((row + col) % 2 === 1 ? 0 : 1) * maxMs / 2;
    }
  ]
];

// Triangle-specific timeout functions
var triangleTimeoutFunctions = [
  [
    // Triangle pattern top to bottom
    function(index, total, maxMs) {
      const row = Math.floor(index / Math.sqrt(total));
      return (row / Math.sqrt(total)) * maxMs;
    },
    // Triangle pattern bottom to top
    function(index, total, maxMs) {
      const row = Math.floor(index / Math.sqrt(total));
      return ((Math.sqrt(total) - row) / Math.sqrt(total)) * maxMs;
    }
  ]
];

// Circle-specific timeout functions
var circleTimeoutFunctions = [
  [
    // Radial pattern outside to inside
    function(index, total, maxMs) {
      const center = Math.floor(total / 2);
      const row = Math.floor(index / Math.sqrt(total));
      const col = index % Math.sqrt(total);
      const centerRow = Math.floor(Math.sqrt(total) / 2);
      const centerCol = Math.floor(Math.sqrt(total) / 2);
      const distance = Math.sqrt(Math.pow(row - centerRow, 2) + Math.pow(col - centerCol, 2));
      const maxDistance = Math.sqrt(Math.pow(centerRow, 2) + Math.pow(centerCol, 2));
      return (distance / maxDistance) * maxMs;
    },
    // Radial pattern inside to outside
    function(index, total, maxMs) {
      const center = Math.floor(total / 2);
      const row = Math.floor(index / Math.sqrt(total));
      const col = index % Math.sqrt(total);
      const centerRow = Math.floor(Math.sqrt(total) / 2);
      const centerCol = Math.floor(Math.sqrt(total) / 2);
      const distance = Math.sqrt(Math.pow(row - centerRow, 2) + Math.pow(col - centerCol, 2));
      const maxDistance = Math.sqrt(Math.pow(centerRow, 2) + Math.pow(centerCol, 2));
      return ((maxDistance - distance) / maxDistance) * maxMs;
    }
  ]
];

// Rhombus-specific timeout functions
var rhombusTimeoutFunctions = [
  [
    // Diamond pattern outside to inside
    function(index, total, maxMs) {
      const row = Math.floor(index / Math.sqrt(total));
      const col = index % Math.sqrt(total);
      const centerRow = Math.floor(Math.sqrt(total) / 2);
      const centerCol = Math.floor(Math.sqrt(total) / 2);
      const distance = Math.abs(row - centerRow) + Math.abs(col - centerCol);
      const maxDistance = centerRow + centerCol;
      return (distance / maxDistance) * maxMs;
    },
    // Diamond pattern inside to outside
    function(index, total, maxMs) {
      const row = Math.floor(index / Math.sqrt(total));
      const col = index % Math.sqrt(total);
      const centerRow = Math.floor(Math.sqrt(total) / 2);
      const centerCol = Math.floor(Math.sqrt(total) / 2);
      const distance = Math.abs(row - centerRow) + Math.abs(col - centerCol);
      const maxDistance = centerRow + centerCol;
      return ((maxDistance - distance) / maxDistance) * maxMs;
    }
  ]
];