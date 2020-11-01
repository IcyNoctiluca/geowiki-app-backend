from aiokafka import AIOKafkaProducer, AIOKafkaConsumer
import asyncio
from lib.Client import Client
import random
import json
from faker import Faker
from lib.config import *


def generate_request():

    global local_client_id

    action = random.choice(['INSERT', 'UPDATE', 'DELETE'])

    updatable_attributes = {
        'continent': config['updatable_attributes']['continent'].split(','),
        'country': config['updatable_attributes']['country'].split(','),
        'city': config['updatable_attributes']['city'].split(',')
    }

    table = random.choice(['continent', 'country', 'city'])

    if action == 'INSERT':

        fake = Faker()
        return json.dumps({
            'client_id': local_client_id,
            'action': action,
            'table': 'city',
            'name': fake.city(),
            'parent_id': random.randint(1, 125)
        })

    elif action == 'UPDATE':

        return json.dumps({
            'client_id': local_client_id,
            'action': action,
            'table': table,
            'attribute': random.choice(updatable_attributes[table]),
            'value': random.randint(1, 1000000),
            'id': random.randint(1, 100)
        })

    elif action == 'DELETE':

        return json.dumps({
            'client_id': local_client_id,
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

    while True:

        db_request = await loop.run_in_executor(None, generate_request)
        print(db_request)

        try:
            await producer.send_and_wait(
                config['broker_topics']['topic'],
                key=str(1).encode(),
                value=db_request.encode()
            )

        finally:
            # Wait for all pending messages to be delivered or expire.
            await asyncio.sleep(1)

    await producer.stop()




async def client_receive_callback():

    pass


if __name__ == '__main__':

    local_client_id = str(random.randint(10000000,100000000))

    # await get_initial_db_state(producer)

    # client startup
    loop = asyncio.get_event_loop()
    loop.create_task(client_send_update())
    loop.create_task(client_receive_callback())
    loop.run_forever()
