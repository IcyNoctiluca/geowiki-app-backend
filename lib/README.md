## lib

This directory contains config files, classes and other functions called by the main applications.


```logging.cnf``` and ```logging.py``` are not implemented. The logging service is done via a standard python logger, I was not able to get a working version of a modular logging service with 
Logstash, but these files are the attempt that was made.

```validations.py``` contains checks used by the main applications

```geowiki.cnf``` and  ```config.py``` are the main configurations used by the applications

```DBGatekeeper.py``` is the class used by the writer to handle all DB access