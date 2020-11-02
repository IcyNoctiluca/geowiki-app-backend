from aiokafka import AIOKafkaProducer, AIOKafkaConsumer
import asyncio
import random
import json
from faker import Faker
from lib.config import *
import logging


def generate_request():

    global local_client_id
    request_id = str(random.randint(0,100000))

    action = random.choice(['INSERT', 'UPDATE', 'DELETE'])

    updatable_attributes = {
        'continent': config['updatable_attributes']['continent'].split(','),
        'country': config['updatable_attributes']['country'].split(','),
        'city': config['updatable_attributes']['city'].split(',')
    }

    logging.debug(f'updatable_attributes: {updatable_attributes}')

    table = random.choice(['continent', 'country', 'city'])

    if action == 'INSERT':

        fake = Faker()
        return json.dumps({
            'client_id': local_client_id,
            'request_id': request_id,
            'action': action,
            'table': 'city',
            'name': fake.city(),
            'parent_id': random.randint(1, 125)
        })

    elif action == 'UPDATE':

        return json.dumps({
            'client_id': local_client_id,
            'request_id': request_id,
            'action': action,
            'table': table,
            'attribute': random.choice(updatable_attributes[table]),
            'value': random.randint(1, 1000000),
            'id': random.randint(1, 100)
        })

    elif action == 'DELETE':

        return json.dumps({
            'client_id': local_client_id,
            'request_id': request_id,
            'action': action,
            'table': 'city',
            'id': random.randint(1, 800)
        })


async def client_send_update():

    producer = AIOKafkaProducer(
        loop=loop,
        bootstrap_servers=config['broker_topics']['server']
    )

    await producer.start()
    logging.debug(f'AIOKafkaProducer started')

    while True:

        db_request = await loop.run_in_executor(None, generate_request)
        logging.debug(f'Random request generated to be sent: {db_request}')

        try:
            key = str(1)
            await producer.send_and_wait(
                config['broker_topics']['topic'],
                key=key.encode(),
                value=db_request.encode()
            )
            logging.info(f'AIOKafkaProducer Sending: key {key} value {db_request}')

        finally:
            # Wait for all pending messages to be delivered or expire.
            logging.info(f'AIOKafkaProducer going to sleep for 1 second')
            await asyncio.sleep(1)

    await producer.stop()
    logging.debug(f'AIOKafkaProducer stopped')



async def client_receive_callback():

    global local_client_id

    consumer = AIOKafkaConsumer(
        config['broker_topics']['topic'],  # topic
        loop=loop,
        bootstrap_servers=config['broker_topics']['server']
    )

    await consumer.start()
    logging.debug(f'AIOKafkaConsumer started')

    try:
        # Consume messages
        async for msg in consumer:

            if not(msg.key.decode() == local_client_id):
                continue

            #print("Received: ", msg.topic, msg.key, msg.value, msg.timestamp)

            serialised_message = 'topic=' + msg.topic + '|key=' + msg.key.decode() + '|value=' + msg.value.decode() + '|timestamp=' + str( msg.timestamp)

            logging.info(f'AIOKafkaConsumer Received: {serialised_message}')

    finally:
        await consumer.stop()
        logging.debug('AIOKafkaConsumer stopped')


if __name__ == '__main__':

    # client startup #

    # assign local id to the executing client
    local_client_id = str(random.randint(10000000, 100000000))

    # initialise logging
    logging.basicConfig(
        filename=f'logs/client_{local_client_id}.log',
        format='%(asctime)s%(msecs)03d - %(message)s',
        datefmt='%s',
        level=logging.INFO
    )
    logging.info(f'Client initialised with ID {local_client_id}')

    # logging.error('python-logstash-async: test logstash error message.')
    # logging.info('python-logstash-async: test logstash info message.')
    # logging.warning('python-logstash-async: test logstash warning message.')

    # start asynchronous loops of main client execution
    loop = asyncio.get_event_loop()

    logging.debug('Creating task client_send_update')
    loop.create_task(client_send_update())

    logging.debug('Creating task client_receive_callback')
    loop.create_task(client_receive_callback())

    logging.debug('Running async loop forever')
    loop.run_forever()
