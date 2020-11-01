from lib.DBGatekeeper import DBGatekeeper
from aiokafka import AIOKafkaConsumer, AIOKafkaProducer
import asyncio
from lib.config import *
import json


def validate_action(parsed_message):
    #print (all(var is not None for var in [parsed_message['table']]))
    assert parsed_message['action'] in ('INSERT', 'UPDATE', 'DELETE'), 'Invalid operation requested!'
    assert all(var is not None for var in [parsed_message['table']]), 'No table given in request!'
    return True


def validate_client_id(parsed_message):
    #print (all(var is not None for var in [parsed_message['client_id']]))
    assert all(var is not None for var in [parsed_message['client_id']]), 'No client ID given in request!'
    return True


def validate_insert(parsed_message):
    #print (var is not None for var in [parsed_message['name'], parsed_message['parent_id']])
    assert all(var is not None for var in [parsed_message['name'], parsed_message['parent_id']]), 'Invalid parameters given for operation!'
    return True


def validate_update(parsed_message):
    #print (all(var is not None for var in [parsed_message['id'], parsed_message['attribute'], parsed_message['value']]))
    assert all(var is not None for var in [parsed_message['id'], parsed_message['attribute'], parsed_message['value']]), 'Invalid parameters given for operation!'
    return True


def validate_delete(parsed_message):
    #print (all(var is not None for var in [parsed_message['id']]))
    assert all(var is not None for var in [parsed_message['id']]), 'Invalid parameters given for operation!'
    return True


async def send_callback(client_id, resp):

    producer = AIOKafkaProducer(
        loop=loop,
        bootstrap_servers=config['broker_topics']['server']
    )

    await producer.start()

    # Produce message
    try:
        await producer.send_and_wait(
            config['broker_topics']['topic'],
            key=client_id.encode(),
            value=resp.encode()
        )

    finally:
        # Wait for all pending messages to be delivered or expire.
        await producer.stop()


async def handle_message(msg):

    global gatekeeper
    #print(msg.value.decode())

    try:
        parsed_message = json.loads(msg.value.decode())

        validate_action(parsed_message)
        validate_client_id(parsed_message)

        if parsed_message['action'] == 'INSERT':

            assert validate_insert(parsed_message)
            gatekeeper.insert(parsed_message['table'], parsed_message['name'], parsed_message['parent_id'])

        elif parsed_message['action'] == 'UPDATE':

            assert validate_update(parsed_message)
            gatekeeper.update(parsed_message['table'], parsed_message['id'], parsed_message['attribute'], parsed_message['value'])

        elif parsed_message['action'] == 'DELETE':

            assert validate_delete(parsed_message)
            gatekeeper.delete(parsed_message['table'], parsed_message['id'])

        resp = gatekeeper.status

    except Exception as e:
        resp = f'Handling of message failed: {e}'

    finally:
        client_id = parsed_message['client_id']
        _ = asyncio.ensure_future(send_callback(client_id, resp))


async def writer_main():

    consumer = AIOKafkaConsumer(
        config['broker_topics']['topic'],  # topic
        loop=loop,
        bootstrap_servers=config['broker_topics']['server']
    )

    await consumer.start()

    try:
        # Consume messages
        async for msg in consumer:

            print("Received: ", msg.topic, msg.key, msg.value, msg.timestamp)

            if not(msg.key.decode() == '1'):
                continue

            #print("Received: ", msg.topic, msg.key, msg.value, msg.timestamp)

            # pass the message to be handled by the writer depending on the type
            _ = asyncio.ensure_future(handle_message(msg))

    finally:
        await consumer.stop()


if __name__ == '__main__':

    # writer startup

    # create new DB gatekeeper object
    gatekeeper = DBGatekeeper(
        config['DB_credentials']['user'],
        config['DB_credentials']['password'],
        config['DB_credentials']['host'],
        config['DB_credentials']['database']
    )

    # connect to DB
    gatekeeper.connect()
    if not(gatekeeper.is_connected):
        raise Exception(gatekeeper.status)

    # execute main writer function
    loop = asyncio.get_event_loop()
    loop.run_until_complete(writer_main())
