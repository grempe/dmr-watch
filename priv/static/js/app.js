$( document ).ready(function() {
  var socket         = new Phoenix.Socket("ws://" + location.host +  "/ws");
  var $cnxn_status   = $("#cnxn-status");
  var $transmissions = $("#transmissions");

  var netwatchTxTemplateTimeCol = function(message) {
    var start_time = moment(message.start_time);
    return "<span class='small text-muted'>" + start_time.format("MM/D/YYYY HH:mm:ss Z") + "</span><br />"
         + "<span class='small text-muted'>" + start_time.utc().format("MM/D/YYYY HH:mm:ss Z") + "</span><br />"
         + "<span class='small text-muted'>RSSI (dBm) : " + message.rssi_in_dbm + "</span><br />"
         + "<span class='small text-muted'>Packet Loss (%) : " + message.loss_percentage + "</span>"
  }

  var netwatchTxTemplateUserCol = function(message) {
    return "<strong class='h4 text-primary'>" + (message.radio_callsign || "Unknown") + "</strong>&nbsp;&mdash;&nbsp;<strong class='h4 text-muted'>" + (message.radio_name || "Unknown") + "</strong><br />"
           + message.radio_id + "<br />"
           + (message.radio_formatted_address || message.radio_location)
  }

  var netwatchTxTemplatePeerCol = function(message) {
    return (message.peer_callsign || "Unknown") + "<br />"
           + message.peer_id + "<br />"
           + (message.peer_formatted_address || message.peer_location)
    }

  var netwatchTxTemplateNetCol = function(message) {
    return (message.bridge_group_name || "Unknown") + "<br />"
           + (message.site_name || "Unknown")
  }

  var netwatchTxTemplate = function(message){
    var msgContainer    = $("<div class='msg-container row'>"
                            + "<span class='col-xs-2'>" + netwatchTxTemplateTimeCol(message) + "</span>"
                            + "<span class='col-xs-3'>" + netwatchTxTemplateUserCol(message) + "</span>"
                            + "<span class='col-xs-1'><span class='glyphicon glyphicon-arrow-right'></span></span>"
                            + "<span class='col-xs-3'>" + netwatchTxTemplatePeerCol(message) + "</span>"
                            + "<span class='col-xs-1'><span class='glyphicon glyphicon-arrow-right'></span></span>"
                            + "<span class='col-xs-2'>" + netwatchTxTemplateNetCol(message) + "</span>"
                            + "</div>"
                            )

    if (message.peer_latitude && message.peer_longitude) {
      var markertitle = message.peer_callsign || message.peer_id
      addGoogleMapPeerMarker(message.peer_latitude , message.peer_longitude, markertitle);
    }

    if (message.radio_latitude && message.radio_longitude) {
      var markertitle = message.radio_callsign || message.radio_id
      addGoogleMapRadioMarker(message.radio_latitude , message.radio_longitude, markertitle);
    }

    return(msgContainer);
  }

  function addGoogleMapPeerMarker(lat, lng, title){
    var loc = new google.maps.LatLng(lat , lng);
    var icon = '/static/images/radio-station-2.png'
    addMarker(loc, title, icon);
  }

  function addGoogleMapRadioMarker(lat, lng, title){
    var loc = new google.maps.LatLng(lat , lng);
    var icon = '/static/images/male-2.png'
    addMarker(loc, title, icon);
  }

  // WEBSOCKETS
  socket.join("netwatch", "transmit", {}, function(chan){

    chan.on("join", function(message){
      $cnxn_status.html('<span class="label label-success">connected</span>');
      $("#tx-placeholder").html("<p>Connected. Waiting for DMR transmissions.</p>");
    });

    chan.on("tx:in_progress", function(message){
      var parsed = $.parseJSON(message);
      console.log(parsed);
      $("#tx-placeholder").remove()
      $transmissions.prepend(netwatchTxTemplate(parsed));
    });

  });
});
