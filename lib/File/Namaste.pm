package File::Namaste;

use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION;
$VERSION = sprintf "%d.%02d", q$Name: Release-0-20 $ =~ /Release-(\d+)-(\d+)/;

our @EXPORT = qw(
	get_namaste set_namaste
);				# yyy more conservative export ??
our @EXPORT_OK = qw(
);

use File::Value;
use File::Spec;

# Default setting for tranformations is non-portable for Unix.
our $portable_default = grep(/Win32|OS2/i, @File::Spec::ISA);

# xxx not yet doing unicode or i18n
# only first arg required
# return tvalue given fvalue
sub namaste_tvalue { my( $fvalue, $portable, $max, $ellipsis )=@_;

	defined($portable)	or $portable = $portable_default;
	my $tvalue = $fvalue;
	$tvalue =~ s,/,=,g;
	$tvalue =~ s,\s+, ,g;
	$tvalue =~ s,\p{IsC},?,g;	# control characters

	$portable and			# more portable (Win32) mapping
		$tvalue =~ tr {"*/:<>?|\\}{.};

	return elide($tvalue, $max, $ellipsis);
}

# Ordered list of labels, mostly kernel element names
#   yyy should this be coming from ERC module, or is that creating
#   a big dependency hurdle for a sliver of functionality?
our @namaste_labels = qw(
	dir_type
	who
	what
	when
	where
	how
	why
	huh
);

sub num2label { my $num = shift;

	my $last = $#namaste_labels;
	$num =~ s/^(\d+).*/$1/;				# forgive, eg, 3=foo
	$num =~ /\D/ || $num < 0 || $num > $last and
		return $namaste_labels[$last];		# last label
		# last label doubles as unknown (huh?) if number is bad
	return $namaste_labels[$num];			# normal return
}

my $dtname = ".dir_type";	# canonical name of directory type file
# xxx .=dir_type
# xxx .=how
# xxx .=huh
# xxx .=what
# xxx .=when
# xxx .=where
# xxx .=who
# xxx .=why


# $num and $fvalue required
# returns empty string on success, otherwise a diagnostic
sub set_namaste { my( $dir, $portable, $num, $fvalue, $max, $ellipsis )=@_;

	return 0
		if (! defined($num) || ! defined($fvalue));

	$dir ||= "";
	$dir = File::Spec->catfile($dir, "")	# add portable separator
		if $dir;		# (eg, slash) if there's a dir name

	my $fname = $dir . $dtname;	# path to .dir_type, if needed
	my $tvalue = namaste_tvalue($fvalue, $portable, $max, $ellipsis);
	# ".0" means set .dir_type also; "." means only set .dir_type
	if ($num =~ s/^\.0/0/ || $num eq ".") {
		# "append only" supports multi-typing in .dir_type, so
		# caller must remove .dir_type to re-set (see "nam" script)
		my $ret = file_value(">>$fname", $fvalue);
		return $ret		# return if error or only .dir_type
			if $ret || $num eq ".";
	}

	$fname = "$dir$num=" .
		namaste_tvalue($fvalue, $portable, $max, $ellipsis);

	return file_value(">$fname", $fvalue);
}

use File::Glob ':glob';		# standard use of module, which we need
				# as vanilla glob won't match whitespace

# first arg is directory, remaining args give numbers to fetch;
# no args means return all
# args can be file globs
# returns array of number/fname/value triples (every third elem is number)
sub get_namaste {

	my $dir = shift @_;

	$dir ||= "";
	$dir = File::Spec->catfile($dir, "")	# add portable separator
		if $dir;		# (eg, slash) if there's a dir name
	my $dir_type = $dir . $dtname;	# path to .dir_type, if needed

	my (@in, @out);
	if ($#_ < 0) {			# if no args, get all files starting
		@in = bsd_glob($dir . '[0-9]=*');	# "<digit>=..."
		-e $dir_type and		# since we're getting all,
			unshift @in, $dir_type;	# if it exists, add .dir_type
	}
	else {				# else do globs for each arg
		while (defined($_ = shift @_)) {
			if ((s/^\.0/0/ || $_ eq ".") && -e $dir_type) {
				# if requested and it exists, add .dir_type
				push @in, $dir_type;
				next		# next if only .dir_type
					if $_ eq ".";
			}
			push @in, bsd_glob($dir . $_ . '=*')
		}
	}
	my ($number, $fname, $fvalue, $status);
	while (defined($fname = shift(@in))) {

		$status = file_value("<$fname", $fvalue);

		($number) = ($fname =~ m{^$dir(\d*)=});
		# if there's no number matched, it may be for .dir_type,
		# in which case use "." for number, else give up with ""
		$number = ($fname =~ m{^$dir$dtname} ? "." : "")
			if (! defined($number));
		push @out, $number, $fname, ($status ? $status : $fvalue);
	}
	return @out;
}

1;

__END__

=head1 NAME

File::Namaste - routines to manage NAMe-AS-TExt tags

=head1 SYNOPSIS

 use File::Namaste;  # to import routines into a Perl script

 $stat =
     set_namaste($dir, $portable, $number, $fvalue, $max, $ellipsis);
                     # Return empty string on success, else an error
                     # message.  The first four arguments required;
                     # remaining args are passed to File::Value::elide().
                     # Uses $dir or the current directory.  To get Win32
                     # mapping, set $portable to 1.

 # Example: set the directory type and title tag files.
 ($msg = set_namaste(0, 0, "dflat_0.4")
          || set_namaste(2, 0, "Crime and Punishment"))
     and die("set_namaste: $msg\n");

 @num_nam_val_triples = get_namaste($dir, $filenameglob, ...);
                     # Return an array of number/filename/value triples
                     # (eg, every 3rd elem is number).  Args give numbers
                     # (as file globs) to fetch # (eg, "0" or "[1-4]")
                     # and no args is same as "[0-9]".  Uses $dir or the
                     # current directory.

 # Example: fetch all namaste tags and print.
 my @nnv = get_namaste();
 while (defined($num = shift(@nnv))) {  # first of triple is tag number;
     $fname = shift(@nnv);              # second is filename derived...
     $fvalue = shift(@nnv);             # from third (the full value)
     print "Tag $num (from $fname): $fvalue\n";
 }

 $transformed_value =       # filename-safe transform of metadata value
      namaste_tvalue( $full_value, $portable, $max, $ellipsis);

=head1 DESCRIPTION

This is very brief documentation for the B<Namaste> Perl module, which
implements the Namaste (Name as Text) convention for containing a data
element completely within the content of a file, using as filename an
approximation of the value preceded by a numeric tag.

=head1 SEE ALSO

Directory Description with Namaste Tags
    L<https://confluence.ucop.edu/display/Curation/Namaste>

L<nam(1p)>

=head1 HISTORY

This is a beta version of Namaste tools.  It is written in Perl.

=head1 AUTHOR

John A. Kunze I<jak at ucop dot edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 UC Regents.  Open source BSD license.

=head1 PREREQUISITES

Perl Modules: L<File::Glob>

Script Categories:

=pod SCRIPT CATEGORIES

UNIX : System_administration
