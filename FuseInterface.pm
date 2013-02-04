use strict;
use warnings;

use Fuse;
use DBInterface;

package FuseInterface;

our $interface;

sub init
{
	my ($dropbox, $mountpoint, $mountparams) = @_;

	$mountparams->{dropbox} = $dropbox;
	$interface = DBInterface->new($mountparams);

	Fuse::main(mountpoint => $mountpoint,
			getattr => \&FuseInterface::getattr,
			getdir => \&FuseInterface::getdir,
			mkdir => \&FuseInterface::mkdir,
			unlink => \&FuseInterface::unlink,
			rmdir => \&FuseInterface::rmdir,
			rename => \&FuseInterface::rename,
			read => \&FuseInterface::read,
			statfs => \&FuseInterface::statfs,
		);
}

sub getattr
{
	return $interface->getattr(@_);
}

sub getdir
{
	return $interface->getdir(@_);
}

sub mkdir
{
	return $interface->mkdir(@_);
}

sub unlink
{
	return $interface->unlink(@_);
}

sub rmdir
{
	return $interface->rmdir(@_);
}

sub rename
{
	return $interface->rename(@_);
}

sub read
{
	return $interface->read(@_);
}

sub statfs
{
	return $interface->statfs(@_);
}

1;

