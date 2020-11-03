# geowiki-app-backend

An instance of the writer application is made by executing ```writer.py```, and a client by ```client.py```. 

While multiple client instances may be made, only a single server application is needed since it handles requests concurrently.

#### Prerequisites

Python libraries from ```requirements.txt```

###### Kafka 
* https://kafka.apache.org/downloads 
* Version 2.6 used for development
* Requires service to be running with commands in seperate terminals: 

```
bin/zookeeper-server-start.sh config/zookeeper.properties

bin/kafka-server-start.sh config/server.properties
```

Messages are handled under the topic ```geowiki```, made by executing:
```
bin/kafka-topics.sh --create --topic quickstart-events --bootstrap-server localhost:9092
```

###### MySQL server 
* Version 14.14 used for development
* Upon running, ```lib/geowiki.sql``` can be executed in SQL terminal to create user, tables etc.


### Implementation Details
