{request, app, test, cleanup} = require './test-helpers'

test 'OK info.json request', (assert) ->
  request(app)
    .get '/trumpler14/info.json'
    .expect 200
    .end (err, res) ->
      assert.error err
      assert.end()
      cleanup()

test 'info.json request for bad id', (assert) ->
  request(app)
    .get '/bad/info.json'
    .expect 404
    .end (err, res) ->
      assert.error err
      assert.end()
      cleanup()
