const dateStringOptions = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };

async function getPlaybacks() {
  try {
    params = getSearchParameters();
    const g = params['g'] || undefined
    let url = `${apiState.protocol}://${apiState.host}/playbacks`;
    const serverParamsString = transformToString(params);
    url = url + serverParamsString;
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include' // need this for cookies
    });

    const data = await response.json();
    const playbacks = data['playbacks']
    const counts = data['counts']
    const groups = data['groups']
    const releases = data['releases']

    const groupsList = document.getElementById("grouped-counts-list");
    groupsList.innerHTML = "";
    Object.keys(groups).forEach(groupDate => {
      const group = groups[groupDate];
      if (group.length !== 0) {
        const dateLi = document.createElement('li');
        dateLi.classList.add("stats-group-date")
        var dateString = groupDate
        // not good here
        if (g === 'month') {
          dateString = groupDate.slice(0, -3)
        } else if (g === 'year') {
          dateString = groupDate.slice(0, -6)
        }
        const dateSpan = document.createElement('span')
        dateSpan.innerText = `${dateString} -->`;
        dateLi.appendChild(dateSpan);
        groupsList.appendChild(dateLi);
      }
      const countList = document.createElement('ul');
      groupsList.appendChild(countList);
      addListViaElement(countList, countsToStrings(group, releases));

    });

    addList("all-counts-list", countsToStrings(counts, releases));
    addList("playbacks-list", playbacksToStrings(playbacks, releases));

  } catch (error) {
    alert('Playback load error: ' + error);
  }
}
getPlaybacks();


function countsToStrings(counts, releases) {
  countsStrings = []
  for (let i = 0; i < counts.length; i++) {
    const txt = {}
    const releaseId = counts[i][0];
    const numPlays = counts[i][1];
    const release = releases[releaseId]
    txt['text'] = `${release.artist} - ${release.title}: ${numPlays}`;
    txt['colors'] = release.variants.find(v => v.id == release.current_variant_id).colors;
    countsStrings.push(txt);
  }
  return countsStrings
}

function playbacksToStrings(playbacks, releases) {
  const playbackStrings = []
  for (let i = 0; i < playbacks.length; i++) {
    const txt = {}
    const playback = playbacks[i];
    const release = releases[playback.release_id]
    const date = new Date(playback.created_at)
    const dateString = date.toLocaleDateString("en-US", dateStringOptions)
    txt['text'] = `${release.artist} - ${release.title} on ${dateString}`;
    txt['colors'] = release.variants.find(v => v.id == release.current_variant_id).colors;
    playbackStrings.push(txt);
  }
  return playbackStrings;
}

function addList(listElementId, listTextStrings) { 
  const list = document.getElementById(listElementId);
  list.innerHTML = "";
  addListViaElement(list, listTextStrings);
}

function addListViaElement(listElement, listTextStrings) {
  for (let i = 0; i < listTextStrings.length; i++) {
    const li = document.createElement('li');
    const txt = document.createElement('span');

    txt.innerText = listTextStrings[i].text;
    const colorOne = listTextStrings[i].colors[0];
    const colorTwo = listTextStrings[i].colors[1];
    const gradientString = `linear-gradient(90deg, ${colorOne}, ${colorTwo})`;
    txt.style.backgroundImage = gradientString;
    txt.style.color = "transparent";
    txt.style.backgroundClip = "text";

    const colorFade = getColorFades(colorOne, colorTwo);
    const colorFadeTiming = {
      duration: Math.random() * 3000 + 5000,
      iterations: Math.floor(Math.random() * 5 + 3),
    };
    const textAnimation = txt.animate(colorFade, colorFadeTiming);

    li.appendChild(txt);
    listElement.appendChild(li);
  }
}

// This should be deterministic based on releaseId, with 4-5 options ...
function getColorFades(colorOne, colorTwo) {
  if (Math.random() > 0.5) {
    return [
      {color: colorOne},
      {color: "transparent"},
      {color: colorTwo},
      {color: "transparent"},
      {color: colorOne},
    ];
  } else {
    return [
      {color: colorTwo},
      {color: "transparent"},
      {color: colorOne},
      {color: "transparent"},
      {color: colorTwo},
    ];
  }
}
