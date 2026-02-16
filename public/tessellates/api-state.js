// Set up API state
var apiState = {
  host: null,
  protocol: null,
  collectionName: null,
  filePathPrefix: null
}

// Leaving this unideal thing in, as a reminder for when I am hacking locally
if (window.location.href.includes("localhost") || window.location.href.includes("127.0.0.1")) {
  apiState.host = "127.0.0.1:3000"
  apiState.protocol = "http"
  // apiState.host = "collects.tide-pool.ca"
  // apiState.protocol = "https"
} else {
  apiState.host = "tessellates.space";
  apiState.protocol = "https";
}
