#!/bin/bash

# Script that open terminals for executing things
gnome-terminal -e "node camada_aplicacao/server.js"
gnome-terminal -e "python camada_tranporte/server.py"
gnome-terminal -e "ruby camada_rede/server.rb"
gnome-terminal -e "ruby camada_rede/client.rb"
gnome-terminal -e "lua camada_fisica/server.lua"
gnome-terminal -e "lua camada_fisica/client.lua"

# sudo apt-get install lua5.1
# sudo apt-get install luarocks
# luarocks install luasocket
# sudo apt-get install nodejs-legacy
# sudo apt-get install ruby-full
