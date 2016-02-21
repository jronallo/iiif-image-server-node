{request, app, test, cleanup} = require './test-helpers'

test 'bad format for image request', (assert) ->
  request(app)
    .get '/trumpler14/full/200,/0/default.asdf'
    .expect 400
    .end (err, res) ->
      assert.error err
      assert.end()
      cleanup()
