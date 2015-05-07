#!/usr/bin/env python

import os
from ConfigParser import SafeConfigParser
import paho.mqtt.publish as publish
import requests
from daemon import runner
import datetime
import re

class SmappeeMQTT():
    def __init__(self, smappee):
        self.smappee = smappee
        self.host = "localhost"
        self.port = 1883
        self.topic = "smappee/csv"
        self.qos = 0
        self.retain = False
        self.stdin_path = '/dev/null'
        self.stdout_path = '/dev/tty'
        self.stderr_path = '/dev/tty'
        self.pidfile_path = '/var/run/smappee-mqtt.pid'
        self.pidfile_timeout = 5

    def run(self):
        reline = re.compile("<BR>\s*(\S+=.+?)<BR>")
        refield = re.compile(",\s+")
        while True:
            try:
                response = requests.get("http://"+self.smappee+"/gateway/apipublic/reportInstantaneousValues")
                report = response.json()["report"]
                payload = "time="+str(datetime.datetime.utcnow()).replace(" ","T")+"Z"
                for line in re.findall(reline, report):
                    for field in re.split(refield, line):
                        payload += ","+field
                msgs = [ { "topic": self.topic, "payload": payload, "qos": self.qos, "retain": self.retain } ]
                publish.multiple(msgs, hostname=self.host, port=self.port, client_id="smappee-mqtt-"+str(os.getpid()))
            except Exception, e:
                pass

def main(argv=None):
    daemon = SmappeeMQTT("smappee")
    daemon_runner = runner.DaemonRunner(daemon)
    daemon_runner.do_action()

if __name__ == "__main__":
    main()

