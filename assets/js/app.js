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

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Alpine from 'alpinejs'

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken } })

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()

window.liveSocket = liveSocket

window.onLogin = () => {
    let acknowledgement = window.document.getElementById("loginAcknowledgement")
    acknowledgement.className = ''
    acknowledgement.textContent = "Trying to sign you in..."
    let username = window.document.getElementById("loginUsername")
    let password = window.document.getElementById("loginPassword")
    fetch('/api/login', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
            'username': username.value,
            'password': password.value
        })
    })
        .then((response) => { return response.json() })
        .then((json) => {
            acknowledgement.textContent = json.message
            if (json.is_error) {
                acknowledgement.className = 'text-red-500 font-bold'
            } else {
                setTimeout(() => {
                    window.location.replace('/s/all')
                }, 2000)
            }
        })
}

window.onLogout = () => {
    fetch('/api/logout', {
        method: 'POST'
    })
        .then((_response) => {
            window.location.replace('/s/all')
        })
}

Alpine.store('menus', {
    loginOpen: false,
    navOpen: false,

    closeMenus() {
        this.loginOpen = false
        this.navOpen = false
    },

    toggleNavMenu() {
        this.navOpen = !this.navOpen
    },

    openLoginMenu() {
        this.navOpen = false
        this.loginOpen = true
    },

    closeNavMenu() {
        this.navOpen = false
    }
});
window.Alpine = Alpine
window.addEventListener("keyup", event => {
    let menus = Alpine.store('menus')
    switch (event.key) {
        case "Escape": {
            menus.closeMenus()
            break
        }
        case "Enter": {
            if (Alpine.store('menus').loginOpen) {
                window.onLogin()
            }
            break
        }
        default: {
            break
        }
    }
});
Alpine.start()