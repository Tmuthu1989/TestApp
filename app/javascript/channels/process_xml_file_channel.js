import consumer from "channels/consumer"
// var $ = Wrap.Constructor;
consumer.subscriptions.create("ProcessXmlFileChannel", {
  connected() {
    $("#file_processing_alert").html("No files processing!")
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    $("#file_processing_alert").html(data.message)
    // Called when there's incoming data on the websocket for this channel
  }
});
