http = require 'http'
path = require 'path'
sshkeyd = require './sshkeyd'
module.exports = (cb)->

  return cb new Error 'you must set a valid HOME env for sshkeyd before continue' unless process.env.HOME
  instance = new sshkeyd path.join process.env.HOME, '.sshkeyd.json'
  await instance.get_handler defer e, handler
  return cb e if e
  server = http.createServer handler
  await server.listen process.env.PORT||10000, defer e
  return cb e if e
  console.log "sshkeyd running on http://localhost:#{server.address().port}/ "
  await server.on 'close', defer e
  cb e
