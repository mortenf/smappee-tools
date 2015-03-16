#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use LWP::UserAgent;
use JSON::PP;
use POSIX qw(pause);
use Time::HiRes qw(setitimer ITIMER_REAL);

my $VERSION = "0.02";
my $usage = "Usage: $0 [-v] host operation(logon|values) [-f format(csv)] [-h] [-i] [-p] [-t] [-u] [-d]\n";

GetOptions(
  'v'   => \( my $opt_verbose ),
  'd'   => \( my $opt_daemon ),
  'format=s' => \( my $opt_format = 'csv' ),
  'h'   => \( my $opt_header ),
  'i=f'   => \( my $opt_interval = 2.0 ),
  'p=s'   => \( my $opt_password ),
  't'   => \( my $opt_time ),
  'u'   => \( my $opt_units ),
) or die $usage;
my $host = shift or die $usage;
my $operation = shift or die $usage;

# Define operations
my %operation = (
  'logon' => sub {
    $opt_password or die "$0: Password required for logon.\n";
    do_logon();
  },
  'values' => sub {
    do_logon();
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get( "http://$host/gateway/apipublic/reportInstantaneousValues" );
    print $response->as_string if ( $opt_verbose );
    if ( !$response->is_success ) {
      print STDERR POSIX::strftime( "%FT%T%z ", localtime ) . $response->status_line . "\n";
      die if ( !$opt_daemon );
      return 1;
    }
    my $values = eval { ${ decode_json( $response->content ) }{ 'report' } } || undef;
    if ( !defined( $values ) ) {
      print STDERR POSIX::strftime( "%FT%T%z ", localtime ) . $response->content . "\n";
      die if ( !$opt_daemon );
      return 1;
    }
    my $phase = "";
    my @headers = $opt_time ? "time" : ();
    my @values = $opt_time ? POSIX::strftime( "%FT%T%z", localtime ) : ();
    my @units;
    while ( $values =~ /<BR>\s*(\S+=.+?)<BR>/s ) {
      $values = $';
      my @fields = split ( /,\s+/, $1);
      foreach my $field ( @fields ) {
        my @field = split ( /=|\s+/, $field );
        push ( @headers, $field[0] . $phase );
        push ( @values, $field[1] );
        push ( @units, $field[2] // "" );
      }
      $phase++;
    }
    print join ( ',', @headers ) . "\n" if ( $opt_header );
    print join ( ',', @values ) . "\n";
    print join ( ',', @units ) . "\n" if ( $opt_units );
    return 0;
  }
);
$operation{ $operation } or die "$0: $operation is not a valid operation.\n";

if ( $opt_daemon ) {
  # Daemonize
  local $| = 1;
  $SIG{ALRM} = sub { };
  setitimer ( ITIMER_REAL, 0.01, $opt_interval );
  while ( 1 ) {
    pause;
    $operation{ $operation }->();
  }
}
else {
  # Operation
  exit $operation{ $operation }->();
}

sub do_logon {
  return 1 if ( ! $opt_password );
  my $ua = LWP::UserAgent->new;
  my $request = HTTP::Request->new( POST => "http://$host/gateway/apipublic/logon" );
  $request->content( $opt_password );
  $request->header( 'Content-Type' => 'application/json' );
  my $response = $ua->request( $request );
  print $response->as_string if ( $opt_verbose );
  if ( !$response->is_success ) {
    print STDERR $response->status_line . "\n";
    die if ( !$opt_daemon );
    return 1;
  }
  if ( !defined(${ decode_json( $response->content ) }{ 'success' })) {
    print STDERR $response->content . "\n";
    die if ( !$opt_daemon );
    return 1;
  }
  return 0;
}
