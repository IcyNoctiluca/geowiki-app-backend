# geowiki application backend

An instance of the writer application is made by executing ```writer.py```, and a client by ```client.py```. 

While multiple client instances may be made, only a single server application is needed since it handles requests concurrently.

#### Prerequisites

Python3.6.9 using libraries from ```requirements.txt```

###### Kafka 
* https://kafka.apache.org/downloads (tar file in ```lib/```)
* Version 2.6 used for development
* Requires service to be running with commands in seperate terminals: 

```
bin/zookeeper-server-start.sh config/zookeeper.properties

bin/kafka-server-start.sh config/server.properties
```

Messages are handled under the topic ```geowiki```, made by executing:
```
bin/kafka-topics.sh --create --topic geowiki --bootstrap-server localhost:9092
```

###### MySQL server 
* Version 14.14 used for development
* Upon running, ```db/geowiki.sql``` can be executed in SQL terminal to create user, tables etc.


#### Design & Implementation Details

###### Client
The client application needed to be implemented in an asynchronous manner in order to both send requests and 
receive callbacks concurrently. Therefore two functions, ```client_send_update``` and ```client_receive_callback```,
are implemented directly in the script and are run indefinitely during execution. These routines need to be separate, since they are both asynchronously processing different messages in some way. 

While it would have been possible to implement a client class and build in the required subroutines, the two main processes of the client are not
very similar in structure, nor containing many shared variables. Therefore using an object-oriented approach would have
hindered more than it helped.

```client_send_update``` generates a random request to send to the writer. It was decided to limit the types of random requests which the
client could make to avoid massive changes to the data tables. For example, clients cannot request for continents to be deleted, since the
underlying countries and cities would also be removed. Alternatively this could have been achieved with user permissions revoking access 
on the tables, but the broker being spammed with a lot of rejected requests in the messages. One field
included in the request is a message ID, which allows the client to keep track of sent requests since the callback
from the writer also contains this field.

###### Writer
Given the main function of the writer is to manipulate the tables based on incoming requests, it was decided to use a class to 
encompass all requests going to the DB. This means that the connection to the DB can remain open indefinitely, since periodically
calling a subroutine to make an alteration would require opening and closing a DB session. Consequently, requests can be processed much more quickly.

The writer functionalities include the receiving of messages ```writer_main```, the processing thereof ```handle_message```, and then sending a callback ```send_callback``` 
to the underlying client based on the message handling.
Similar to the client design, a writer class was not implemented due to lack of shared components of the writers functionalities.

\
\
One major limitation of the client is that it does not have any knowledge of the existing data, with updates requests being generated
by hard-coded random parameters. An improvement to the setup would be for the client to request the table entries upon startup, and
then keep a local state of the tables which would be further maintained by listening in on the messages broadcasted by the writer.


#### Running in the Cloud
Using a single DB and writer cause instability if the application is overloaded with a lot of client requests. A more appropriate way would be to deploy replicated DBs
and writer applications. A master and slave setup would not suffice since the master would still be overloaded, therefore
an active replication would be a better model to implement. This would improve robustness, but such a deployment would require load-balancing on the side of
the writer applications. Better use of Kafka should be made to use rules to redirect messages so specific writers for example, based on their current load,
which would improve their stability.

Furthermore, in the cloud, the writer application would receive a lot of 'spam' messages, since it receives the callbacks that it sends to clients. Using 
multiple Kafka topics, such as ```geowiki-client``` or ```geowiki-writer``` would allow the applications to filter what they are receiving.
