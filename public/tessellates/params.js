// All params are snake_case so that we can easily pass them to the ruby backend
// without having to worry
function getSearchParameters() {
  const prmstr = window.location.search.substr(1);
  return prmstr != null && prmstr != "" ? transformToAssocArray(prmstr) : {};
}

function transformToAssocArray(prmstr) {
  const params = {};
  const paramArray = prmstr.split("&");
  for ( var i = 0; i < paramArray.length; i++) {
    const temp = paramArray[i].split("=");
    params[temp[0]] = temp[1];
  }
  return params;
}

function transformToString(paramsObject) {
  let paramsStr = '';
  Object.entries(paramsObject).forEach(entry => {
    const [k, v] = entry;
    if (!v) {
      return;
    }
    if (paramsStr.length === 0) {
      paramsStr += `?${k}=${v}`
    } else {
      paramsStr += `&${k}=${v}`
    }
  });
  return paramsStr;
}

function parseTessellatesParams(params, tess) {
  if (!params['offset']) {
    params['offset'] = 0;
    params['min_offset'] = 0;
    params['max_offset'] = (tess.defaultItems * 2);
  } else {
    params['offset'] = parseInt(params['offset'])
    params['min_offset'] = Math.max(0, params['offset'] - tess.defaultItems);
    params['max_offset'] = params['offset'] + (tess.defaultItems * 2);
  }
  if (!params['filter']) {
    params['filter'] = "";
  }
  return params;
}
