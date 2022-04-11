// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

import Alpine from 'alpinejs'

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import socket from "./user_socket.js"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
    params: {
        _csrf_token: csrfToken,
        paseto: localStorage.getItem('exsemantica_paseto'),
        handle: localStorage.getItem('exsemantica_handle')
    }
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
window.Alpine = Alpine
Alpine.start()



window.loginInitiate = async () => {
    let handle = document.getElementById("login-handle").value
    let passwd = document.getElementById("login-password").value
    let invite = document.getElementById("login-invite").value
    let presence = await fetch(`/api/v0/login?user=${handle}`, { method: 'GET' })
    let presence_json = await presence.json()

    let foot = document.getElementById("login-footer")
    foot.classList.remove('invisible')

    if (presence_json.unique) {
        foot.innerText = 'Please wait... [registering]';
        let result = await fetch(`/api/v0/login`, {
            method: 'PUT',
            headers: {
                'content-type': 'application/json'
            },
            body: JSON.stringify({
                'user': handle,
                'pass': passwd,
                'invite': invite
            })
        })
        let result_json = await result.json()
        setTimeout(() => {
            if (result_json.success) {
                window.location.reload()
            } else {
                foot.innerText = result_json.description
            }
        }, 2000)
    } else {
        foot.innerText = 'Please wait... [logging in]';
        let result = await fetch(`/api/v0/login`, {
            method: 'POST',
            headers: {
                'content-type': 'application/json'
            },
            body: JSON.stringify({
                'user': handle,
                'pass': passwd
            })
        })
        let result_json = await result.json()

        setTimeout(() => {
            if (result_json.success) {
                localStorage.setItem('exsemantica_handle', result_json.handle)
                localStorage.setItem('exsemantica_paseto', result_json.paseto)
                window.location.reload()
            } else {
                foot.innerText = result_json.description
            }
        }, 2000)
    }
}