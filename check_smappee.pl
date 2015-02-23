#!/usr/bin/perl
 
# Nagios plugin for monitoring Smappee device version etc.
 
# For opsview
use lib '/usr/local/nagios/perl/lib', '/usr/local/nagios/lib';
 
use warnings;
use strict;
use Nagios::Plugin;
use LWP::UserAgent;
use HTTP::Request;
use JSON::PP;
use Data::Dumper;
 
my $VERSION = "0.01";
 
my $np = Nagios::Plugin->new(
  usage   => "Usage: %s -h host -p password [-v] [--app version] [-acq version] [--os version]",
  version => $VERSION,
  blurb   => "Checks Smappee status and versions",
);
 
$np->add_arg(
    spec => "host|h=s",
    help => qq{-h, --host=STRING
       Host name (or IP address) of Smappee device},
    required => 1
);
 
$np->add_arg(
    spec => "app=s",
    help => qq{--app=STRING
       Expected application software version and build nr},
    default => "",
);
 
$np->add_arg(
    spec => "acq=s",
    help => qq{--acq=STRING
       Expected acquisition software version},
    default => "",
);
 
$np->add_arg(
    spec => "os=s",
    help => qq{--os=STRING
       Expected OS build nr},
    default => "",
);
 
$np->add_arg(
    spec => "password|p=s",
    help => qq{-p, --password=STRING
       Smappee password},
    required => 1
);
 
$np->add_arg(
    spec => "verbose|v",
    help => qq{-v, --verbose
       Verbose},
);
 
$np->getopts;

# Logon
my $ua = LWP::UserAgent->new;
my $request = HTTP::Request->new(POST => 'http://' . $np->opts->host . '/gateway/apipublic/logon');
$request->content($np->opts->password);
$request->header('Content-Type' => 'application/json');
my $response = $ua->request($request);
if (!$response->is_success) {
  print "Smappee Logon request/response: " . Dumper($ua) if ($np->opts->verbose);
  $np->nagios_exit(CRITICAL, "Unable to logon to Smappee at '" . $np->opts->host . "': " . $response->status_line);
}
print "Smappee Logon response: " . $response->content if ($np->opts->verbose);

# System info / statistics
$response = $ua->get('http://' . $np->opts->host . '/gateway/apipublic/statisticsPublicReport');
if (!$response->is_success) {
  print "Smappee Data request/response: " . Dumper($ua) if ($np->opts->verbose);
  $np->nagios_exit(CRITICAL, "Unable to obtain Smappee status from '" . $np->opts->host . "': " . $response->status_line);
}
print "Smappee Data response: " . $response->content if ($np->opts->verbose);

# Parse response
my $status = decode_json $response->content;
my %info;
foreach my $s (@$status) {
  next if (!defined($$s{'value'}));
  $info{$$s{'key'}} = $$s{'value'};
  chomp $info{$$s{'key'}};
}
if (keys %info < 10) {
  $np->nagios_exit(CRITICAL, "Unable to obtain Smappee status from '" . $np->opts->host . "': " . $response->content);
}

# Check status
$status = 'Smappee Link/Sigs: ' . $info{'Link quality'}
	. ' / ' . $info{'Nr of signatures received from acquisition engine'}
	. ', App/Acq/OS: ' . $info{'Application software version and build nr'}
	. ' / ' . $info{'Acquisition Software version'}
	. ' / ' . $info{'OS build nr'};
$np->nagios_exit(WARNING, '(OS) ' . $status) if ($np->opts->os && $np->opts->os ne $info{'OS build nr'});
$np->nagios_exit(WARNING, '(App) ' . $status) if ($np->opts->app && $np->opts->app ne $info{'Application software version and build nr'});
$np->nagios_exit(WARNING, '(Acq) ' . $status) if ($np->opts->acq && $np->opts->acq ne $info{'Acquisition Software version'});

$np->nagios_exit(OK, $status);
