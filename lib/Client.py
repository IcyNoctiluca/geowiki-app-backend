import random

class Client:

    def __init__(self):
        self.local_db_state = None


    def set_new_state(self, new_state):
        pass

    def update_recieved_state(self, received_state):
        pass

    def generate_random_sql():

        insert_query_continent = 'INSERT INTO ? () VALUES ()'
        update_query = 'UPDATE ? SET ? = ? WHERE id = ?'
        delete_query = 'DETELE FROM ? WHERE id = ?'


    async def send_message(self):


        producer = AIOKafkaProducer(
            loop=loop,
            bootstrap_servers='localhost:9092'
        )