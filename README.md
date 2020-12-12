Smappee Tools
=============

This is a - small, possibly growing - collection of tools for working with a [Smappee](http://smappee.com/).

Currently the collection consists of a Nagios plugin, a CSV data logger and an MQTT logger.

## check_smappee.pl

A [Nagios](http://www.nagios.org/) plugin that can monitor the status of a Smappee through its builtin web interface, including information and possible alerts when the Smappee has been upgraded (when the OS version or build number changes).

### Usage

```bash
./check_smappee.pl --host $ARG1$ --password $ARG2$ --app "1.0.0S buildNr #994" --acq 1.78 --os 8
```

### Sample Output

```
SMAPPEE OK - Smappee Link/Sigs: 65/70  / 172873, App/Acq/OS: 1.0.0S buildNr #994 / 1.78 / 8
```

## smappee-client.pl

A script that (currently) can save the current power consumption status variables to a CSV file. The script can be started in daemon mode, automatically saving the status every two seconds (or less often).

### Usage

```bash
./smappee-client.pl $HOST values -t -d 2>> smappee-error.log | cronolog smappee-%Y-%m-%d.csv &
```

### Sample Output

```
time,voltage,current1,activePower1,reactivePower1,apparentPower1,cosfi1,quadrant1,phaseshift1,phaseDiff1,current2,activePower2,reactivePower2,apparentPower2,cosfi2,quadrant2,phaseshift2,phaseDiff2,current3,activePower3,reactivePower3,apparentPower3,cosfi3,quadrant3,phaseshift3,phaseDiff3
2014-11-06T00:17:17+0100,230.1,1.516,334.013,101.216,349.012,95,0,0.0,0.0,0.007,1.246,1.025,1.614,61,0,0.0,0.0,0.627,144.138,7.893,144.354,99,0,0.0,0.0
Vrms,A,W,var,VA,,,,,A,W,var,VA,,,,,A,W,var,VA,,,,
```

## smappee-mqtt.py

A daemon script that publishes the current power consumption status variables to an MQTT broker every second.
Publishes in raw format and in json (in /json topic)
Authorization must be handled externally, e.g. by running the above Nagios check every 5 minutes or so.

### Usage

```bash
./smappee-mqtt.py start
```

### Sample Configuration

```
[smappee]
hostname = smappee

[mqtt]
hostname = localhost
port = 1883
topic = device/smappee/in/raw
topic_json = device/smappee/in/json
qos = 0
delay = 0.6
retain = False
auth = True
user = test
password = test
```

### Sample Raw Payload

```
time=2015-05-07T21:48:44.047870Z,voltage=235.4 Vrms,current=1.456 A,activePower=309.015 W,reactivePower=148.588 var,apparentPower=342.883 VA,cosfi=90,quadrant=0,phaseshift=0.0,phaseDiff=0.0,current=0.007 A,activePower=1.442 W,reactivePower=0.82 var,apparentPower=1.659 VA,cosfi=60,quadrant=0,phaseshift=0.0,phaseDiff=0.0,current=0.454 A,activePower=105.698 W,reactivePower=16.44 var,apparentPower=106.969 VA,cosfi=98,quadrant=0,phaseshift=0.0,phaseDiff=0.0
```


### Sample JSON Payload

```
{"time":"2020-12-12T19:25:21.401288Z","voltage":232.5,"phase": [{"current":3.948 ,"activePower":915.89,"reactivePower":64.509,"apparentPower":918.159,"cosfi":99,"quadrant":0,"phaseshift":0.0,"phaseDiff":0.0},{"current":11.451 ,"activePower":2663.387,"reactivePower":0.0,"apparentPower":2663.147,"cosfi":99,"quadrant":0,"phaseshift":0.0,"phaseDiff":0.0},{"current":1.074 ,"activePower":187.665,"reactivePower":165.002,"apparentPower":249.888,"cosfi":74,"quadrant":0,"phaseshift":0.0,"phaseDiff":0.0}]}
```


## License

This collection is provided under the GPL License.

## Contribution

Please do!
