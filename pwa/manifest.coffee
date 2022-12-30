exports.manifest = (cfg) ->
  gen_icons= []
  genfn = (elt, i) ->
    r = {src: "icons/icon_#{elt}.png", sizes: "#{elt}x#{elt}", type: "image/png"}
    if cfg.pwa.icon_mask[i] then r.purpose = "maskable"
    gen_icons.push r
  genfn elt, i++ for elt, i in cfg.pwa.icon_sizes
  gen_icons.push {src: 'icons/icon.svg', sizes: cfg.pwa.icon_svg}
  name: cfg.pwa.name
  "short-name": cfg.pwa.shortname
  display: cfg.pwa.display
  description: cfg.pwa.description
  lang: cfg.pwa.lang
  background_color: cfg.pwa.background_color
  theme_color: cfg.pwa.theme_color
  start_url: cfg.pwa.start_url
  icons: gen_icons
  scope: cfg.pwa.scope
