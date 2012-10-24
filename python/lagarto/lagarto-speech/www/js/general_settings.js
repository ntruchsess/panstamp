/* Copyright (c) Daniel Berenguer (panStamp) 2012 */

/**
 * Update table fields
 */
function updateValues()
{
  var xmlDoc = getXmlDoc();
  var settings = xmlDoc.getElementsByTagName("settings")[0];

  if (settings != null)
  {
    var opt;

    var recordcmd = settings.getElementsByTagName("recordcmd")[0];
    if (recordcmd != null)
      document.getElementById("recordcmd").value = recordcmd.childNodes[0].nodeValue;

    var playcmd = settings.getElementsByTagName("playcmd")[0];
    if (playcmd != null)
      document.getElementById("playcmd").value = playcmd.childNodes[0].nodeValue;

    var language = settings.getElementsByTagName("language")[0];
    if (language != null)
      document.getElementById("language").value = language.childNodes[0].nodeValue;

    var welcomemsg = settings.getElementsByTagName("welcomemsg")[0];
    if (welcomemsg != null)
      document.getElementById("welcomemsg").value = welcomemsg.childNodes[0].nodeValue;

    var keyword = settings.getElementsByTagName("keyword")[0];
    if (keyword != null)
      document.getElementById("keyword").value = keyword.childNodes[0].nodeValue;

    var reply = settings.getElementsByTagName("reply")[0];
    if (reply != null)
      document.getElementById("reply").value = reply.childNodes[0].nodeValue;
  }
}

