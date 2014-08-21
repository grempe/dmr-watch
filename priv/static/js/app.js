$( document ).ready(function() {
  var socket         = new Phoenix.Socket("ws://" + location.host +  "/ws");
  var $cnxn_status   = $("#cnxn-status");
  var $transmissions = $("#transmissions");

  var netwatchTxTemplateTimeCol = function(message) {
    var start_time = moment(message.start_time)
    var str = ""

    if (start_time) {
      str += "<span class='small text-muted'>" + start_time.format("MM/D/YYYY HH:mm:ss Z") + "</span><br />"
      str += "<span class='small text-muted'>" + start_time.utc().format("MM/D/YYYY HH:mm:ss Z") + "</span><br />"
    }

    if (message.rssi_in_dbm != 0) {
      if (message.rssi_in_dbm < -85) {var label = "label label-info"} else {var label = "text-muted"}
      if (message.rssi_in_dbm < -90) {var label = "label label-warning"} else {var label = "text-muted"}
      if (message.rssi_in_dbm < -95) {var label = "label label-danger"} else {var label = "text-muted"}

      str += "<span class='small " + label + "'>RSSI (dBm) : " + message.rssi_in_dbm + "</span><br />"
    } else {
      str += "<span class='small label label-default'>RSSI (dBm) : n/a</span><br />"
    }

    if (message.loss_percentage >= 0) {
      if (message.loss_percentage > 1) {var label = "label label-warning"} else {var label = "text-muted"}
      if (message.loss_percentage > 5) {var label = "label label-danger"} else {var label = "text-muted"}
      str += "<span class='small " + label + "'>Packet Loss (%) : " + message.loss_percentage + "</span>"
    }

    return str
  }

  var netwatchTxTemplateUserCol = function(message) {
    var str = ""
    if (message.radio_callsign && message.radio_name){
      str += "<strong class='h5 text-primary'>" + message.radio_callsign + "</strong>&nbsp;&mdash;&nbsp;<strong class='h5 text-muted'>" + message.radio_name + "</strong><br />"
    }

    if (message.radio_callsign && !message.radio_name){
      str += "<strong class='h5 text-primary'>" + message.radio_callsign + "</strong><br />"
    }

    if (message.radio_id){
      str += message.radio_id + "<br />"
    }

    if (message.radio_formatted_address){
      str += message.radio_formatted_address
    }

    if (message.radio_location && !message.radio_formatted_address){
      str += message.radio_location
    }

    return str
  }

  var netwatchTxTemplatePeerCol = function(message) {
    var str = ""
    if (message.peer_callsign){
      str += message.peer_callsign + "<br />"
    }

    if (message.peer_id){
      str += message.peer_id + "<br />"
    }

    if (message.peer_id){
     str += (message.peer_formatted_address || message.peer_location)
    }

    return str
  }

  var netwatchTxTemplateNetCol = function(message) {
    var str = ""
    if (message.bridge_group_name) {
      str += message.bridge_group_name + "<br />"
    }

    if (message.site_name) {
      str += message.site_name
    }

    return str
  }

  var netwatchTxTemplate = function(message){
    var msgContainer  = $("<div class='msg-container row'>"
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
      if (message.radio_callsign && message.radio_name) {
        var markertitle = message.radio_callsign + " : " + message.radio_name
      } else if (message.radio_callsign) {
        var markertitle = message.radio_callsign
      } else {
        var markertitle = message.radio_id
      }

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
