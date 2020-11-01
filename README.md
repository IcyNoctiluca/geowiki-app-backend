# geowiki-app-backend


bin/zookeeper-server-start.sh config/zookeeper.properties

bin/kafka-server-start.sh config/server.properties


### reader

bin/kafka-console-consumer.sh --topic geowiki --from-beginning --bootstrap-server localhost:9092


### writer

bin/kafka-console-producer.sh --topic geowiki --bootstrap-server localhost:9092




