package DBInterface;

use strict;
use warnings;

use Errno qw (ENOTDIR, EIO);
use File::Basename;
use WebService::Dropbox;
use DateTime::Format::Strptime;

sub new
{
	my ($class, $args) = @_;

	my $object = {
		dropbox => $args->{dropbox},
		uid => $args->{uid},
		gid => $args->{gid},
		mode => $args->{mode},
	};

	bless($object, $class);

	return $object;
}

sub dropbox_to_unix_time
{
	my $dropbox_time = $_[0];
	my $time_pattern = "%a, %d %b %Y %H:%M:%S %z";
	my $strp = DateTime::Format::Strptime->new(pattern => $time_pattern);

	return $strp->parse_datetime($dropbox_time)->epoch;
}

sub getattr
{
	my ($self, $filepath) = @_;

	my $block_size = 1024;
	my $file_info = $self->{dropbox}->metadata($filepath);
	my $size = $file_info->{bytes};
	my $file_time = dropbox_to_unix_time($file_info->{modified});

	(0,		# device
	 0,		# inode (ignored by FUSE)
	 $self->{mode},	# Unix mode
	 1,		# hard links
	 $self->{uid},	# UID
	 $self->{gid},	# GID
	 0,		# rdev (for special files only)
	 $size,		# file size in bytes
	 $file_time,	# atime
	 $file_time,	# mtime
	 $file_time,	# ctime
	 $block_size,	# block size in bytes
	 $size / $block_size	# "blocks" on disk
	);
}

sub getdir
{
	my ($self, $directory) = @_;

	my $dir_info = $self->{dropbox}->metadata($directory);

	unless ($dir_info->{is_dir}) {
		return ('.', ENOTDIR);
	}

	my @dir_entries = map {
		my @components = fileparse($_->{path});
        	$components[0]
        	} @{ $dir_info->{contents} };

	('.', '..', @dir_entries, 0);
}

sub mkdir
{
	my ($self, $directory, $mode) = @_;

	$self->{dropbox}->create_folder($directory) or return -EIO;
}


