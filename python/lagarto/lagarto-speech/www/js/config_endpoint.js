/* Copyright (c) Daniel Berenguer (panStamp) 2012 */

/**
 * Update table fields
 */
function updateValues()
{
  var endpoint_id = getUrlVars()["id"];

  var jsonDoc = getJsonDoc();
  var speechnet = jsonDoc.network;

  speechnet.forEach(function(endpoint)
  {
    if (endpoint.id == endpoint_id)
    {
      document.getElementById("location").value = endpoint.location;
      document.getElementById("name").value = endpoint.name;
      document.getElementById("id").value = endpoint.id;

      return;
    }
  });
}

