# IIIF Image Server in Node

IIIF Image server written in Node using the [`iiif-image`](https://github.com/jronallo/iiif-image) module.

## Compliance

[IIIF Image API version 2.0](http://iiif.io/api/image/2.0/), [Level 1 compliant](http://iiif.io/api/image/2.0/compliance/).

Most Level 2 features are available. Additional features supported include "square" regions and the non-standard "!square" and "square!" regions which add a left-top or bottom-right gravity respectively. See [`iiif-image`](https://github.com/jronallo/iiif-image) for more information.

[Validation tests](http://iiif.io/api/image/validator/results/?server=http%3A%2F%2Fiiif.lib.ncsu.edu&prefix=&identifier=67352ccc-d1b0-11e1-89ae-279075081939&version=2.0&level=2&id_squares=on&info_json=on&id_basic=on&id_error_escapedslash=on&id_error_unescaped=on&id_escaped=on&id_error_random=on&region_error_random=on&region_pixels=on&region_percent=on&size_region=on&size_error_random=on&size_ch=on&size_wc=on&size_percent=on&size_bwh=on&size_wh=on&rot_error_random=on&rot_region_basic=on&rot_full_basic=on&quality_error_random=on&quality_color=on&quality_bitonal=on&quality_grey=on&format_jpg=on&format_error_random=on&format_png=on&jsonld=on&baseurl_redirect=on&cors=on) that do not pass include setting a JSON-LD media type but only under certain caching circumstances. [See this discussion](https://groups.google.com/forum/#!topic/iiif-discuss/NuDHEgEbzo0) on the list about content types. This server only supports the "default" quality. If you need support for "color", "gray", and "bitonal" qualities, let me know.

## Requirements

Currently `iiif-image` only works with JPEG2000 images. In order to handle JP2 files you'll need to install OpenJPEG (`opj_decompress` & `opj_dump`). You can also change the `jp2_binary` configuration (see confing/default.yml) to enable the more performant but proprietary Kakadu executables (`kdu_expand` & `kdu_jp2info`; see notice below about Kakadu).

`iiif-image` also relies on [sharp](http://sharp.dimens.io/en/stable/) for image processing which depends on libvips. Only OSX ought to need to install libvips.

Non-standard features include region by "!square" (for top-left gravity) and "square!" (bottom-left gravity).

## Usage

```sh
npm i
npm start
```

In your browser visit <http://localhost:3001/viewer/trumpler14>

## Configuration

See the config directory in the default.yml file for notes on settings.

See [node-config](https://github.com/lorenwest/node-config) for how to override the defaults for different environments. Note that for the most part all settings must be present, though for a particular environment you only have to include the differences from the default.

## Cleaning the File Cache

TODO: Work in progress

`clean_iiif_cache` can be used to clean the file cache of old, unused image files. It uses the file's atime to determine whether to delete the file or not. Caches a file for longer periods of time if it is in an image profile of frequently used images. See the `iiif` CLI that [`iiif-image`](https://github.com/jronallo/iiif-image) provides for how the same image profile can be used to warm the cache.

## Development

In one terminal run `npm run compile` to compile the Coffeescript.

In another terminal run `npm run watch` to restart the server on changes.

Run the tests with `npm run watch_test` for test reloading or just `npm test` to run them once.

## Vagrant

The Ansible playbook and roles show how to get the server deployed to a CentOS 7 machine. You can run them with:

`vagrant up`

Once everything is installed you can visit: <http://localhost:8088/viewer/trumpler14>

If you use the "public" image cache one trick you can use is to make the public directory a symlink to where your cache lives to allow it to be persistent across deploys.

## Deployment

Here is basically how I am deploying this project in case it is useful for anyone else. The ansible directory contains roles which should help give you some direction on how to automate deployment of the application on a CentOS or RHEL machine. This is not a full recipe though. In Vagrant the code is already linked into the VM--it is just there. For a staging or production deploy the code needs to be pushed to the remote server. I like to push code out with Capistrano.

This is too brief but hopefully gives some direction:

1. Get a server set up with Passenger and Nginx. This is done with the steps in ansible/roles/passenger-nginx-install.
2. Deploy the app with Capistrano and note the path of the deploy.
3. Install the other dependencies for the image server using the image-server role.
4. Configure Passenger and Nginx using the passenger-nginx-config role.

TODO: Adjust the ansible roles for proven actual production deploy.

## Logging

Currently everything is logged to ./log/iiif.log with [Bunyan](https://github.com/trentm/node-bunyan). Bunyan logs as JSON and comes with a command line tool to sort through log files and make them pretty for inspection.

Different keys tell you where in the code the log message comes from:

`route`: Basic logging for the main routes in the main application. The requested `url` and requestor `ip` are also logged.

`cache`: Tells which cache the logging message is for. Currently values would be "image" or "info". Other keys are used with `cache`. `found`: Has values "hit" or "miss". `img` is the path to the image. Also cache operations will use the `op` key.

`valid`: Information about the validity of requests. Has a value of true or false. `test` says whether the test for validity was done on just the request parameters with "params" or also include the image information for a fuller validity check with "info".

`res`: What kind of response has been sent. Will either be "info", "image", "viewer", or a status code.

## TODO
- Allow iiif-image profile documents to be used for image caching or cache cleanup decisions.
- Disable memory cache clearing?
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
