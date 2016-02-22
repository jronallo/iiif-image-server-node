# IIIF Image Server in Node

IIIF Image server written in Node using the [`iiif-image`](https://github.com/jronallo/iiif-image) module.

## Compliance

[IIIF Image API version 2.0](http://iiif.io/api/image/2.0/), [Level 1 compliant](http://iiif.io/api/image/2.0/compliance/).

Some Level 2 features are available like regionByPct, rotationBy90s and png format responses.

## Requirements

Currently `iiif-image` only works with JPEG2000 images. In order to handle JP2 files you'll need to install OpenJPEG (`opj_decompress` & `opj_dump`). You can also change the `jp2_binary` configuration (see confing/default.yml) to enable the more performant but proprietary Kakadu executables (`kdu_expand` & `kdu_jp2info`; see notice below about Kakadu).

`iiif-image` also relies on [sharp](http://sharp.dimens.io/en/stable/) for image processing which depends on libvips. Only OSX ought to need to install libvips.

## Usage

```sh
npm i
npm start
```

In your browser visit <http://localhost:3001/viewer/trumpler14>

## Configuration

See the config directory in the default.yml file for notes on settings.

See [node-config](https://github.com/lorenwest/node-config) for how to override the defaults for different environments. Note that for the most part all settings must be present, though for a particular environment you only have to include the differences from the default.

## Development

In one terminal run `npm run compile` to compile the Coffeescript.

In another terminal run `npm run watch` to restart the server on changes.

Run the tests with `npm run watch_test` for test reloading or just `npm test` to run them once.

## Vagrant and Server Deploys

The Ansible playbook and roles show how to get the server deployed to a CentOS 7 machine. You can run them with:

`vagrant up`

Once everything is installed you can visit: <http://localhost:8088/viewer/trumpler14>

## Logging

Currently everything is logged to ./log/iiif.log with [Bunyan](https://github.com/trentm/node-bunyan). Bunyan logs as JSON and comes with a command line tool to sort through log files and make them pretty for inspection.

Different keys tell you where in the code the log message comes from:

`route`: Basic logging for the main routes in the main application. The requested `url` and requestor `ip` are also logged.

`cache`: Tells which cache the logging message is for. Currently values would be "image" or "info". Other keys are used with `cache`. `found`: Has values "hit" or "miss". `img` is the path to the image. Also cache operations will use the `op` key.

`valid`: Information about the validity of requests. Has a value of true or false. `test` says whether the test for validity was done on just the request parameters with "params" or also include the image information for a fuller validity check with "info".

`res`: What kind of response has been sent. Will either be "info", "image", "viewer", or a status code.

## TODO
- Cache info.json to the filesystem without expiration.
- Ansible deploy scripts should set expires headers via nginx (or node?)
- Can performance be improved if output of opj_decompress and kdu_expand is streamed through a socket? How would this work? http://stackoverflow.com/questions/11750041/how-to-create-a-named-pipe-in-node-js/18226566#18226566
- When iiif-image supports extracting from other formats like TIF and JPEG:
  - Resolver should be able to find/match these formats.
  - Extractor should be selected dynamically. If JP2 then opj or kdu, otherwise just choose the sharp extractor.

## Kakadu Copyright Notice and Disclaimer
 We do not distribute the Kakadu executables. You will need to install the Kakadu binaries/executables available [here](http://kakadusoftware.com/downloads/). The executables available there are made available for demonstration purposes only. Neither the author, Dr. Taubman, nor UNSW Australia accept any liability arising from their use or re-distribution.

That site states:

> Copyright is owned by NewSouth Innovations Pty Limited, commercial arm of the UNSW Australia in Sydney. **You are free to trial these executables and even to re-distribute them, so long as such use or re-distribution is accompanied with this copyright notice and is not for commercial gain. Note: Binaries can only be used for non-commercial purposes.** If in doubt please contact the Kakadu Team at info@kakadusoftware.com.

## Author

Jason Ronallo

## License and Copyright

see MIT-LICENSE
