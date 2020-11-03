# logs

This directory contains the raw log files for the main applications. Each client has a random ID
assigned to it. This ID is appended to the log file of its application.

The logging service is done via a standard python logger, I was not able to get a working version of a modular logging service with 
Logstash.