=head1 NAME

SSS - A Triple-S Library

=head1 DESCRIPTION

The Survey Interchange format (Triple-S) is an industry-wide standard
for the encoding of survey results. There are several versions of the
standard.

This library supports XML 1.1, XML 1.2, XML 2.0* and Classic 1.1

See the BUGS AND LIMITATIONS section for limitations of our XML 2.0 support.

=head1 USAGE

 use SSS;
 my $sss = SSS->new();
 $sss->load_defs(file=>'survey.sss'); 
 $sss->load_recs(file=>'survey.asc'); 

 ### do stuff with the data

=head1 NOTE

Version 13 is a complete rewrite of the SSS codebase, and is not backwards
compatible with previous versions.

=head1 TODO

Add the auto_load feature, to support automatic loading of records.

Support the hierarchial data structures in SSS XML 2.0.

Support creating definition and records files.

=cut

package SSS;
# ABSTRACT: A Triple-S Library

our $VERSION = v14.0.0;

use v5.12;
use Moo;
use Carp;

use SSS::Definitions;
use SSS::Records;

=head1 PUBLIC ACCESSORS

=over 1

=item defs

The Definitions object.

Provides the 'load_defs' and 'vars' methods directly via our SSS object.

=cut

has 'defs' => 
(
  is         => 'lazy',
  handles    => [ 'load_defs', 'vars' ],
);

=item recs

The Records object.

Provides the 'load_recs', 'records' and 'find_records' methods directly.

=cut

has 'recs' => 
(
  is         => 'lazy',
  handles    => [ 'load_recs', 'records', 'find_records' ],
);

sub _build_defs 
{
  my ($self) = @_;
  return SSS::Definitions->new(parent=>$self);
}

sub _build_recs 
{
  my ($self) = @_;
  return SSS::Records->new(parent=>$self);
}

=back

=head1 TESTING

A full suite of tests are included in the 't' folder.
Just run 'prove' or 'prove -v' to run all the tests,
or run 'perl ./t/name-of-test.t' to run a single test.

=head1 DEPENDENCIES

Perl 5.12 or higher.

Moo

XML::LibXML

LWP::Simple

=head1 BUGS AND LIMITATIONS

We do not support the SSS Classic 1.0 format, sorry.

We do not support the hierarchial structures introduced in SSS XML 2.0.
You can load the individual hierarchies (i.e. any definition file that has
a <survey/> and associated set of records) but we don't support the top-level
definition file with the <hierarchy/> element yet.

=head1 AUTHOR

Timothy Totten <2010@huri.net>

=head1 LICENSE

Artistic License 2.0

=cut

## End of package.
1;