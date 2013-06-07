# Mumbletune

MUMBLETUNE is a nice bot that connects to a mumble server and allows users to listen to Spotify together.

## Installation

What you need:
- A Spotify Premium account. I wish it didn't have to be this way, but for API access, Premium's required
- A Spotify App Key. Spotify will issue you one [here][1]. 

Clone this repo and install its dependencies

    $ git clone git://github.com/elliottwilliams/mumbletune.git
    cd mumbletune
    bundle install

## Usage

1. Create a configuration file. See `conf.example.yaml` for help.
2. Start Mumbletune, passing your config with `-c`.

		$ mumbletune -c config_file.yaml

[1]: https://developer.spotify.com/technologies/libspotify/keys/