fbpDiffBot = require '..'
express = require 'express'
bodyParser = require 'body-parser'
debug = require('debug')('fbp-diffbot:app')

checkPr = (req, res) ->
  repo = "#{req.params.owner}/#{req.params.repo}"
  pr = req.params.pr
  options = req.query

  debug '/checkpr', repo, pr

  fbpDiffBot.diffbot.checkPr req.config, repo, pr, options
  .then (commentUrl) ->
    return res.status(200).end()
  .catch (err) ->
    console.error '/checkpr', err
    code = err.code or 500
    return res.status(code).end()

githubHook = (req, res) ->
  repoName = req.body.repository.full_name
  pr = req.body.pull_request.number
  options = {}

  debug '/hooks/github', req.body.action, repoName, pr

  fbpDiffBot.diffbot.checkPr req.config, repoName, pr, options
  .then (commentUrl) ->
    return res.status(200).end()
  .catch (err) ->
    console.error '/hooks/github', err
    code = err.code or 500
    return res.status(code).end()

  return res.status(404).end() # FIXME: implement

exports.getApp = getApp = (config) ->
  app = express()

  app.use (req, res, next) ->
    req.config = config # Attach config to request, so handlers can access
    next()

  app.use(bodyParser.json())

  app.post '/checkpr/:owner/:repo/:pr', checkPr
  app.post '/hooks/github', githubHook

  return app

exports.start = (override, callback) ->
  defaults =
    port: process.env.PORT || 3000
    endpoint: 'https://api.github.com'
    token: process.env.GH_TOKEN
    ownurl: 'https://fbp-diffbot.herokuapp.com'

  config = {}
  for k, v of defaults
    config[k] = v
  for k, v of override
    config[k] = v

  app = getApp config
  app.listen config.port, (err) ->
    return callback err if err
    return callback null, app, config.port
