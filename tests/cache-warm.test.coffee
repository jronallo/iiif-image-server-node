{request, app, test, cleanup, delay} = require './test-helpers'
path = require 'path'
fs = require 'fs'

test 'cache warming works', (assert) ->
  cleanup()
  request(app)
    .get '/warm/trumpler14'
    .expect 200
    .end (err, res) ->
      # File caching happens _after_ the response is sent so we need to delay
      # before checking on the presence of the files.
      delay 100, ->
        # Check that the body returned is correct
        res_json = res.body
        expected_response = [
          "/square/300,/0/default.jpg",
          "/full/600,/0/default.jpg",
          "/square/75,/0/default.png"]
        assert.deepEqual res_json, expected_response

        # Check that the files exist
        info_json_path = path.join __dirname, '../public/trumpler14/info.json'
        assert.ok fs.statSync(info_json_path)
        for part_path in expected_response
          full_path = path.join __dirname, '../public/trumpler14', part_path
          assert.ok fs.statSync(full_path)

        cleanup()
        assert.end()
