/* Copyright (c) Daniel Berenguer (panStamp) 2012 */

var statement, statementType = "action";
var endpointTypes = {};

/**
 * Update values
 */
function updateValues()
{
  statement = window.parent.statement;

  var jsonDoc = getJsonDoc();
  var servers = jsonDoc.http_servers;
  fillServers(servers);
}

/**
 * Fill server list
 */
function fillServers(servers)
{
  var dot = statement[1].indexOf(".");
  var currVal = statement[1].substring(0, dot);
  var currValFound = false;
  var fldServer = document.getElementById("server");
  fldServer.options.length = 0;
  for(var server in servers)
  {
    if (server == currVal)
      currValFound = true;

    fldServer.options[fldServer.options.length] = new Option(server, servers[server]);
  }
  if (!currValFound)
    fldServer.options[fldServer.options.length] = new Option(currVal, "");

  document.getElementById("server").value = currVal;

  onchangeServer();
}

/**
 * Fill endpoints in item1
 */
function fillEndpoints()
{
  var dot = statement[1].indexOf(".");
  var currVal = statement[1].substring(dot+1);
  var currValFound = false;
  var fldEndp = document.getElementById("endp");
  var jsonDoc = getJsonDoc();
  var swapnet = jsonDoc.lagarto;

  fldEndp.options.length = 0;

  endpointTypes = {};
  swapnet.status.forEach(function(endpoint)
  {
    var endp = endpoint.location + "." + endpoint.name;
    if (endp == currVal)
      currValFound = true;
    fldEndp.options[fldEndp.options.length] = new Option(endp, endp);
    
    endpointTypes[endp] = endpoint.type;
  });

  if (!currValFound)
  {
    fldEndp.options[fldEndp.options.length] = new Option(currVal, "");
    endpointTypes[currVal] = "num";
  }

  fldEndp.value = currVal;

  onchangeEndp();
}

/**
 * Lagarto server selected
 */
function onchangeServer()
{
  var server = document.getElementById("server").value;
  if (server != "")
    loadJSONdata("/command/get_endpoint_list/?server=" + server, fillEndpoints);
  else
  {
    var dot = statement[1].indexOf(".");
    var currVal = statement[1].substring(dot+1);
    var fldEndp = document.getElementById("endp");
    fldEndp.options.length = 0;
    fldEndp.options[fldEndp.options.length] = new Option(currVal, "");
    endpointTypes[currVal] = "num";
    onchangeEndp();
  }
}

/**
 * Endpoint selected
 */
function onchangeEndp()
{
  var endpType = getEndpointType();

  if (endpType == "bin")
	  document.getElementById("item2box").src = "../edit_item2_state.html";
  else
    document.getElementById("item2box").src = "../edit_item2_val.html";
}

/**
 * Return python representation of the network action
 */
function getAction()
{
  var i = document.getElementById("server").selectedIndex;
  if (i == -1)
    return null;
  var server = document.getElementById("server").options[i].text;

  var item1 = "\"" + server + "." + document.getElementById("endp").value + "\"";
  var pythonString = "network.set_value(" +  item1 + ", ";
  var item2box = document.getElementById("item2box").contentWindow;
  var item2 = item2box.getItem2();
  if (item2 == null)
    return null;
  pythonString += item2 + ")";

  return pythonString;
}

/**
 * Return list of servers
 */
function getServers()
{
  var server = document.getElementById("server");

  return server.options;
}

/**
 * Return type of the endpoint currently selected
 */
function getEndpointType()
{
  return endpointTypes[document.getElementById("endp").value];
}

