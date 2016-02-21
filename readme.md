# IIIF Image Server in Node

Simple example IIIF Image server written in Node to show the use of the `iiif-image` module.

## Requirements

In order to handle JP2 files you'll need to install OpenJPEG (`opj_decompress` & `opj_dump`). You can also make some changes to the code to enable the more performant but proprietary Kakadu executables (`kdu_expand` & `kdu_jp2info`).

## Usage

```sh
npm i
npm start
```

In your browser visit <http://localhost:3001/viewer/trumpler14>

## Configuration

See the config directory.

## Development

In one terminal run `npm run compile` to compile the Coffeescript.

In another terminal run `nodemon` to restart the server on changes.

## Vagrant

The Ansible playbook and roles show how to get the server deployed to a CentOS 7 machine. You can run them with:

`vagrant up`

Once everything is installed you can visit: <http://localhost:8088/viewer/trumpler14>

## TODO
- Ansible deploy scripts should set expires headers via nginx (or node?)
- Can performance be improved if output of opj_decompress and kdu_expand is streamed through a socket? How would this work? http://stackoverflow.com/questions/11750041/how-to-create-a-named-pipe-in-node-js/18226566#18226566

## Kakadu Copyright Notice and Disclaimer
 We do not distribute the Kakadu executables. You will need to install the Kakadu binaries/executables available [here](http://kakadusoftware.com/downloads/). The executables available there are made available for demonstration purposes only. Neither the author, Dr. Taubman, nor UNSW Australia accept any liability arising from their use or re-distribution.

That site states:

> Copyright is owned by NewSouth Innovations Pty Limited, commercial arm of the UNSW Australia in Sydney. **You are free to trial these executables and even to re-distribute them, so long as such use or re-distribution is accompanied with this copyright notice and is not for commercial gain. Note: Binaries can only be used for non-commercial purposes.** If in doubt please contact the Kakadu Team at info@kakadusoftware.com.

## Author

Jason Ronallo

## License and Copyright

see MIT-LICENSE
