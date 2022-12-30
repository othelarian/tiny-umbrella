bach = require 'bach'
chokidar = require 'chokidar'
coffee = require 'coffeescript'
connect = require 'connect'
fse = require 'fs-extra'
http = require 'http'
{ extname } = require 'path'
pug = require 'pug'
{ rollup, watch } = require 'rollup'
sass = require 'sass'
serveStatic = require 'serve-static'
sharp = require 'sharp'
{ terser } = require 'rollup-terser'

{ nodeResolve } = require '@rollup/plugin-node-resolve'
commonjs = require '@rollup/plugin-commonjs'

# OPTIONS #############################

option '-r', '--release', 'set compilation mode to release'
option '-f', '--force', 'ONLY FOR PWA: regen all the PWA files'

# GLOBAL VARS #########################

cfg = require('./config.default').cfg

# ROLLUP PLUGINS ######################

rollCoffee = (opts = {}) =>
  name: 'rolling-coffee'
  transform: (code, id) ->
    if extname(id) != '.coffee' then return null
    out = coffee.compile code, opts
    code: out

# PWA FUNS ############################

pwaIcon = (cb) ->
  await fse.mkdirs cfg.icon.dir
  runExec 'icon', cb

pwaManifest = (cb) ->
  gen_file = "#{cfg.dest}/#{cfg.pwa['short-name']}.webmanifest"
  src_file = "#{cfg.pwa.path}/manifest.coffee"
  coffManifest = await timeDiff gen_file, src_file
  coffDefault = await timeDiff gen_file, 'config.default.coffee'
  coffCustom = await timeDiff gen_file, 'config.coffee'
  if not cfg.force and coffManifest and coffDefault and coffCustom
    console.log 'manifest already on the latest version'
    cb null, 8
  else
    try
      await fse.writeFile gen_file, JSON.stringify require("./#{src_file}").manifest cfg
      traceExec 'manifest'
      cb null, 8
    catch e
      cb e, null

pwaSW = (cb) ->
  gen_file = cfg.pwa.service_worker.out
  src_file = cfg.pwa.service_worker.src
  if not cfg.force and await timeDiff gen_file, src_file
    console.log 'sw script already on the latest version'
    cb null, 9
  else
    in_opts = {input: src_file, plugins: [rollCoffee {bare: true}]}
    out_opts =
      file: "./#{gen_file}"
      format: 'iife'
      plugins: (if cfg.envRelease then [terser()] else [])
    try
      await (await rollup in_opts).write out_opts
      traceExec 'sw'
      cb null, 9
    catch e
      cb e, null

# COMMON FUNS #########################

timeDiff = (gen_file, src_file) ->
  getTime = (path) ->
    try
      (await fse.stat path).mtimeMs
    catch
      0
  gen_time = await getTime gen_file
  src_time = await getTime src_file
  gen_time > src_time

doExec = (in_files, out_file, selected) ->
  try
    rendered = switch selected
      when 'pug', 'icon' then pug.renderFile in_files[0], cfg
      when 'sass'
        style = if cfg.envRelease then 'compressed' else 'expanded'
        (sass.compile in_files, {style}).css
    fse.writeFileSync out_file, rendered
    if selected is 'icon'
      icn_path = cfg.icon.dir
      sh = sharp cfg.icon.out
      resizing = (size) -> await sh.resize(size).toFile "#{icn_path}/icon_#{size}.png"
      resizing size for size in cfg.pwa.icon_sizes
    traceExec selected
  catch e
    console.error "doExec '#{selected}' => Something went wrong!!!!\n\n\n#{e}"

traceExec = (name) ->
  stmp = new Date().toLocaleString()
  console.log "#{stmp} => #{name} compilation done"

runExec = (selected, cb) ->
  [in_files, out_file] = switch selected
    when 'pug' then [cfg.web.html.src, cfg.web.html.out]
    when 'icon' then [cfg.icon.src, cfg.icon.out]
    when 'sass' then [cfg.web.sass.src, cfg.web.sass.out]
  doExec in_files, out_file, selected
  if cfg.watching then watchExec in_files, out_file, selected
  cb null, 11

watchExec = (to_watch, out_file, selected) ->
  watcher = chokidar.watch to_watch
  watcher.on 'change', => doExec(to_watch, out_file, selected)
  watcher.on 'error', (err) => console.log "CHOKIDAR ERROR:\n#{err}"

# ACTION FUNS #########################

