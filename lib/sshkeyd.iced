express = require 'express'
request = require 'request'
marked = require 'marked'
fs = require 'fs'
path = require 'path'
util = require 'util'
_ = require 'underscore'
{
  exec
  spawn
} = require 'child_process'

_package = require '../package.json'
queue = require './queue'

githubapi = (method, url, qs, cb)->
  await request
    method: method
    url: url
    headers:
      'User-Agent': "sshkeyd #{_package.version}"
      'Accept': 'application/json'
    qs: qs
    defer e, res, data
  return cb new Error "GitHub API error: #{e.message}" if e
  try
    data = JSON.parse data
  catch e
    return cb new Error "GitHub API error: #{e.message}"
  return cb new Error "GitHub API error: #{data.message}" if res.statusCode != 200
  cb null, data

module.exports = class
  constructor: (@path_cfg)->
  get_handler: (cb)=>
    handler = new express()
    @queue = new queue()
    @queue.on 'error', (e)=> 
      @sync_error = e
      @queue.empty()
    handler.locals.pretty = true
    handler.locals.version = _package.version
    handler.locals.marked = marked
    handler.locals.params = (obj)=>
      str = ""
      str += "#{encodeURIComponent k}=#{encodeURIComponent v}&" for k, v of obj
      return str
    handler.locals._ = _
    handler.set 'view engine', 'jade'
    handler.set 'views', path.join __dirname, '..', 'views'
    handler.use '/assets', express.static path.join __dirname, 'assets'
    handler.use (rq, rs, cb)=>
      (rq.body?= {})[k] = v for k, v of rq.query
      cb null
    handler.use express.urlencoded()
    handler.use express.json()
    handler.use express.methodOverride()
    handler.use @route_read_config
    handler.use express.cookieParser()
    handler.use express.session
      secret: String Math.random()
    handler.use express.csrf()
    handler.use handler.router
    handler.all '/', @route_auth
    handler.get '/', @route_dashboard
    handler.post '/', @route_authorize
    handler.post '/', @route_add_server
    handler.post '/', @route_add_member
    handler.delete '/', @route_delete_server
    handler.use @route_error
    cb null, handler

  route_read_config: (rq, rs, cb)=>
    await fs.readFile @path_cfg, 'utf8', defer e, rq.cfg
    if e
      rq.cfg = {}
    else
      try
        rq.cfg = JSON.parse rq.cfg
      catch e
        return cb new Error "Error reading config file(`~/.sshkeyd.json`): #{e.message}"
    unless rq.cfg.client_secret? && rq.cfg.client_id? && rq.cfg.admin_username?
      if rq.method == 'GET'
        return rs.render 'install'
      if rq.method == 'POST' && rq.body.cfg
        rq.cfg.client_id = rq.body.cfg.client_id
        rq.cfg.client_secret = rq.body.cfg.client_secret
        rq.cfg.admin_username = rq.body.cfg.admin_username
        await @save_config rq.cfg, defer e
        return cb e if e
        return rs.redirect '.'
      return rs.redirect '.'
    rq.cfg.orgs ?= {}
    cb null

  route_auth: (rq, rs, cb)=>
    if rq.method == 'GET' && rq.query.state && rq.query.code
      return cb new Error 'request timeout' unless rq.query.state == rq.session.id
      await githubapi "POST", "https://github.com/login/oauth/access_token", code: rq.query.code, client_id: rq.cfg.client_id, client_secret: rq.cfg.client_secret, defer e, access
      return cb e if e
      rq.session.access_token = access_token = access.access_token

      await githubapi "GET", "https://api.github.com/user", access_token: access_token, defer e, user
      return cb e if e
      await githubapi "GET", "https://api.github.com/users/#{user.login}/orgs", access_token: access_token, defer e, user.orgs
      return cb e if e
      for org in user.orgs
        await githubapi "GET", "https://api.github.com/orgs/#{org.login}/members", access_token: access_token, defer e, org.members
        return cb e if e
      rq.session.user = user
      cb null
      return rs.redirect ''
    unless rq.session.user
      return rs.redirect "https://github.com/login/oauth/authorize?client_id=#{rq.cfg.client_id}&state=#{rq.session.id}&scope="
    rs.locals._csrf = rq.csrfToken()
    if rq.isAdmin = rq.session.user.login == rq.cfg.admin_username
      await exec 'which ssh', defer e, rq.bin_ssh
      return cb new Error "Cannot locate your `ssh` bin. Please set a valid `PATH` env." if e
      rq.bin_ssh = rq.bin_ssh.trim()
      rq.id_pub = []
      for format in ['rsa', 'dsa', 'ecdsa']
        await fs.readFile (path.join process.env.HOME, '.ssh', "id_#{format}.pub"), 'utf8', defer e, key
        rq.id_pub.push key.trim() unless e
      unless rq.id_pub.length
        return cb new Error """
        You don't have any ssh-keys yet. Get one through

        ```
        ssh-keygen
        ```
        """

    cb null
  route_dashboard: (rq, rs, cb)=>

    if rq.isAdmin
      await @sync_keys rq.id_pub, rq.bin_ssh, rq.session.access_token, rq.cfg, defer e
      return cb e if e


    rs.locals.other_orgs = other_orgs = ["_personal"]
    if rq.isAdmin
      for org, servers of rq.cfg.orgs
        if _.every(rq.session.user.orgs, (o)-> o.login != org)

          await githubapi "GET", "https://api.github.com/orgs/#{org}/members", access_token: rq.session.access_token, defer e, members
          unless e
            other_orgs.push 
              login: org
              members: members

    rs.locals.orgs_other_members = orgs_other_members = {}
    for org in rq.session.user.orgs.concat other_orgs
      orgs_other_members[org.login] = []
      for server, members of rq.cfg.orgs[org.login]
        for member in members
          if _.every(org.members, (m)-> m.login != member) && !_.contains(orgs_other_members[org.login], member)
            orgs_other_members[org.login].push member

    rs.locals.active_org = rq.session.active_org||''
    unless rs.locals.active_org = _.find(rq.session.user.orgs.concat(other_orgs), (o)-> o.login == rs.locals.active_org)
      rs.locals.active_org = rq.session.user.orgs.concat(other_orgs)[0]
    return rs.render 'dashboard', 
      isAdmin: rq.isAdmin
      user: rq.session.user
      orgs: rq.cfg.orgs
      added_type: rq.session.added_type||'server'
      added_value: rq.session.added_value||''



  route_authorize: (rq, rs, cb)=>
    if rq.isAdmin && rq.body.authorization?
      rq.cfg.orgs[rq.body.authorization.org] = org = {}
      for server_host, server of rq.body.authorization.servers
        org[server_host] = members = []
        for member, authorized of server.members
          members.push member if authorized
      await @save_config rq.cfg, defer e
      return cb e if e
      await @sync_keys rq.id_pub, rq.bin_ssh, rq.session.access_token, rq.cfg, defer e
      return cb e if e
      rq.session.active_org = rq.body.authorization.org
      return rs.json {} if rq.get('Accept').match /json/
      return rs.redirect '.' 
    cb null

  route_add_server: (rq, rs, cb)=>
    if rq.isAdmin && rq.body.server
      if rq.body.server.host = rq.body.server.host.trim()
        await @push_keys rq.id_pub, rq.bin_ssh, [rq.id_pub], rq.body.server.host, defer e
        return cb e if e

        (rq.cfg.orgs[rq.body.server.org]?= {})[rq.body.server.host] ?= []

        await @save_config rq.cfg, defer e
        return cb e if e
      rq.session.added_type = 'server'
      rq.session.added_value = rq.body.server.host
      rq.session.active_org = rq.body.server.org
      return rs.redirect '' 
    cb null

  route_add_member: (rq, rs, cb)=>
    if rq.isAdmin && rq.body.member
      if rq.body.member.login = rq.body.member.login.trim()
        await @get_id_pub rq.session.access_token, rq.body.member.login, defer e, keys
        return cb e if e

        for host, members of rq.cfg.orgs[rq.body.member.org]?= {}
          members.push rq.body.member.login if -1 == members.indexOf rq.body.member.login

        await @save_config rq.cfg, defer e
        return cb e if e
      rq.session.added_type = 'member'
      rq.session.added_value = rq.body.member.login
      rq.session.active_org = rq.body.member.org
      return rs.redirect '' 
    cb null
  route_delete_server: (rq, rs, cb)=>
    if rq.isAdmin && rq.body.server
      if rq.body.server.host = rq.body.server.host.trim()
        delete (rq.cfg.orgs[rq.body.server.org]?= {})[rq.body.server.host]
        await @save_config rq.cfg, defer e
        return cb e if e
      rq.session.active_org = rq.body.server.org
      return rs.redirect '' 
    cb null
  route_error: (e, rq, rs, cb)->
    rs.statusCode = 500
    rs.render 'error', error: e

  sync_keys: (id_pub, bin_ssh, access_token, cfg, cb)=>
    if @sync_error
      await @syncing_keys id_pub, bin_ssh, access_token, cfg, defer e
      return cb e if e
      @sync_error = null
    else
      @queue.empty()
      @queue.enqueue (done)=>
        @syncing_keys id_pub, bin_ssh, access_token, cfg, done
    cb null

  syncing_keys: (id_pub, bin_ssh, access_token, cfg, cb)=>
    for org, servers of cfg.orgs||{}
      for server, members of servers||{}
        keys = []
        keys.push key for key in id_pub
        for member in members||[]
          await @get_id_pub access_token, member, defer e, member_keys
          return cb e if e
          keys.push key for key in member_keys
        await @push_keys id_pub, bin_ssh, keys, server, defer e
        return cb e if e

    cb null

  push_keys: (id_pub, bin_ssh, keys, server, cb)=>
    server_arr = server.split ','
    process.stdout.write "syncing #{keys.length} keys to #{server}... "

    ssh = spawn bin_ssh, [
        "-o"
        "PasswordAuthentication=no"
        "-o"
        "StrictHostKeyChecking=no"
        "-o"
        "PasswordAuthentication=no"
        "-o"
        "GSSAPIAuthentication=no"
        "-o"
        "ChallengeResponseAuthentication=no"
        "-p"
        server_arr[1]||22
        server_arr[0]
        'mkdir -p .ssh && cat - > .ssh/authorized_keys'
      ], stdio: ['pipe', 1, 2]
    ssh.stdin.setEncoding 'utf8'
    for key in keys
      ssh.stdin.write key
      ssh.stdin.write '\n'
    ssh.stdin.end()
    await ssh.on 'close', defer code
    if code
      process.stdout.write 'error!\r\n'
      return cb new Error """
      Error syncing keys to `#{server}`. Use the following command to authorize your self on this host.

      ```
      ssh-copy-id -p #{server_arr[1]||22} #{server_arr[0]}
      ```
      """
    process.stdout.write 'ok.\r\n'
    cb null

  get_id_pub: (access_token, github_login, cb)=>
    @_sshkey_cache?= {}
    keys = @_sshkey_cache[github_login]
    return cb null, keys if keys?
    await githubapi "GET", "https://api.github.com/users/#{github_login}/keys", access_token: access_token, defer e, keys
    return cb e if e
    cb null, @_sshkey_cache[github_login] = keys.map (key)-> key.key

  save_config: (cfg, cb)=>
    await fs.writeFile @path_cfg, (JSON.stringify cfg, null, '  '), 'utf8', defer e
    return cb new Error "Error writing config file(`~/.sshkeyd.json`): #{e.message}" if e
    cb null

