package SSS::Definitions;

use Mouse;
use Carp;

has 'parent' => 
(
  is       => 'ro',
  required => 1,
);

=item vars

An Array of SSS::Variable objects representing the variables in the order
they were defined in the definition file(s).

=cut

has 'vars' => 
(
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);

=item vars_by_name

A Hash of the vars, indexed by their SSS NAME.

=cut

has 'vars_by_name' => 
(
  is       => 'ro',
  isa      => 'HashRef',
  default  => sub { {} },
);

=item vars_by_id

A Hash of the vars, indexed by their SSS VARIABLE ID.

=cut

has 'vars_by_id' =>
(
  is        => 'ro',
  isa       => 'HashRef',
  default   => sub { {} },
);

=item date

The DATE field from the definitions, if set.

=cut

has 'date' =>
(
  is  => 'rw',
  isa => 'Str',
);

=item time

The TIME field from the definitions, if set.

=cut

has 'time' =>
(
  is  => 'rw',
  isa => 'Str',
);

=item origin

The ORIGIN field from the definitions, if set.

=cut

has 'origin' =>
(
  is  => 'rw',
  isa => 'Str',
);

=item user

The USER field from the definitions, if set.

=cut

has 'user' =>
(
  is  => 'rw',
  isa => 'Str',
);

=item survey_name

The SURVEY NAME field from the definitions, if set. SSS XML 1.2+ only.

=cut

has 'survey_name' =>
(
  is  => 'rw',
  isa => 'Str',
);

=item survey_version

The SURVEY VERSION field from the definitions, if set. SSS XML 1.2+ only.

=cut

has 'survey_version' =>
(
  is  => 'rw',
  isa => 'Str',
);

=item survey_title

The SURVEY TITLE field from the definitions, if set.

=cut

has 'survey_title' =>
(
  is  => 'rw',
  isa => 'Str',
);

=item record_id

The RECORD ID field from the definitions.

=cut

has 'record_id' =>
(
  is  => 'rw',
  isa => 'Str',
);

=item record_uri

If the <record href="" ... > is used, we store it here. SSS XML 1.2+ only.

This can be used in a case like:

$sss->load_defs('my-data.xml');
$sss->load_recs($sss->defs->record_uri);

YMMV.

=cut

has 'record_uri' =>
(
  is  => 'rw',
  isa => 'Str',
);

=item record_format

The format of the record data file.

=cut

has 'record_format' =>
(
  is      => 'rw',
  isa     => 'Str',
  default => 'fixed',
);

=item record_skip

If set, and > 0, we skip this many lines in the record file.

=cut

has 'record_skip' =>
(
  is      => 'rw',
  isa     => 'Int',
  default => 0,
);

=item add_var($variable_object)

Adds a new variable definition to the system. 

NOTE: There should really be no need to call this directly, use load_defs() 
instead, it can load more than one definition file, as long as they specify 
different variables.

=cut

sub add_var
{
  my ($self, $variable) = @_;
  my $id = $variable->id;
  $self->vars_by_id->{$id} = $variable;
  my $name = $variable->name;
  if ($name)
  {
    $self->vars_by_name->{$name} = $variable;
  }
  push(@{$self->vars}, $variable);
}

=item get_var_by_name($name)

Returns a Hash Reference representing the variable with the given NAME field.

  my $var = $sss->get_var_by_name($name);

=cut

sub get_var_by_name
{
  my ($self, $name) = @_;
  if (!defined $name) 
  { 
    carp "Must specify a variable name in get_var_by_name()";
    return;
  }
  my $vars = $self->vars_by_name;
  if (exists $vars->{$name})
  {
    return $vars->{$name};
  }
  else
  {
    carp "Attempt to get non-existent variable by name, '$name'.";
    return;
  }
}

=item get_var_by_id()

Return a Hash Reference representing the variable with the given VARIABLE ID.

  my $var = $sss->get_var_by_id($id);

=cut

sub get_var_by_id
{
  my ($self, $id) = @_;
  if (!defined $id) 
  { 
    carp "Must specify a variable id in get_var_by_id()"; 
    return;
  }
  my $vars = $self->vars_by_id;
  if (exists $vars->{$id})
  {
    return $vars->{$id};
  }
  else
  {
    carp "Attempt to get non existent variable by id, '$id'.";
    return;
  }
}

=item load_defs

Load the specified definitions.

Specify one of the named parameters:

  file    The path to a file to load.
  url     The URL containing the file to load.
  text    The raw definitions text itself.

=cut

sub load_defs
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

  $text =~ s/^\s+//g; ## Trim leading whitespace.
  if (substr($text, 0, 1) eq '<')
  {
    require SSS::Definitions::XML;
    my $parser = SSS::Definitions::XML->new(parent => $self);
    $parser->load_defs($text, %opts);
  }
  elsif (substr($text, 0, 3) eq 'SSS')
  {
    require SSS::Definitions::Classic;
    my $parser = SSS::Definitions::Classic->new(parent => $self);
    $parser->load_defs($text, %opts);
  }
  else
  {
    carp "Invalid definition file format, could not parse.";
  }
}

1;

