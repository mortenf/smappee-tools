Smappee Tools
=============

This is a - small, possibly growing - collection of tools for working with a [Smappee](http://smappee.com/).

Currently the collection consists of a Nagios plugin and a data logger.

## check_smappee.pl

A [Nagios](http://www.nagios.org/) plugin that can monitor the status of a Smappee through its builtin web interface, including information and possible alerts when the Smappee has been upgraded (when the OS version or build number changes).

### Usage

`./check_smappee.pl --host $ARG1$ --password $ARG2$ --app "1.0.0S buildNr #994" --acq 1.78 --os 8`

### Sample Output

`SMAPPEE OK - Smappee Link/Sigs: 65/70  / 172873, App/Acq/OS: 1.0.0S buildNr #994 / 1.78 / 8`

## smappee-client.pl

A script that (currently) can save the current power consumption status variable to a CSV file. The script can be started in daemon mode, automatically saving the status every two seconds (or less often).

### Usage

`./smappee-client.pl $HOST values -t -d 2>> smappee-error.log | cronolog smappee-%Y-%m-%d.csv &`

### Sample Output

`time,voltage,current1,activePower1,reactivePower1,apparentPower1,cosfi1,quadrant1,phaseshift1,phaseDiff1,current2,activePower2,reactivePower2,apparentPower2,cosfi2,quadrant2,phaseshift2,phaseDiff2,current3,activePower3,reactivePower3,apparentPower3,cosfi3,quadrant3,phaseshift3,phaseDiff3`
`2014-11-06T00:17:17+0100,230.1,1.516,334.013,101.216,349.012,95,0,0.0,0.0,0.007,1.246,1.025,1.614,61,0,0.0,0.0,0.627,144.138,7.893,144.354,99,0,0.0,0.0`
`Vrms,A,W,var,VA,,,,,A,W,var,VA,,,,,A,W,var,VA,,,,`

## License

This collection is provided under the GPL License.

## Contribution

Please do!
