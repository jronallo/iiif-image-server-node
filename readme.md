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

Once the provisioner runs you'll still need to run `sudo scripts/install-kdu.sh` to install the Kakadu binaries and complete the installation (then logout and back in).

Then visit <http://localhost:8088/index.html?id=trumpler14>

## Author

Jason Ronallo

## License and Copyright

see MIT-LICENSE
