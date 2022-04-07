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
import { argon2id, argon2Verify } from 'hash-wasm'

import Alpine from 'alpinejs'

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
// import socket from "./user_socket.js"


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken } })

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

window.exSemFeedChannel = window.liveSocket.channel("lv_semantic_feed:home", {})
window.exSemFeedChannel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

window.exSemFeedChannel.on("update_trends", (msg) => {
    console.log("Trends received", msg)
    document.getElementById("trend-summary").innerText = "";
    msg.result.forEach(element => {
        let node = document.createElement("div");
        switch (element.type) {
            case "users":
                node.innerHTML = `<b>${element.handle}</b><br>user`
                node.classList.add(
                    'text-xs',
                    'transition',
                    'bg-amber-200',
                    'duration-0',
                    'hover:bg-amber-100',
                    'hover:duration-200',
                    'm-1',
                    'p-1',
                    'rounded-xl'
                )
                document.getElementById("trend-summary").appendChild(node)
                break;

            case "interests":
                node.innerHTML = `<b>${element.handle}</b><br>interest`
                node.classList.add(
                    'text-xs',
                    'transition',
                    'bg-lime-200',
                    'duration-0',
                    'hover:bg-lime-100',
                    'hover:duration-200',
                    'm-1',
                    'p-1',
                    'rounded-xl'
                )
                document.getElementById("trend-summary").appendChild(node)
                break;

            case "posts":
                node.innerHTML = `<b>${element.handle}</b><br>post`
                node.classList.add(
                    'text-xs',
                    'transition',
                    'bg-cyan-200',
                    'duration-0',
                    'hover:bg-cyan-100',
                    'hover:duration-200',
                    'm-1',
                    'p-1',
                    'rounded-xl'
                )
                document.getElementById("trend-summary").appendChild(node)
                break;
            default:
                break;
        }
    });
    document.getElementById("trend-display-waiting").innerText = `Trends loaded on ${msg.time}`
})

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
        await fetch(`/api/v0/login`, {
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
    } else {
        foot.innerText = 'Please wait... [logging in]';
        await fetch(`/api/v0/login`, {
            method: 'POST',
            headers: {
                'content-type': 'application/json'
            },
            body: JSON.stringify({
                'user': handle,
                'pass': passwd
            })
        })
    }
    setTimeout(() => window.location.reload(), 2000)
}