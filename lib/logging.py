import logging
from logstash_async.handler import AsynchronousLogstashHandler
from logstash_async.formatter import LogstashFormatter
from logging.config import fileConfig


fileConfig('lib/logging.cnf', disable_existing_loggers=True)
logger = logging.getLogger()

