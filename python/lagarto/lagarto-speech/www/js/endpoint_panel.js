/* Copyright (c) Daniel Berenguer (panStamp) 2012 */

/**
 * Create values
 */
function createValues()
{
  var jsonDoc = getJsonDoc();
  var swapnet = jsonDoc.lagarto;
  swapnet.status.forEach(addEndpoint);
}

/**
 * Add endpoint
 */
function addEndpoint(endpoint)
{
  var nettable = document.getElementById("nettable");
  var row, cell, label, command, val;

  row = nettable.insertRow(nettable.rows.length);

  // Link to config page
  cell = row.insertCell(0);
  cfglink = document.createElement("a");
  cfglink.setAttribute("href", "config_endpoint.html/?id=" + endpoint.id);
  cell.appendChild(cfglink);
  // Endpoint ID
  cell.className = "cellitem";
  label = document.createTextNode(endpoint.id);
  label.value = document.createTextNode(endpoint.id);
  cfglink.appendChild(label);
  // Location
  cell = row.insertCell(1);
  cell.className = "cellitem";
  label = document.createTextNode(endpoint.location);
  cell.appendChild(label);
  // Name
  cell = row.insertCell(2);
  cell.className = "cellitem";
  label = document.createTextNode(endpoint.name);
  cell.appendChild(label);
  // Value
  cell = row.insertCell(3);
  cell.className = "cellitem";
  val = document.createElement("input");
  val.type = "text";
  val.className = "inputnoedit1";
  val.readOnly = "readOnly";
  val.id = endpoint.id;
  val.value = endpoint.value
  cell.appendChild(val);
}

/**
 * Update values
 */
function updateValues()
{
  var jsonDoc = getJsonDoc();
  var swapnet = jsonDoc.lagarto;
 
  swapnet.status.forEach(function(endpoint)
  {
    valField = document.getElementById(endpoint.id);
    if (valField != null)
    {
      valField.value = endpoint.value;
    }
  });
}

