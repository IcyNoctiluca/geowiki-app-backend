## loads config file as a global variable to be imported by the applications

import configparser
CONFIG_SOURCE = 'lib/geowiki.cnf'
config = configparser.ConfigParser()
config.read(CONFIG_SOURCE)
