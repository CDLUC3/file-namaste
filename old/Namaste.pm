package File::Namaste;

use 5.000000;
use strict;
use warnings;

my %kernel = (
	0	=>  'dir_type',
	1	=>  'who',
	2	=>  'what',
	3	=>  'when',
	4	=>  'where',
);

# This is a magic routine that the Exporter calls for any unknown symbols.
#
sub export_fail { my( $class, @symbols )=@_;
	# XXX define ANVLR, ANVLS, (GR)ANVL*
	print STDERR "XXXXX\n";
	for (@symbols) {
		print STDERR "sym=$_\n";
	}
	#return @symbols;
	return ();
}

require Exporter;
our @ISA = qw(Exporter);

our $VERSION;
$VERSION = sprintf "%d.%02d", q$Name: Release-0-12 $ =~ /Release-(\d+)-(\d+)/;
our @EXPORT = qw(
	get_namaste set_namaste
	num2dk om oml
);
our @EXPORT_OK = qw(
);

use File::Value;

# xxx is this routine internal only?
# only first arg required
# return tvalue given fvalue
sub namaste_tvalue { my( $fvalue, $max, $ellipsis )=@_;

	my $tvalue = $fvalue;
	$tvalue =~ s,/,\\,g;
	$tvalue =~ s,\n+, ,g;
	$tvalue =~ s,\p{IsC},?,g;
	# XXX if (windows) s/badwinchars/goodwinchars/
	# XXX eg, $s =~ tr[<>:"/?*][.]
	# XXX not yet doing unicode or i18n

	my $xx = elide($tvalue, $max, $ellipsis);
	return $xx;
	#return elide($tvalue, $max, $ellipsis);
}

# first two args required
# returns empty string on success, otherwise a diagnostic
sub set_namaste { my( $num, $fvalue, $max, $ellipsis )=@_;

	return 0
		if (! defined($num) || ! defined($fvalue));

	my $fname = "$num=" . namaste_tvalue($fvalue, $max, $ellipsis);

	return file_value(">$fname", $fvalue);
}

use File::Glob ':glob';		# standard use of module, which we need
				# as vanilla glob won't match whitespace

# args give numbers to fetch; no args means return all
# args can be file globs
# returns array of number/fname/value triples (every third elem is number)
sub get_namaste {

	my (@in, @out);
	if ($#_ < 0) {			# if no args, get all files that
		@in = bsd_glob('[0-9]=*');	# start "<digit>=..."
	}
	else {				# else do globs for each arg
		push @in, bsd_glob($_ . '=*')
			while (defined($_ = shift @_));
	}
	my ($number, $fname, $fvalue, $status);
	while (defined($fname = shift(@in))) {
		# XXX other params for file_value??
		$status = file_value("<$fname", $fvalue);
		($number) = ($fname =~ /^(\d*)=/);
		$number = ""
			if (! defined($number));
		push @out, $number, $fname, ($status ? $status : $fvalue);
	}
	return @out;
}

sub num2dk{ my( $number )=@_;

	return $kernel{$number}
		if (exists($kernel{$number})
			&& defined($kernel{$number}));
	return $number;
}

use File::ANVL;

# Output Multiplexer
sub om { my( $format, $mode, $name, $value, $attribute, @other )=@_;

	if ($format eq FMT_PLAIN) {
		return 1			# don't print comments
			if ($mode eq NOTE);
		# if we get here, we have a non-comment (DATA)
		# xxx ignoring attribute and other
		return (print $value, "\n");
	}
	elsif ($format eq FMT_ANVL) {	
		return (print "# ", anvl_fmt($name, $value))
			if ($mode eq NOTE);
		# if we get here, we have a non-comment (DATA)
		# xxx ignoring attribute and other
		return (print anvl_fmt($name, $value));
	}
	elsif ($format ne FMT_XML) {	
		pod2usage("$0: $format: unsupported format code");
	}

	# if we get here, we're doing XML formatted output
	# xxx mostly untested code
	# xxx need to escape before embedding
	#
	return (print "<!-- $name, $value -->\n")
		if ($mode eq NOTE);
	# if we get here, we have a non-comment (DATA)
	# xxx ignoring attribute and other
	return (print "<$name>$value</$name>\n");
}