checkEnv = (options) ->
  cfgpath = './config.coffee'
  try
    fse.accessSync cfgpath
    cfgov = require(cfgpath).cfg
    cfg[key] = value for key, value of cfgov
  cfg.envRelease = if options.release? then true else false
  cfg.watching = false
  cfg.dest = cfg.dest_path[if cfg.envRelease then 'release' else 'debug']
  if options.publish then cfg.dest = cfg.dest_path.github
  outUpdate = (path) ->
    curr = if path.length is 0 then cfg else
      tmp = cfg
      tmp = tmp[p] for p in path
      tmp
    for own key, value of curr
      if typeof curr[key] is 'object' and not Array.isArray curr[key]
        npath = Array.from path
        npath.push key
        outUpdate npath
      else if key is 'out' or key is 'dir' then curr[key] = "#{cfg.dest}/#{curr[key]}"
  outUpdate []
  cfg.force = options.force?

compileJs = (cb) ->
  #in_opts = {input: cfg.web.coffee.src, plugins: [rollCoffee({bare: true}), nodeResolve()]}
  in_opts =
    input: cfg.web.coffee.src
    plugins: [rollCoffee({bare: false}), nodeResolve(), commonjs()]
  out_opts =
    file: cfg.web.coffee.out
    format: 'cjs'
    plugins: (if cfg.envRelease then [terser()] else [])
  if cfg.watching
    watcher = watch {in_opts..., output: out_opts}
    watcher.on 'event', (event) ->
      if event.code is 'ERROR' then console.log event.error
      else if event.code is 'END' then traceExec 'coffee'
  else
    bundle = await rollup in_opts
    await bundle.write out_opts
    traceExec 'coffee'
  cb null, 0

compilePug = (cb) -> runExec 'pug', cb

compilePWA = (cb) -> (bach.series pwaIcon, pwaManifest, pwaSW) cb

compileSass = (cb) -> runExec 'sass', cb

createDir = (cb) ->
  try
    await fse.mkdirs "./#{cfg.dest}/#{cfg.static}"
    await fse.copy "./#{cfg.static}", "./#{cfg.dest}/#{cfg.static}"
    cb null, 0
  catch e
    if e.code = 'EEXIST'
      if not cfg.envRelease
        console.warn 'Warning: \'dist\' already exists'
      cb null, 1
    else cb e, null

launchServer = ->
  console.log 'launching server...'
  app = connect()
  app.use(serveStatic "./#{cfg.dest}")
  http.createServer(app).listen 5000
  console.log 'dev server launched'

building = bach.series createDir, compileSass, compilePug, compilePWA, compileJs

# TASKS ###############################

task 'build', 'build the app (core + static + wasm)', (options) ->
  checkEnv options
  console.log 'building...'
  building (e, _) ->
    if e?
      console.log 'Something went wrong'
      console.log e
    else console.log 'building => done'

task_cleandesc =
  "rm ./#{cfg.dest_path.debug} or ./#{cfg.dest_path.release} (debug or release)"
task 'clean', task_cleandesc, (options) ->
  checkEnv options
  console.log "cleaning `#{cfg.dest}`..."
  fse.remove "./#{cfg.dest}", (e) ->
    if e? then console.log e
    else console.log "`#{cfg.dest}` removed successfully"

task 'github', 'populate `docs` dir for github page', (options) ->
  checkEnv {release: true, publish: true}
  fse.remove "./#{cfg.dest}", (e) ->
    if e? then console.log e
    else
      building (e, _) ->
        if e? then console.log e
        else console.log 'publishing DONE'

task 'icon', 'generate and watch for the icon', (options) ->
  checkEnv options
  if cfg.envRelease
    console.error 'Impossible to use `icon` in `releaase` mode!'
  else
    cfg.watching = true
    pwaIcon (e, _) -> if e? then console.log e

task 'pwa', 'compile everything for the PWA (icon + manifest + sw)', (options) ->
  checkEnv options
  compilePWA (e, _) -> if e? then console.log e

task 'serve', 'launch a micro server and watch files', (options) ->
  checkEnv options
  if cfg.envRelease
    console.error 'Impossible to use `serve` in `release` mode!'
  else
    cfg.watching = true
    serving = bach.series createDir, compilePWA,
      (bach.parallel compileSass, compilePug, compileJs, launchServer)
    serving (e, _) -> if e? then console.log e

task 'static', 'compile sass, pug, pwa stuff, and copy static files', (options) ->
  checkEnv options
  compileStatic = bach.parallel compileSass, compilePug, compilePWA
  (bach.series createDir, compileStatic) (e, _) -> if e? then console.log e

task 'wasm', 'use rollup to compile wasm and coffee (only coffee here)', (options) ->
  checkEnv options
  compileJs -> 42
