let vlcHelper = {}

vlcHelper._headers = new Headers();
vlcHelper._headers.set('Authorization', 'Basic ' + btoa("" + ":" + "wombat"));
vlcHelper._apiUrl = "http://127.0.0.1:8089/requests/status.xml";

vlcHelper.makePlayFunc = function(record) {
  // "dependecy injection"
  if (vlcHelper._filePrefix === undefined) {
    vlcHelper._filePrefix = apiState.filePathPrefix
  }

  if (uiState.localPlayback === true) {
    return function() {
      return vlcHelper._checkState()
        .then(vlcState => vlcHelper._addTracks(record.tracks, vlcState));
    }
  }
}

vlcHelper.pause = function() {
  const vlcCommand = "pl_pause";
  vlcHelper._runMetaCommand(vlcCommand);
}

vlcHelper.clearAllTracks = function() {
  const vlcCommand = "pl_empty";
  vlcHelper._runMetaCommand(vlcCommand);
}

vlcHelper._addTracks = function(tracks, vlcState) {
  for (let i = 0; i < tracks.length; i++) {
    let vlcCommand = "in_enqueue"
    const fileSuffix = encodeURIComponent(tracks[i].media_link);
    if (i === 0 && vlcState === "stopped") {
        vlcCommand = "in_play"
      }
    vlcHelper._addTrack(vlcCommand, vlcHelper._filePrefix, fileSuffix);
  }
}

vlcHelper._addTrack = function(command, prefix, suffix) {
  const vlcUrl = `${vlcHelper._apiUrl}?command=${command}&input=${prefix}${suffix}`;
  return fetch(vlcUrl, {headers: vlcHelper._headers})
    .then(response => response.text());
}

vlcHelper._runMetaCommand = function(command) {
  const vlcUrl = `${vlcHelper._apiUrl}?command=${command}`;
  return fetch(vlcUrl, {headers: vlcHelper._headers})
    .then(response => response.text());
}

vlcHelper._checkState = function() {
  const vlcStateUrl = `${vlcHelper._apiUrl}`;
  return fetch(vlcStateUrl, {headers: vlcHelper._headers})
    .then(response => response.text())
    .then(text => {
      const parser = new DOMParser();
      const xmlResponse = parser.parseFromString(text, "application/xml");
      const vlcState = xmlResponse.children[0].children[11].textContent
      return vlcState;
    })
}
