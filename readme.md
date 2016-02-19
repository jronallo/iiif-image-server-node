# IIIF Image Server in Node

Simple example IIIF Image server written in Node to show the use of the `iiif-image` module.

## Usage

```sh
npm i
npm start
```

In your browser visit <http://localhost:3000/index.html?id=trumpler14>

## Development

In one terminal run `npm run compile` to compile the Coffeescript.

In another terminal run `nodemon` to restart the server on changes.

## Vagrant

Currently dependencies are installed with ansible roles from a private repository. These roles install nodejs and passenger. We're working to make this repository public.

Once everything is installed you can visit: <http://localhost:8088/index.html?id=trumpler14>

## Kakadu Copyright Notice and Disclaimer
 We do not distribute the Kakadu executables. You will need to install the Kakadu binaries/executables available [here](http://kakadusoftware.com/downloads/). The executables available there are made available for demonstration purposes only. Neither the author, Dr. Taubman, nor UNSW Australia accept any liability arising from their use or re-distribution.

That site states:

> Copyright is owned by NewSouth Innovations Pty Limited, commercial arm of the UNSW Australia in Sydney. **You are free to trial these executables and even to re-distribute them, so long as such use or re-distribution is accompanied with this copyright notice and is not for commercial gain. Note: Binaries can only be used for non-commercial purposes.** If in doubt please contact the Kakadu Team at info@kakadusoftware.com.

## Author

Jason Ronallo

## License and Copyright

see MIT-LICENSE
