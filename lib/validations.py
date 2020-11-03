from lib.config import *


# db gatekeeper validations #
# checks that given parameters are acceptable

def validate_table(_table):
    assert _table in ('continent', 'country', 'city'), 'Unacceptable table given!'
    return True


def validate_id_type(_id):
    assert type(_id) is int, 'Unacceptable ID type given!'
    return True


def validate_attr(_table, _attr):

    updatable_attributes = {
        'continent': config['updatable_attributes']['continent'].split(','),
        'country': config['updatable_attributes']['country'].split(','),
        'city': config['updatable_attributes']['city'].split(',')
    }
    assert _attr in updatable_attributes[_table], 'Unacceptable attribute for table given!'
    return True


def validate_attr_value(_value):
    assert type(_value) is int, 'Unacceptable attribute value!'
    return True


def determine_foreign_key(_table):
    if _table == 'country': return 'cont_id'
    elif _table == 'city':  return 'country_id'
    else: raise Exception(f'Could not determine the foreign key for table {_table}!')


# db writer validations #

def validate_action(parsed_message):
    #print (all(var is not None for var in [parsed_message['table']]))
    assert parsed_message['action'] in ('INSERT', 'UPDATE', 'DELETE'), 'Invalid operation requested!'
    assert all(var is not None for var in [parsed_message['table']]), 'No table given in request!'
    return True


def validate_client_id(parsed_message):
    #print (all(var is not None for var in [parsed_message['client_id']]))
    assert all(var is not None for var in [parsed_message['client_id']]), 'No client ID given in request!'
    return True

def validate_message_id(parsed_message):
    #print (all(var is not None for var in [parsed_message['request_id']]))
    assert all(var is not None for var in [parsed_message['request_id']]), 'No message ID given in request!'
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