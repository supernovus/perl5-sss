package SSS::Records;

use Mouse;
use Carp;

has 'parent'  => 
(
  is       => 'ro',
  isa      => 'SSS',
  required => 1,
);

has 'records' => 
(
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);

=item find_records()

Search through the records for those containing certain variable values.

  my @select = $sss->find_records(MyVar => 1);

=cut

sub find_records
{
  my ($self, %query) = @_;
  my @recs = @{$self->records};
  my $reccount = scalar @recs;
  if ($reccount < 1) { carp "No records found, cannot continue."; return; }
  my @return;
  RECORD: for my $rec (@recs)
  {
    for my $key (keys %query)
    {
      my $value = $query{$key};
      if 
      (  ! exists $rec->fields_by_name->{$key}
        || $rec->fields_by_name->{$key}->value ne $value
      )
      {
        next RECORD; ## Skip filtered records.
      }
    }
    push @return, $rec;
  }
  return @return;
}

=item get_fields_by_name()

Returns an Array of Hash references representing the record fields,
where each hash key is the NAME field from the survey definitions.

  my @recs = $sss->get_fields_by_name();
  foreach my $rec (@recs)
  {
    my $cost = $rec->{cost}; ## a VARIABLE with a NAME of 'cost' must exist.
    do_something_with($cost->{value});
  }

=cut

sub get_fields_by_name
{
  my ($self, %opts) = @_;
  my @recs = $self->find_records(%opts);
  my @return;
  for my $rec (@recs)
  { ## We are only interested in the name index.
    push @return, $rec->fields_by_name;
  }
  return @return;
}

=item get_fields_by_id()

Returns an Array of Hash references representing the record fields,
where each hash key is the VARIABLE ID from the survey definitions.

  my @recs = $sss->get_fields_by_id();
  foreach my $rec (@recs)
  {
    my $var15 = $rec->{15}; ## a VARIABLE with an ID of '15' must exist.
    do_something_with($var15->{value});
  }

=cut

sub get_fields_by_id
{
  my ($self, %opts) = @_;
  my @recs = $self->find_records(%opts);
  my @return;
  for my $rec (@recs)
  { ## We are only interested in the id index.
    push @return, $rec->fields_by_id;
  }
  return @return;
}

=item load_recs()

Loads the records in either fixed-width or CSV format depending on the
settings in the definitions.

Specify one of the named parameters:

  file    The path to a file to load.
  url     The URL containing the file to load.
  text    The raw records text itself.

=cut

sub load_recs
{
  my ($self, %opts) = @_;

  my $text;

  if (exists $opts{file})
  {
    my $file = $opts{file};
    if (!$file || !-f $file) 
    { 
      carp "Missing or invalid definition file."; 
      return;
    }
    $text = do { local ( @ARGV, $/ ) = $file ; <> } ;
  }
  elsif ($opts{url})
  {
    require LWP::Simple;
    $text = LWP::Simple::get($opts{url});
  }
  elsif ($opts{text})
  {
    $text = $opts{text};
  }

  my $format = lc($self->parent->defs->record_format);
  if ($format eq 'fixed')
  {
    require SSS::Records::Fixed;
    my $parser = SSS::Records::Fixed->new(parent => $self);
    $parser->load_recs($text, %opts);
  }
  elsif ($format eq 'csv')
  {
    require SSS::Records::CSV;
    my $parser = SSS::Records::CSV->new(parent => $self);
    $parser->load_recs($text, %opts);
  }
  else
  {
    carp "Invalid record file format, could not parse.";
  }
}

1;

