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
window.createContract = function(email, username) {
  window.crypto.subtle.generateKey({
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 4096,
      hash: "SHA-512",
      publicExponent: new Uint8Array([0x01, 0x00, 0x01]),
    }, true, ['sign', 'verify']
  ).then((contract) => {
    return Promise.all([
      window.crypto.subtle.exportKey('jwk', contract.privateKey),
      window.crypto.subtle.exportKey('jwk', contract.publicKey)
    ])
  }).then((keys, error) => {
    window.localStorage.setItem('contractPrivateKey', keys[0]);

    return fetch('/api/v0/contract', {
      method: 'PUT',

      body: JSON.stringify({
        'email': email,
        'username': username,
        'contractPublicKey': keys[1],
      }),

      headers: {
        'Content-Type': 'application/json'
      }
    })
  });
}

