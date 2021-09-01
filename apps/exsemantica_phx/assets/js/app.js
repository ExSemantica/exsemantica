// var argon2 = require('argon2-browser');
// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "tailwindcss/tailwind.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import topbar from "topbar"
import {LiveSocket} from "phoenix_live_view"

import 'jsonwebtoken'

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// TODO: Email is currently unimplemented.
window.contractRegisterUnverified = function(email, username) {
  fetch('/api/v0/registration', {
      method: 'PUT',

      body: JSON.stringify({
        'email': email,
        'username': username,
      }),

      headers: {
        'Content-Type': 'application/json'
      }
  })
    .then((_) => { return true })
    .catch((e) => {
      console.error(e);
      return false
    })
}

window.contractCheck = function(username, password) {
  fetch('/api/v0/registration?user="' + username + '"', {
    method: 'GET',

    headers: {
      'Content-Type': 'application/json'
    }
  })
    .then(result => {return result.json(); })
    .then(jsonResult => {
      console.log(jsonResult);
      // NOTE to self: Do not make this a boolean, it shall be either a contract or not.
      if(!jsonResult.fulfilledContract) {
        document.getElementById('motd').innerText = jsonResult.msg; 
      }
    }).catch(e => {
      console.error(e);
      document.getElementById('motd').innerText = "An unknown error occured in your browser.";
    });
}

window.checkLogin = function() {
  contractCheck(
    document.getElementById('email').innerText,
    document.getElementById('password').innerText,
  );
}

