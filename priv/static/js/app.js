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

    if (!message.radio_callsign && !message.dmr_marc_radio_callsign){
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
    return(msgContainer);
  }

  function addGoogleMapMarker(lat, lng, type, title, radius, linkedLat, linkedLng){
    var location = new google.maps.LatLng(lat, lng);

    if (linkedLat && linkedLng) {
      var linkedLocation = new google.maps.LatLng(linkedLat, linkedLng);
    } else {
      var linkedLocation = null;
    }

    if (type == 'peer') {
      var icon = '/static/images/radio-station-2.png'
    } else if (type == 'radio') {
      var icon = '/static/images/male-2.png'
    } else if (type == 'observer') {
      var icon = '/static/images/downloadicon.png'
    }
    addMarker(location, title, icon, radius, linkedLocation);
  }

  function getGeoLocation() {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(geoSuccess, geoError, {maximumAge: 600000});
    } else {
      window.myGeoError = "GEOLOCATION_NOT_SUPPORTED";
      console.log("Geolocation is not supported by this browser.");
    }
  }

  function geoSuccess(position) {
    console.log("geoSuccess : latlong: " + position.coords.latitude + ", " + position.coords.longitude);
    window.myGeoError = null;
    window.myLatitude = position.coords.latitude;
    window.myLongitude = position.coords.longitude;
    addGoogleMapMarker(position.coords.latitude, position.coords.longitude, "observer", "Me.", 0, null, null);
  }

  function geoError(error) {
    window.myLatitude = null;
    window.myLongitude = null;

    switch(error.code) {
      case error.PERMISSION_DENIED:
        window.myGeoError = "PERMISSION_DENIED";
        console.log("geoError : User denied the request for Geolocation.")
        break;
      case error.POSITION_UNAVAILABLE:
        window.myGeoError = "POSITION_UNAVAILABLE";
        console.log("geoError : Location information is unavailable.")
        break;
      case error.TIMEOUT:
        window.myGeoError = "TIMEOUT";
        console.log("geoError : The request to get user location timed out.")
        break;
      case error.UNKNOWN_ERROR:
        window.myGeoError = "UNKNOWN_ERROR";
        console.log("geoError : An unknown error occurred.")
        break;
    }
  }

  function placeGeoMarkers(message) {
    if (message.radio_latitude && message.radio_longitude) {
      if (message.dmr_marc_radio_callsign && message.dmr_marc_radio_name) {
        var radioMarkerTitle = message.dmr_marc_radio_callsign + " : " + message.dmr_marc_radio_name
      } else if (message.radio_callsign && message.radio_name) {
        var radioMarkerTitle = message.radio_callsign + " : " + message.radio_name
      } else if (message.radio_callsign) {
        var radioMarkerTitle = message.radio_callsign
      } else {
        var radioMarkerTitle = message.radio_id
      }

      addGoogleMapMarker(message.radio_latitude, message.radio_longitude, 'radio', radioMarkerTitle, 10000, null, null);
    }

    if (message.peer_latitude && message.peer_longitude) {
      var peerMarkerTitle = message.peer_callsign || message.peer_id
      addGoogleMapMarker(message.peer_latitude, message.peer_longitude, 'peer', peerMarkerTitle, 75000, message.radio_latitude, message.radio_longitude);
    }
  }

  // WEBSOCKETS
  socket.join("dmrwatch", "server", {}, function(chan){

    chan.on("join", function(message){
      // console.log(message)
      getGeoLocation();
      $("#server-status").text("Connected. Waiting for DMR transmissions.");
      $("#server-status").fadeIn();
    });

    chan.on("tx:in_progress", function(message){
      console.log(message);
      placeGeoMarkers(message);
      $("#tx-in-progress-placeholder").fadeOut();
      $("#tx-in-progress").prepend(netwatchTxTemplate(message));
    });

    chan.on("tx:history", function(message){
      console.log(message);
      placeGeoMarkers(message);
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

    // geo location points sent by other clients
    // map these on our local map.
    chan.on("geo:location", function(message){
      console.log(message)
      if (message.latitude && message.longitude && message.latitude != window.myLatitude && message.longitude != window.myLongitude) {
      addGoogleMapMarker(message.latitude, message.longitude, "observer", "Web Observer", 0);
      }
    });

    // geo location request from the server
    // sends back geo:location:response which will be re-broadcast.
    chan.on("geo:location:request", function(message){
      console.log(message)
      if (window.myGeoError && window.myGeoError != null) {
        chan.send("geo:location:response:error", {"error": window.myGeoError});
      } else if (window.myLatitude && window.myLongitude) {
        chan.send("geo:location:response", {"latitude": window.myLatitude, "longitude": window.myLongitude});
      }
    });

  });

});
