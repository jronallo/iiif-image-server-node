{request, app, test, cleanup} = require './test-helpers'

test 'bad format for image request', (assert) ->
  request(app)
    .get '/trumpler14/full/200,/0/default.asdf'
    .expect 400
    .end (err, res) ->
      assert.error err
      assert.end()
      cleanup()

test 'responds with 200 for good request', (assert) ->
  request(app)
    .get '/trumpler14/full/200,/0/default.jpg'
    .expect 200
    .end (err, res) ->
      assert.error err
      assert.end()
      cleanup()

test 'responds with 200 for request with parameters', (assert) ->
  request(app)
    .get '/trumpler14/full/200,/0/default.jpg?t=1463789246259'
    .expect 200
    .end (err, res) ->
      assert.error err
      assert.end()
      cleanup()
