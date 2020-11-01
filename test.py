async def client_send_update():

    producer = AIOKafkaProducer(
        loop=loop,
        bootstrap_servers='localhost:9092'
    )

    await producer.start()

    while True:

        await asyncio.sleep(2)
        print('going to send smt')


async def client_recieve_callback():
    global config

    consumer = AIOKafkaConsumer(
        config['broker_topics']['topic'],  # topic
        loop=loop,
        bootstrap_servers='localhost:9092'
    )

    await consumer.start()

    try:

        async for msg in consumer:

            print("Received: ", msg.topic, msg.partition, msg.offset, msg.key, msg.value, msg.timestamp)

            # skip if the message key is not meant for the writer
            if not (msg.key == config['broker_topics']['writer_key']):
                continue

    finally:
        await consumer.stop()


async def get_initial_db_state():

    producer = AIOKafkaProducer(
        loop=loop,
        bootstrap_servers='localhost:9092'
    )

    # Produce message
    try:

        await asyncio.gather(
            producer.send_and_wait("geowiki", key=b'2', value='GET_STATE_cont'.encode()),
            producer.send_and_wait("geowiki", key=b'2', value='GET_STATE_country'.encode()),
            producer.send_and_wait("geowiki", key=b'2', value='GET_STATE_city'.encode())
        )
    finally:
        # Wait for all pending messages to be delivered or expire.
        await producer.stop()

