
global <<< require \prelude-ls # immutable (ease-of-access)

# App
#####
require! {
  http
  \pretty-error : PrettyError
  \rethinkdb-websocket-server : {r, RQ, listen}
  \rethinkdbdash : rethinkdb
  koa
  \koa-helmet : helmet
  \koa-generic-session : session
  \koa-generic-session-rethinkdb : RethinkSession
  \koa-logger
  \./pages
  \./middleware
  \../shared/features
}

pe  = new PrettyError!
env = process.env.NODE_ENV or \development

# connect to rethinkdb
[db-host, db-port, http-path] =
  [process.env.npm_package_config_domain,
   process.env.npm_package_config_rethinkdb_port,
   '/db']
connection = rethinkdb {db-host, db-port}
store      = new RethinkSession {connection}
  ..setup! # initial tables

### App's purpose is to abstract instantiation from starting & stopping
module.exports =
  class App
    (@port=8080, @changeset=\latest) ->

    start: (cb = (->)) ->
      console.log "[1;37;30m+ [1;37;40m#env[0;m @ port [1;37;40m#{@port}[0;m ##{@changeset[to 5].join ''}"

      @app = koa! # attach middlewares
        ..keys = ['iAsNHei275_#@$#%^&']   # cookie session secrets
        ..on \error (err) ->
          console.error(pe.render err)    # error handler
        ..use helmet!                     # solid secure base
        ..use middleware.webpack          # proper dev-server headers
        ..use middleware.error-handler    # 404 & 50x handler
        ..use middleware.config-locals @  # load env-sensitive config into locals
        ..use middleware.health-probe     # for upstream balancers, proxies & caches 
        ..use middleware.rate-limit       # rate limiting for all requests (override in package.json config)
        ..use middleware.app-cache        # offline support
        ..use middleware.static-assets    # static assets handler
        ..use session {store}             # rethinkdb session support for koa
        ..use middleware.jade             # use minimalistic jade layout (escape-hatch from react)
        ..use middleware.etags            # auto etag every page for caching
        ..use pages                       # apply pages

      # config environment
      if env isnt \test then @app.use koa-logger!

      # boot http server
      @server = http.create-server @app.callback!
      listen {db-host, http-path, http-server: @server, unsafely-allow-any-query: env isnt \production}

      # listen
      unless @port is \ephemeral then @server.listen @port, cb
      @app

    stop: (cb = (->)) ->
      console.log "[1;37;30m- [1;37;40m#env[0;m @ port [1;37;40m#{@port}[0;m ##{@changeset[to 5].join ''}"
      # cleanup & cleanly quit listening
      <~ @server.close
      connection.get-pool-master!drain!
      cb!
