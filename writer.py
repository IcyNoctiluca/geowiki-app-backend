from lib.DBGatekeeper import DBGatekeeper
from aiokafka import AIOKafkaConsumer, AIOKafkaProducer
import asyncio
from lib.validations import *
import json
import logging

# send a callback to the client with a given ID
async def send_callback(client_id, resp):

    producer = AIOKafkaProducer(
        loop=loop,
        bootstrap_servers=config['broker_topics']['server']
    )

    await producer.start()
    logging.debug('AIOKafkaProducer started')

    # Produce message
    try:
        # ensure the key of the message is the client ID, so the client can identify its message
        await producer.send_and_wait(
            config['broker_topics']['topic'],
            key=client_id.encode(),
            value=resp.encode()
        )
        logging.info(f'Sent callback to client {client_id}!')


    finally:
        await producer.stop()
        logging.debug('AIOKafkaProducer stopped')


# main routine for parsing the clients request and sending it to the DB for processing
async def handle_message(msg):

    global gatekeeper
    await asyncio.sleep(5)

    try:
        logging.debug('Parsing message')
        parsed_message = json.loads(msg.value.decode())

        # validate fields in message
        validate_action(parsed_message)
        validate_client_id(parsed_message)
        validate_message_id(parsed_message)

        request_id = parsed_message['request_id']

        # send message to DB depending on action requested #

        if parsed_message['action'] == 'INSERT':

            logging.debug('Validating of insert type message')
            assert validate_insert(parsed_message)
            gatekeeper.insert(parsed_message['table'], parsed_message['name'], parsed_message['parent_id'])

        elif parsed_message['action'] == 'UPDATE':

            logging.debug('Validating of udpate type message')
            assert validate_update(parsed_message)
            gatekeeper.update(parsed_message['table'], parsed_message['id'], parsed_message['attribute'], parsed_message['value'])

        elif parsed_message['action'] == 'DELETE':

            logging.debug('Validating of delete type message')
            assert validate_delete(parsed_message)
            gatekeeper.delete(parsed_message['table'], parsed_message['id'])

        # get request response from the gatekeeper for sending back to the client
        resp = gatekeeper.status
        logging.info(f'DB action message ID {request_id} successful! {resp}')

    except Exception as e:
        logging.error(f'Handling of message ID {request_id} failed: {e}')
        resp = f'Handling of message failed: {e}'

    finally:

        # prepare message to be sent back to the client
        client_id = parsed_message['client_id']
        return_message = str({
            'request_id': parsed_message['request_id'],
            'response': resp
        })

        # send response back to client via callback function
        logging.info(f'Processing callback for message id {request_id} to client {client_id}')
        _ = asyncio.ensure_future(send_callback(client_id, return_message))


# receive messages from client, and send to handler
async def writer_main():

    consumer = AIOKafkaConsumer(
        config['broker_topics']['topic'],  # topic
        loop=loop,
        bootstrap_servers=config['broker_topics']['server']
    )

    await consumer.start()
    logging.debug('AIOKafkaConsumer started')

    try:

        # get the key so the writer knows which messages to look for
        writer_key = config['broker_topics']['writer_key']

        # Consume messages
        async for msg in consumer:
            
            serialised_message = 'topic=' + msg.topic + '|key=' + msg.key.decode() + '|value=' + msg.value.decode() + '|timestamp=' + str( msg.timestamp)

            # check if writer was supposed to receive the message using the key
            if not(msg.key.decode() == writer_key):
                logging.warning(
                    f'DB received message not meant for DB, probably meant for client. Ignoring: {serialised_message}')
                continue

            logging.info(f'DB received message {serialised_message}, sending received message to handler')

            # pass the message to be handled by the writer depending on the type
            _ = asyncio.ensure_future(handle_message(msg))

    finally:
        await consumer.stop()
        logging.debug('AIOKafkaConsumer stopped')


if __name__ == '__main__':

    # writer startup #

    # initialise logging
    logging.basicConfig(
        filename=f'logs/writer.log',
        format='%(asctime)s%(msecs)03d - %(message)s',
        datefmt='%s',
        level=logging.INFO
    )
    logging.info('Writer initialised')

    logging.debug(f'config file dump {config}')

    # create new DB gatekeeper object
    gatekeeper = DBGatekeeper(
        config['DB_credentials']['user'],
        config['DB_credentials']['password'],
        config['DB_credentials']['host'],
        config['DB_credentials']['database']
    )
    logging.debug('Initialised DBGatekeeper with credentials')

    # connect to DB
    logging.debug('Connecting to DB via gatekeeper')
    gatekeeper.connect()
    if not(gatekeeper.is_connected):
        logging.error('Could not connect to DB! Raising exception')
        raise Exception(gatekeeper.status)


    # execute main writer function
    loop = asyncio.get_event_loop()
    
    logging.info('Running main writer execution loop')
    loop.run_until_complete(writer_main())