# extra newline version of om()
sub oml { my( $format, $mode, $name, $value, $attribute, @other )=@_;

	my $ret = om($mode, $name, $value, $attribute, @other);
	return $ret	if ! $ret;
	return (print "\n");
}

1;

__END__

=head1 NAME

File::Namaste - routines for NAMe-AS-TExt tags (V0.1)

=head1 SYNOPSIS

 use File::Namaste;         # to import routines into a Perl script

 $stat = set_namaste( $number, $fvalue, $max, $ellipsis )
                            # Return empty string on success, else an
                            # error message.  The first two arguments are
                            # required; remaining args passed to elide().
                            # Uses the current directory.

 # Example: set the directory type and title tag files.
 ($msg = set_namaste(0, "dflat_0.4")
          || set_namaste(2, "Crime and Punishment"))
     and die("set_namaste: $msg\n");

 @num_nam_val_triples = get_namaste( $filenameglob, ...)
                            # Return an array of number/filename/value
                            # triples (eg, every 3rd elem is number).
			    # Args give numbers (as file globs) to fetch
			    # (eg, "0" or "[1-4]") and no args is same
			    # as "[0-9]".  Uses the current directory.

 # Example: fetch all namaste tags and print.
 my @nnv = get_namaste();
 while (defined($num = shift(@nnv))) {  # first of triple is tag number;
     $fname = shift(@nnv);              # second is filename derived...
     $fvalue = shift(@nnv);             # from third (the full value)
     print "Tag $num (from $fname): $fvalue\n";
 }

=head1 DESCRIPTION

This is very brief documentation for the B<Namaste> Perl module, which
implements the Namaste (Name as Text) convention for containing a data
element completely within the content of a file, using as filename an
approximation of the value preceded by a numeric tag.

The functions C<file_value()> and C<elide()> are general purpose and do
not rely on Namaste; however, they are used by C<set_namaste()>
and C<get_namaste()>.

=head1 SEE ALSO

Directory Description with Namaste Tags
	L<http://www.cdlib.org/inside/diglib/namaste/namastespec.html>

=head1 HISTORY

This is an alpha version of Namaste tools.  It is written in Perl.

=head1 AUTHOR

John A. Kunze I<jak at ucop dot edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 UC Regents.  Open source Apache License, Version 2.

=head1 PREREQUISITES

Perl Modules: L<File::Glob>

Script Categories:

=pod SCRIPT CATEGORIES

UNIX : System_administration

=cut

sub anvl_oldfmt { my( $s )=@_;

	$s eq "" and		# return an empty string untouched (add no \n)
		return $s;
	#$s =~ s/\n/ /g;	# replace every \n with " " -- this case is
	#			# not expected, but would screw things up

	$s =~ s/^\s*//;		# trim initial whitespace
	$s =~ s/%/%%/g;		# to preserve literal %, double it
				# XXX must be decoded by receiver
	# xxx ERC-encode ERC structural delims ?

	# XXX why do 4 bytes (instead of 2) show up in wget??
	# # %-encode any chars that need it
	# $s =~ s/$except_re/ "%" . join("", unpack("H2", $1)) /ge;
	# fold lines longer than 72 chars and wrap with one tab's
	#    indention (assume tabwidth=8, line length of 64=72-8

	# wrap:  initial tab = "", subsequent tab = "\t"
	$s = wrap("", "\t", $s);
	return $s . "\n";		# append newline to end element
}

my $debug = 0;			# default is off; to set use anvl_debug(1)

sub anvl_debug { my( $n )=@_;
	$debug = $n;
	return 1;
}

# if length is 0, go for it.
#
my $ridiculous = 4294967296;	# max length is 2^32  XXX better way?

