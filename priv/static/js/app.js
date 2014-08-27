$( document ).ready(function() {
  var socket         = new Phoenix.Socket("ws://" + location.host +  "/ws");

  var netwatchTxTemplateTimeCol = function(message) {
    var start_time = moment(message.start_time)
    var str = ""

    if (start_time) {
      str += "<span class='small text-muted'>" + start_time.format("MM/D/YYYY HH:mm:ss Z") + "</span><br />"
      str += "<span class='small text-muted'>" + start_time.utc().format("MM/D/YYYY HH:mm:ss Z") + "</span><br />"
    }

    if (message.rssi_in_dbm != 0) {
      var label = "text-muted"
      if (message.rssi_in_dbm < -85 && message.rssi_in_dbm >= -95) {label = "label label-info"}
      if (message.rssi_in_dbm < -95 && message.rssi_in_dbm >= -105) {label = "label label-warning"}
      if (message.rssi_in_dbm < -105) {label = "label label-danger"}

      str += "<span class='small " + label + "'>RSSI (dBm) : " + message.rssi_in_dbm + "</span><br />"
    } else {
      str += "<span class='small label label-default'>RSSI (dBm) : n/a</span><br />"
    }

    if (message.loss_percentage >= 0) {
      var label = "text-muted"
      if (message.loss_percentage > 1) {label = "label label-warning"}
      if (message.loss_percentage > 5) {label = "label label-danger"}
      str += "<span class='small " + label + "'>Packet Loss (%) : " + message.loss_percentage + "</span><br />"
    }

    if (!message.radio_callsign){
      str += "<span class='small label label-warning'>No Radio Callsign</span><br />"
    }

    if (!message.radio_location && !message.radio_formatted_address){
      str += "<span class='small label label-warning'>No Radio Location</span><br />"
    }

    if (message.dmr_marc_radio_callsign){
      str += "<span class='small label label-success'>DMR-MARC Radio DB</span><br />"
    } else {
      str += "<span class='small label label-danger'>DMR-MARC Radio DB</span><br />"
    }

    return str
  }

  var netwatchTxTemplateUserCol = function(message) {
    var str = ""

    if (message.dmr_marc_radio_callsign && message.dmr_marc_radio_name){
      str += "<a href='http://callook.info/" + message.dmr_marc_radio_callsign + "' target=_blank>" + message.dmr_marc_radio_callsign + "</a>&nbsp;&mdash;&nbsp;<span class='text-muted'>" + message.dmr_marc_radio_name + "</span><br />"
    } else if (message.radio_callsign && message.radio_name){
      str += "<a href='http://callook.info/" + message.radio_callsign + "' target=_blank>" + message.radio_callsign + "</a>&nbsp;&mdash;&nbsp;<span class='text-muted'>" + message.radio_name + "</span><br />"
    } else if (message.radio_callsign && !message.radio_name){
      str += "<a href='http://callook.info/" + message.radio_callsign + "' target=_blank>" + message.radio_callsign + "</a><br />"
    }

    str += "<span class='small text-muted'>"

    if (message.radio_id){
      str += message.radio_id + "<br />"
    }

    if (message.radio_formatted_address){
      str += message.radio_formatted_address + "<br />"
    } else if (message.radio_location) {
      str += message.radio_location
    }

    if (message.dmr_marc_radio_home_repeater){
      str += "Home Repeater: " + message.dmr_marc_radio_home_repeater + "<br />"
    }

    if (message.dmr_marc_radio_remarks){
      str += "Remarks: " + message.dmr_marc_radio_remarks
    }

    str += "</span>"

    return str
  }

  var netwatchTxTemplatePeerCol = function(message) {
    var str = ""
    if (message.peer_callsign){
      str += "<a href='http://callook.info/" + message.peer_callsign + "' target=_blank>" + message.peer_callsign + "</a><br />"
    }

    str += "<span class='small text-muted'>"

    if (message.peer_id){
      str += message.peer_id + "<br />"
    }

    if (message.peer_formatted_address){
     str += message.peer_formatted_address
    }

    if (message.peer_location && !message.peer_formatted_address){
      str += message.peer_location
    }

    str += "</span>"

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
      addGoogleMapMarker(message.peer_latitude, message.peer_longitude, 'peer', markertitle);
    }

    if (message.radio_latitude && message.radio_longitude) {
      if (message.dmr_marc_radio_callsign && message.dmr_marc_radio_name) {
        var markertitle = message.dmr_marc_radio_callsign + " : " + message.dmr_marc_radio_name
      } else if (message.radio_callsign && message.radio_name) {
        var markertitle = message.radio_callsign + " : " + message.radio_name
      } else if (message.radio_callsign) {
        var markertitle = message.radio_callsign
      } else {
        var markertitle = message.radio_id
      }

      addGoogleMapMarker(message.radio_latitude, message.radio_longitude, 'radio', markertitle);
    }

    return(msgContainer);
  }

  function addGoogleMapMarker(lat, lng, type, title){
    var loc = new google.maps.LatLng(lat, lng);
    if (type == 'peer') {
      var icon = '/static/images/radio-station-2.png'
    } else if (type == 'radio') {
      var icon = '/static/images/male-2.png'
    }
    addMarker(loc, title, icon);
  }

  // WEBSOCKETS
  socket.join("dmrwatch", "server", {}, function(chan){

    chan.on("join", function(message){
      // console.log(message)
      $("#server-status").text("Connected. Waiting for DMR transmissions.");
      $("#server-status").fadeIn();
    });

    chan.on("tx:in_progress", function(message){
      console.log(message)
      $("#tx-in-progress-placeholder").fadeOut()
      $("#tx-in-progress").prepend(netwatchTxTemplate(message));
    });

    chan.on("tx:history", function(message){
      console.log(message)
    });

    chan.on("time:utc_time", function(message){
      var server_utc_time = moment(message)
      //console.log(message)
      $("#server-time").text(server_utc_time.format("MM/D/YYYY HH:mm:ss Z"));
    });

    chan.on("status:message", function(message){
      //console.log(message)
      if (message) {
        $("#server-status").text(message);
        $("#server-status").fadeIn();
      } else {
        $("#server-status").text("");
        $("#server-status").fadeOut();
      }
    });

  });

});
