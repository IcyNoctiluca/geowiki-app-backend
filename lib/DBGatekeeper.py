from mysql.connector import (connection)
import json
from lib.validations import *


class DBGatekeeper:

    def __init__(self, _user, _password, _host, _database):

        self.user = _user
        self.password = _password
        self.host = _host
        self.database = _database
        self.cnx = connection.MySQLConnection()

        self.status = None
        self.is_connected = False


    def connect(self):

        try:
            self.cnx.connect(
                user=self.user,
                password=self.password,
                host=self.host,
                database=self.database
            )
            self.status = 'Connection to DB successful!'
            self.is_connected = True

        except Exception as err:
            self.status = f'Connection DB failed: {err}'
            self.is_connected = False


    def get_table_state(self, _table):

        assert validate_table(_table)

        cursor = self.cnx.cursor()
        cursor.execute(f'''
            SELECT * FROM {_table};
        ''')

        headers = [x[0] for x in cursor.description]
        raw_data = cursor.fetchall()
        json_data = [dict(zip(headers, result)) for result in raw_data]

        return json.dumps(json_data, indent=4, sort_keys=True, default=str)


    def delete(self, _table, _id):

        assert validate_table(_table)
        assert validate_id_type(_id)

        cursor = self.cnx.cursor(prepared = True)

        query = (f'''
            DELETE FROM {_table} WHERE id = %s;
        ''')

        try:
            cursor.execute(query, (_id,))
            self.cnx.commit()
            self.status = "{} record(s) deleted".format(cursor.rowcount)

        except Exception as err:
            self.status = f"Failed to delete: {err}"


    def update(self, _table, _id, _attr, _value):

        assert validate_table(_table)
        assert validate_id_type(_id)
        assert validate_attr(_table, _attr)
        assert validate_attr_value(_value)

        cursor = self.cnx.cursor(prepared = True)

        query = (f'''
            UPDATE {_table} SET {_attr} = %s WHERE id = %s;
        ''')

        try:
            cursor.execute(query, (_value, _id,))
            self.cnx.commit()
            self.status = "{} record(s) updated".format(cursor.rowcount)

        except Exception as err:
            self.status = f"Failed to update: {err}"


    def insert(self, _table, _name, _parent_id):

        assert validate_table(_table)
        assert validate_id_type(_parent_id)

        parent_id_type = determine_foreign_key(_table)

        cursor = self.cnx.cursor(prepared=True)

        query = (f'''
            INSERT INTO {_table} (name, {parent_id_type}) VALUES (%s, %s)
        ''')

        try:
            cursor.execute(query, (_name, _parent_id))
            self.cnx.commit()
            self.status = "{} record(s) inserted".format(cursor.rowcount)

        except Exception as err:
            self.status = f"Failed to insert: {err}"