sub file_value { my( $file, $value, $how, $length )=@_;

	my $ret_value = \$_[1];
	use constant OK => "";		# empty string on return means success

	! defined($file) and
		return "needs a file name";

	# make caller be explicit about whether doing read/write/append
	#
	$file !~ /^\s*(<|>|>>)\s*(\S.*)/ and
		return "file ($file) must begin with '<', '>', or '>>'";
	my ($mode, $statfname) = ($1, $2);

	# we're to do value-to-file
	# in this case we ignore $how and $length
	# XXX should we not support a trim??
	if ($mode =~ />>?/) {
		! defined($value) and
			return "needs a value to put in '$file'";
		! open(OUT, $file) and
			return "$statfname: $!";
		my $r = print OUT $value;
		close(OUT);
		return ($r ? OK : "write failed: $!");
	}
	# If we get here, we're to do file-to-value.

	my $go_for_it = (defined($length) && $length eq "0" ? 1 : 0);
	my $statlength = undef;

	if (defined($length)) {
		$length !~ /^\d+$/ and
			return "length unspecified or not an integer";
	}
	elsif ($statfname ne "-") {
		# no length means read whole file, but be reasonable
		$statlength = (-s $statfname);
		! defined($statlength) and
			return "$statfname: $!";
		$length = ($statlength > $ridiculous
			? $ridiculous : $statlength);
	}
	else {
		$length = $ridiculous;
	}

	$how ||= "trim";		# trim (def), raw, untaint
	$how = lc($how);
	$how ne "trim" && $how ne "raw" && $how ne "untaint" and
		return "third arg ($how) must be one of: trim, raw, or untaint";

	! open(IN, $file) and
		return "$statfname: $!";
	if ($go_for_it) {		# don't be reasonable about length
		local $/;
		$$ret_value = <IN>;
		close(IN);
	}
	else {
		my $n = read(IN, $$ret_value, $length);
		close(IN);
		! defined($n) and
			return "$statfname: failed to read $length bytes: $!";
		# XXXX do we have to read in a loop until all bytes come in?
		return "$statfname: read fewer bytes than expected"
			if (defined($statlength) && $n < $statlength);
	}

	if ($how eq "trim") {
		$$ret_value =~ s/^\s+//;
		$$ret_value =~ s/\s+$//;
	}
	elsif ($how eq "untaint") {
		if ($$ret_value =~ /([-\@\w.]+)/) {
			$$ret_value = $1;
		}
	}
	# elsif ($how eq "raw") { then no further processing }

	return OK;
}

# xxx unicode friendly??
#
# XXXX test with \n in string???
my $max_default = 16;		# is there some sense to this? xxx use
				# xxx fraction of display width maybe?

sub elide { my( $s, $max, $ellipsis )=@_;

	return undef
		if (! defined($s));
	$max ||= $max_default;
	return undef
		if ($max !~ /^(\d+)([esmESM]*)([+-]\d+%?)?$/);
	my ($maxlen, $where, $tweak) = ($1, $2, $3);

	$where ||= "e";
	$where = lc($where);

	$ellipsis ||= ($where eq "m" ? "..." : "..");
	my $elen = length($ellipsis);

	my ($side, $offset, $percent);		# xxx only used for "m"?
	if (defined($tweak)) {
		($side, $offset, $percent) = ($tweak =~ /^([+-])(\d+)(%?)$/);
	}
	$side ||= ""; $offset ||= 0; $percent ||= "";
	# XXXXX finish this! print "side=$side, n=$offset, p=$percent\n";

	my $slen = length($s);
	return $s
		if ($slen <= $maxlen);	# doesn't need elision

	my $re;		# we will create a regex to edit the string
	# length of orig string after that will be left after edit
	my $left = $maxlen - $elen;

	my $retval = $s;
	# Example: if $left is 5, then
	#   if "e" then s/^(.....).*$/$1$ellipsis/
	#   if "s" then s/^.*(.....)$/$ellipsis$1/
	#   if "m" then s/^.*(...).*(..)$/$1$ellipsis$2/
	if ($where eq "m") {
		# if middle, we split the string
		my $half = int($left / 2);
		$half += 1	# bias larger half to front if $left is odd
			if ($half > $left - $half);	# xxx test
		$re = "^(" . ("." x $half) . ").*("
			. ("." x ($left - $half)) . ")\$";
			# $left - $half might be zero, but this still works
		$retval =~ s/$re/$1$ellipsis$2/;
	}
	else {
		my $dots = "." x $left;
		$re = ($where eq "e" ? "^($dots).*\$" : "^.*($dots)\$");
		if ($where eq "e") {
			$retval =~ s/$re/$1$ellipsis/;
		}
		else {			# else "s"
			$retval =~ s/$re/$ellipsis$1/;
		}
	}
	return $retval;
}

1;
