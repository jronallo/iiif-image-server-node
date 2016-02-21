{request, app, test, cleanup} = require './test-helpers'

test 'viewer on OK', (assert) ->
  request(app)
    .get '/viewer/trumpler14'
    .expect 200
    .end (err, res) ->
      assert.error err
      assert.end()
      cleanup()

test 'viewer on bad id request', (assert) ->
  request(app)
    .get '/viewer/bad'
    .expect 404
    .end (err, res) ->
      assert.error err
      assert.end()
      cleanup()
