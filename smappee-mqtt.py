#!/usr/bin/env python

import sys, os, requests, datetime, re, logging
import paho.mqtt.publish as publish
from ConfigParser import SafeConfigParser
from daemon import runner
from time import sleep

class SmappeeMQTT():
    def __init__(self):
        cfg = SafeConfigParser({"client_id": "smappee-mqtt-"+str(os.getpid()), "hostname": "localhost", "port": "1883", "auth": "False", "retain": "False", "qos": "0"})
        cfg.optionxform = str
        cfg.read("/etc/smappee-mqtt.conf")
        self.smappee = cfg.get("smappee", "hostname")
        self.client_id = cfg.get("mqtt", "client_id")
        self.host = cfg.get("mqtt", "hostname")
        self.port = eval(cfg.get("mqtt", "port"))
        self.topic = cfg.get("mqtt", "topic")
        self.topic_json = cfg.get("mqtt", "topic_json")
        self.qos = eval(cfg.get("mqtt", "qos"))
        self.delay = eval(cfg.get("mqtt", "delay"))
        self.retain = eval(cfg.get("mqtt", "retain"))
        if eval(cfg.get("mqtt", "auth")):
            self.auth = { "username": cfg.get("mqtt", "user"), "password": cfg.get("mqtt", "password") }
        else:
            self.auth = None
        self.stdin_path = '/dev/null'
        self.stdout_path = '/dev/null'
        self.stderr_path = '/dev/null'
        self.pidfile_path = '/var/run/smappee-mqtt.pid'
        self.pidfile_timeout = 5

    def run(self):
        reline = re.compile("<BR>\s*(\S+=.+?)<BR>")
        refield = re.compile(",\s+")
        last = None
        while True:
            while True:
                now = datetime.datetime.utcnow().second
                if last != now:
                    last = now
                    break
                sleep(self.delay)
            try:
                phaseCounter = 0
                response = requests.get("http://"+self.smappee+"/gateway/apipublic/reportInstantaneousValues")
                report = response.json()["report"]
                payload = "time:"+str(datetime.datetime.utcnow()).replace(" ","T")+"Z"
                payloadJ = "\"time\":\""+str(datetime.datetime.utcnow()).replace(" ","T")+"Z\""
                for line in re.findall(reline, report):
                    for field in re.split(refield, line):
                        payload += ",\""+field
                        payloadJ += ",\""+field
                        if "voltage" in field: #ugly hack to create array objects in jsonresponse..
                            payloadJ += ",\"phase\": [{"
                        if "phaseDiff" in field:
                            phaseCounter = phaseCounter + 1
                            if phaseCounter < 3:
                                payloadJ += "},{"

                #old version
                JsonPayload = "{\"elmaalerObject\": {" + payloadJ + "}]}}"
                #new version, not using the elmaalerObject. Change to make a simpler structure
                #JsonPayload = "{" + payloadJ + "}]}"
                JsonPayload = JsonPayload.replace("=","\":")
                JsonPayload = JsonPayload.replace(" Vrms","")
                JsonPayload = JsonPayload.replace("A","")
                JsonPayload = JsonPayload.replace(" W","")
                JsonPayload = JsonPayload.replace(" V","")
                JsonPayload = JsonPayload.replace(",\"cu","\"cu")
                JsonPayload = JsonPayload.replace(" var","")

                msgs = [ { "topic": self.topic_json, "payload": JsonPayload, "qos": self.qos, "retain": self.retain } ]
                publish.multiple(msgs, hostname=self.host, port=self.port, client_id=self.client_id, auth=self.auth)

                msgs = [ { "topic": self.topic, "payload": payload, "qos": self.qos, "retain": self.retain } ]
                publish.multiple(msgs, hostname=self.host, port=self.port, client_id=self.client_id, auth=self.auth)
            except Exception, e:
                logger.warning(e)
                pass

def main(argv=None):
    daemon = SmappeeMQTT()
    logger = logging.getLogger("smappee-mqtt")
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    handler = logging.FileHandler("/var/log/smappee-mqtt.log")
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.info("calling with param: " + argv[1]);
    daemon_runner = runner.DaemonRunner(daemon)
    daemon_runner.daemon_context.files_preserve=[handler.stream]
    daemon_runner.do_action()

if __name__ == "__main__":
    main(sys.argv)
