# Mumbletune

MUMBLETUNE is an amiable bot that connects to a mumble server and allows users to interact with and play a queue of music. It currently plays music through Spotify.

## Installation

First, install Hexxeh's (spotify-websocket-api)[https://github.com/Hexxeh/spotify-websocket-api].

    git clone git://github.com/Hexxeh/spotify-websocket-api.git
    cd spotify-websocket-api
    python setup.py build
    puthon setup.py install

Then, add this line to your application's Gemfile:

    gem 'mumbletune'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mumbletune

## Usage

1. Create a configuration file. See `conf.example.yaml` for help.
2. Start Mumbletune, passing your config with `-c`.

		$ mumbletune -c config_file.yaml