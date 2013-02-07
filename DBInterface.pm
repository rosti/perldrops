package DBInterface;

use strict;
use warnings;

use Errno qw(ENOTDIR EIO ENOENT ENOANO);
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

	unless (defined $dropbox_time) {
		return 0;
	}

	my $time_pattern = "%a, %d %b %Y %H:%M:%S %z";
	my $strp = DateTime::Format::Strptime->new(pattern => $time_pattern);

	return $strp->parse_datetime($dropbox_time)->epoch;
}

sub getattr
{
	my ($self, $filepath) = @_;

	my $file_info = $self->{dropbox}->metadata($filepath);

	unless (defined $file_info) {
		return -ENOENT();
	}

	my $block_size = 1024;
	my $size = $file_info->{bytes};
	my $blocks = 1 + $size / $block_size;
	my $file_time = dropbox_to_unix_time($file_info->{modified});

	my $mode = $self->{mode};
	$mode |= ($file_info->{is_dir} ? 0040000 : 0100000);

	(0,		# device
	 0,		# inode (ignored by FUSE)
	 $mode,		# Unix mode
	 1,		# hard links
	 $self->{uid},	# UID
	 $self->{gid},	# GID
	 0,		# rdev (for special files only)
	 $size,		# file size in bytes
	 $file_time,	# atime
	 $file_time,	# mtime
	 $file_time,	# ctime
	 $block_size,	# block size in bytes
	 $blocks	# "blocks" on disk
	);
}

sub getdir
{
	my ($self, $directory) = @_;

	my $dir_info = $self->{dropbox}->metadata($directory);

	unless (defined($dir_info) || $dir_info->{is_dir}) {
		return ('.', ENOTDIR());
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

	$self->{dropbox}->create_folder($directory) or return -EIO();

	return 0;
}

sub unlink
{
	my ($self, $path) = @_;

	$self->{dropbox}->delete($path) or return -ENOENT();

	return 0;
}

*rmdir = \&unlink;

sub rename
{
	my ($self, $old_path, $new_path) = @_;

	$self->{dropbox}->move($old_path, $new_path) or return -ENOENT();

	return 0;
}

sub read
{
	my ($self, $path, $size, $offset) = @_;
	my $block = "";
	my $end_byte = $offset + $size - 1;

	my $response_code = sub {
		$block .= $_[0];
	};

	my $files_opts = {
		headers => [ 'Range' => "bytes=$offset-$end_byte" ],
	};

	$self->{dropbox}->files($path, $response_code, {}, $files_opts) or return -EIO();

	return $block;
}

sub statfs
{
	return -ENOANO();
}

1;
