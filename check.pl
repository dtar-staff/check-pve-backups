#!/usr/bin/perl

use strict;
use warnings;

use PVE::APIClient::LWP;
use JSON;


#Returns the hash containing required parameters
sub new_server {
	my $apitoken = shift;
	my $hostname = shift;
	my $nodename = shift;
	my $fingerprint = shift;
	my %result = (
		'hostname' => $hostname,
		 'apitoken' => $apitoken,
		 'nodename' => $nodename,
		 'fingerprints' => {
			$fingerprint => 1,
		},
	);
	return \%result;
}

#Returns API connection object, capable of processing requests to server
sub new_connection {
	my $server_ref = shift;
	my %server = %{$server_ref};
	return  PVE::APIClient::LWP->new(
		apitoken => $server{apitoken},
		host => $server{hostname},
		cached_fingerprints => $server{fingerprints},
	);
}


#Returns the array of anonymous hashes with node task descriptions
#For more, see Proxmox VE API docs
sub get_tasks {
	my $server = shift;
	my $connection = new_connection($server);
	return $connection->get("/nodes/$server->{nodename}//tasks", {});
}

#Fancily prints information received from API (bullshit subroutine, but I'm lazy to refactor)
sub print_report {
	my $server_ref = shift;
	my %server = %{$server_ref};
	my $tasks_ref = get_tasks(\%server);
	my @tasks = @{$tasks_ref};
	print "\t\t---===###[[[ $server{hostname} ]]]###===---\n";
	for my $elem (@tasks) {
		my %task = %{$elem};
		my $duration = $task{endtime} - $task{starttime};
		$duration = int($duration / 60 / 60); # Duration in hours
		if ($task{type} eq 'vzdump') {
			print "Backup job [OK] \t", scalar(localtime($task{endtime})) if $task{status} eq 'OK';
			print "Backup job [FAILED] \t", scalar(localtime($task{endtime})) unless $task{status} eq 'OK';
			print "\t Job duration: ~$duration hours.\n";
		}
	}
	
	
}


my @servers = ();


my $srv01_apitoken = 'PVEAPIToken=user@realm!tokenname=some_guid';
my $srv01_hostname = 'some.silly.fqdn';
my $srv01_nodename = 'nodename';
my $srv01_fingerprint = 'SH:A2:56:FI:NG:ER:PR:IN:TO:FY:OU:RS:ER:VE:RC:ER:TI:FI:CA:TE';


push @servers, new_server($srv01_apitoken, $srv01_hostname, $srv01_nodename, $srv01_fingerprint);

for my $elem (@servers) {
	my %server = %{$elem};
	print_report(\%server);
}

