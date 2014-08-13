$( document ).ready(function() {
  var socket         = new Phoenix.Socket("ws://" + location.host +  "/ws");
  var $cnxn_status   = $("#cnxn-status");
  var $transmissions = $("#transmissions");

  var netwatchTxTemplateUserCol = function(message) {
    return "<strong class='h4 text-primary'>" + (message.radio_callsign || "Unknown") + "</strong>&nbsp;&mdash;&nbsp;<strong class='h4 text-muted'>" + (message.radio_name || "UNKNOWN") + "</strong><br />"
           + message.radio_id + "<br />"
           + message.radio_location
  }

  var netwatchTxTemplatePeerCol = function(message) {
    return (message.peer_callsign || "Unknown") + "<br />"
           + message.peer_id + "<br />"
           + message.peer_location
    }

  var netwatchTxTemplateNetCol = function(message) {
    return (message.bridge_group_name || "Unknown") + "<br />"
           + (message.site_name || "Unknown")
  }

  var netwatchTxTemplate = function(message){
    var msgContainer    = $("<div class='msg-container row'>"
                            + "<span class='col-xs-4'>" + netwatchTxTemplateUserCol(message) + "</span>"
                            + "<span class='col-xs-1'><span class='glyphicon glyphicon-arrow-right'></span></span>"
                            + "<span class='col-xs-3'>" + netwatchTxTemplatePeerCol(message) + "</span>"
                            + "<span class='col-xs-1'><span class='glyphicon glyphicon-arrow-right'></span></span>"
                            + "<span class='col-xs-3'>" + netwatchTxTemplateNetCol(message) + "</span>"
                            + "</div>"
                            )

    return(msgContainer);
  }

  // WEBSOCKETS
  socket.join("netwatch", "transmit", {}, function(chan){

    chan.on("join", function(message){
      $cnxn_status.html('<span class="label label-success">connected</span>');
    });

    chan.on("tx:in_progress", function(message){
      var parsed = $.parseJSON(message);
      $transmissions.prepend(netwatchTxTemplate(parsed));
    });

  });
});
