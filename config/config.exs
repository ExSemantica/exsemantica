import Config

assets_dir = Path.join([Path.dirname(__DIR__), "assets"])
assets_out = Path.join([Path.dirname(__DIR__), "priv", "static", "assets"])

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:mfa]

config :esbuild,
  version: "0.14.12",
  default: [
    args: ~w(
      js/app.js
      --bundle
      --target=es2016
      --outdir=#{assets_out}
      --minify
    ),
    cd: assets_dir
  ]

config :tailwind,
  version: "3.0.15",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=#{Path.join(assets_out, "app.css")}
    --minify
  ),
    cd: assets_dir
  ]

# Set this to a theme binary, it's in `priv/templates/`
#
# For example, "indigo_child" maps to "indigo_child-MODE.html.eex" where MODE is
# the mode of the theme engine
#
# TODO: Document this more.
config :exsemtheme, theme: :indigo_child, cd: assets_dir, port: 8080, out: assets_out
config :exsemantica, port: 8088

import_config "#{Mix.env()}.exs"
