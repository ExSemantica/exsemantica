// var argon2 = require('argon2-browser');
// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.


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
import { Socket } from "phoenix"
import topbar from "topbar"
import { LiveSocket } from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken } })

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show())
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// TODO: Email is currently unimplemented.
window.contractRegisterUnverified = function (email, username) {
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

window.contractCheck = function (username, _password) {
  fetch('/api/v0/login?user="' + username + '"', {
    method: 'GET',

    headers: {
      'Content-Type': 'application/json'
    }
  })
    .then(result => { return result.json(); })
    .then(jsonResult => {
      console.log(jsonResult);
      // NOTE to self: Do not make this a boolean, it shall be either a contract or not.
      if (!jsonResult.fulfilledContract) {
        document.getElementById('motd').innerText = jsonResult.msg;
      }
    }).catch(e => {
      console.error(e);
      document.getElementById('motd').innerText = "An unknown error occured in your browser.";
    });
}

window.checkLogin = function () {
  contractCheck(
    document.getElementById('email').value,
    document.getElementById('password').value,
  );
}

window.runLogin = true;

window.clientValidateLogin = async function (ev) {
  ev.stopPropagation();

  if (window.runLogin) {
    window.runLogin = false;
    let motd = document.getElementById('motd');
    motd.innerText = "Attempting to log you in...";
    motd.classList.add("bg-indigo-400");
    motd.classList.remove("invisible");
    await new Promise((r) => setTimeout(r, 2000)).then((_) =>
      fetch('/api/v0/login?user=' + document.getElementById('username').value, {
        method: 'GET',

        headers: {
          'Content-Type': 'application/json'
        }
      })
    )
      .then((result) => {
        motd.classList.remove("bg-indigo-400");
        return result.json();
      })
      .then((result) => {
        if (result.e) {
          motd.classList.add("bg-red-500");
          document.getElementById('motd').innerText = result.msg;
        }
        window.runLogin = true;
      }, (err) => {
        motd.classList.add("bg-red-500");
        document.getElementById('motd').innerText = err;
        window.runLogin = true;
      })
  }
}