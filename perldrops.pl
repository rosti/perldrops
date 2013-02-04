#!/usr/bin/perl

use strict;
use warnings;

use DBCredentials;
use FuseInterface;

use POSIX qw(getuid getgid);
use WebService::Dropbox;

sub parse_config_file
{
	my $config_file = $_[0];
	my $config_hash = {};

	open CONFIGFILE, $config_file or return $config_hash;

	while (<CONFIGFILE>) {

		chomp;

		next if (/^\s*#/ or /^\s*$/) ;

		if (/^(\s*)(\w+)(\s*)\=(\s*)([\w|\(-\:]+)/) {
			$config_hash->{$2} = $5;
		} else {
			print("Syntax error: $_\n");
		}
	}

	close CONFIGFILE;

	return $config_hash;
}

sub run_fuse_fs
{
	my $settings = $_[0];

	my $dropbox = WebService::Dropbox->new(DBCredentials::get_credentials());

	$dropbox->access_token($settings->{access_token});
	$dropbox->access_secret($settings->{access_secret});
	$dropbox->root($settings->{access_type});

	FuseInterface::init($dropbox, $settings->{mountpoint}, $settings);
}

my $config_file = shift || $ENV{HOME}."/.perldrops";

my $settings = parse_config_file($config_file);

unless (defined($settings->{access_token} or defined($settings->{access_secret}))) {
	die "Run genconfig.pl to generate config file with valid DropBox credentials!\n";
}

$settings->{access_type} = 'sandbox' unless (defined($settings->{access_type}));
$settings->{mountpoint} = '/mnt' unless (defined($settings->{mountpoint}));
$settings->{uid} = getuid() unless (defined($settings->{uid}));
$settings->{gid} = getgid() unless (defined($settings->{gid}));
$settings->{mode} = '0644' unless (defined($settings->{mode}));

$settings->{mode} = oct($settings->{mode});

run_fuse_fs($settings);

