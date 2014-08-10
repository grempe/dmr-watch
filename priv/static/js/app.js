$(function(){
  var socket     = new Phoenix.Socket("ws://" + location.host +  "/ws");
  var $transmissions  = $("#transmissions");
  var sanitize   = function(html){ return $("<div/>").text(html).html(); }

  var netwatchTxTemplate = function(message){
    // var radio_callsign = sanitize(message.radio_callsign || "unknown");
    // var peer_callsign  = sanitize(message.peer_callsign);

    return("<ul class='netwatch_tx'>"
             + "<li class='start_time'>"          + message.start_time + "</li>"

             + "<li class='bridge_group_name'>"   + message.bridge_group_name + "</li>"
             + "<li class='duration_in_seconds'>" + message.duration_in_seconds + "</li>"
             + "<li class='loss_percentage'>"     + message.loss_percentage + "</li>"

             + "<li class='peer_alias'>"          + message.peer_alias + "</li>"
             + "<li class='peer_callsign'>"       + message.peer_callsign + "</li>"
             + "<li class='peer_id'>"             + message.peer_id + "</li>"
             + "<li class='peer_location'>"       + message.peer_location + "</li>"

             + "<li class='radio_alias'>"         + message.radio_alias + "</li>"
             + "<li class='radio_callsign'>"      + message.radio_callsign + "</li>"
             + "<li class='radio_id'>"            + message.radio_id + "</li>"
             + "<li class='radio_location'>"      + message.radio_location + "</li>"
             + "<li class='radio_name'>"          + message.radio_name + "</li>"
             + "<li class='rssi_in_dbm'>"         + message.rssi_in_dbm + "</li>"

             + "<li class='site_name'>"           + message.site_name + "</li>"
           + "</ul>");
  }

  socket.join("netwatch", "transmit", {}, function(chan){

    chan.on("join", function(message){
      $transmissions.text("joined netwatch:transmit");
    });

    chan.on("tx:in_progress", function(message){
      var parsed = $.parseJSON(message);
      $transmissions.prepend(netwatchTxTemplate(parsed));
    });

  });
});
