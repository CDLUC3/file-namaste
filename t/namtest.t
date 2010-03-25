use 5.006;
use Test::More qw( no_plan );

use strict;
use warnings;

my $script = "nam";		# script we're testing

# as of 2009.08.27  (SHELL stuff, remake_td, Config perlpath)
#### start boilerplate for script name and temporary directory support

use Config;
$ENV{SHELL} = "/bin/sh";
my $td = "td_$script";		# temporary test directory named for script
# Depending on circs, use blib, but prepare to use lib as fallback.
my $blib = (-e "blib" || -e "../blib" ?	"-Mblib" : "-Ilib");
my $bin = ($blib eq "-Mblib" ?		# path to testable script
	"blib/script/" : "") . $script;
my $perl = $Config{perlpath} . $Config{_exe};	# perl used in testing
my $cmd = "2>&1 $perl $blib " .		# command to run, capturing stderr
	(-x $bin ? $bin : "../$bin") . " ";	# exit status in $? >> 8

my ($rawstatus, $status);		# "shell status" version of "is"
sub shellst_is { my( $expected, $output, $label )=@_;
	$status = ($rawstatus = $?) >> 8;
	$status != $expected and	# if not what we thought, then we're
		print $output, "\n";	# likely interested in seeing output
	return is($status, $expected, $label);
}

use File::Path;
sub remake_td {		# make $td with possible cleanup
	-e $td			and remove_td();
	mkdir($td)		or die "$td: couldn't mkdir: $!";
}
sub remove_td {		# remove $td but make sure $td isn't set to "."
	! $td || $td eq "."	and die "bad dirname \$td=$td";
	eval { rmtree($td); };
	$@			and die "$td: couldn't remove: $@";
}

#### end boilerplate

use File::Namaste;

{ 	# Namaste.pm tests

remake_td();

my $namy = "noid_0.6";
is set_namaste($td, 0, "pairtree_0.3"), "", 'short namaste tag';
is set_namaste($td, 0, $namy), "", 'second, repeating namaste tag';

my $namx = "Whoa/dude:!
  Adventures of HuckleBerry Finn";

is set_namaste($td, 1, $namx), "", 'longer stranger tag';

my @namtags = get_namaste($td);
ok scalar(@namtags) eq 9, 'got correct number of tags';

is $namtags[8], $namx, 'read back longer stranger tag';

is scalar(get_namaste($td, "9")), "0", 'no matching tags';

@namtags = get_namaste($td, "0");
is $namtags[2], $namy, 'read repeated namaste tag, which glob sorts first';

my ($num, $fname, $fvalue, @nums);
@namtags = get_namaste($td);
while (defined($num = shift(@namtags))) {
	$fname = shift(@namtags);
	$fvalue = shift(@namtags);
	unlink($fname);
	push(@nums, $num);
}
is join(", ", @nums), "0, 0, 1", 'tag num sequence extracted from array';

is scalar(get_namaste($td)), "0", 'tags all unlinked';

#XXX need lots more tests

remove_td();

}

{ 	# nam tests
# XXX need more -m tests
# xxx need -d tests
remake_td();
$cmd .= " -d $td ";

my $x;

$x = `$cmd rmall`;
is $x, "", 'nam rmall to clean out test dir';

$x = `$cmd set 0 foo`;
chop($x);
is $x, "", 'set of dir_type';

#print "nam_cmd=$cmd\n", `ls -t`;

$x = `$cmd get 0`;
chop($x);
is $x, "foo", 'get of dir_type';

$x = `$cmd add 0 bar`;
chop($x);
is $x, "", 'set extra dir_type';

$x = `$cmd get 0`;
chop($x);
is $x, "bar
foo", 'get of two dir_types';

$x = `$cmd set 0 zaf`;
chop($x);
is $x, "", 'clear old dir_types, replace with new';

$x = `$cmd get 0`;
chop($x);
is $x, "zaf", 'get of one new dir_type';

$x = `$cmd set 1 'Mark Twain'`;
chop($x);
is $x, "", 'set of "who"';

$x = `$cmd get 1`;
chop($x);
is $x, "Mark Twain", 'get of "who"';

$x = `$cmd set 2 'Adventures of Huckleberry Finn' 13m ___`;
chop($x);
is $x, "", 'set of long "what" value, with elision';

$x = `$cmd get 2`;
chop($x);
is $x, 'Adventures of Huckleberry Finn', 'get of long "what" value';

$x = `$cmd -vm anvl get 2`;
chop($x);
like $x, '/2=Adven___ Finn/', 'get filename with "-m anvl" and -v comment';

$x = `$cmd --verbose --format xml get 2`;
chop($x);
like $x, '/2=Adven___ Finn -->/', 'get with long options and "xml" comment';

$x = `$cmd rmall`;
is $x, "", 'final nam rmall to clean out test dir';

remove_td();

}
