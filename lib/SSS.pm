=head1 NAME

SSS - A Triple-S version 1.1 Parser

=head1 DESCRIPTION

The Survey Interchange format (Triple-S) is an industry-wide standard
for the encoding of survey results. There are several versions of the
standard, including 1.0, 1.1, XML 1.1, XML 1.2 and XML 2.0.

This library is specifically for the non-XML version 1.1

=head1 USAGE

 use SSS;
 my $sss = SSS->new();
 $sss->load_defs('survey.sss');
 $sss->load_recs('survey.asc');
 ### do stuff with the data

=cut

package SSS;

our $VERSION = v11.9.8;

## We are using the Huri Perl base library.
use Huri object=>1, add=>['lines'];
use Carp;

## If you need debugging, use Huri::Debug.
#use Huri::Debug show=>['load_defs','load_recs'];

=head1 PUBLIC METHODS

=over 1

=item new()

Create a new SSS object. Does not load any data.

  my $sss = SSS->new();

=cut

has 'defs'; ## Definitions, loaded from .sss files.
has 'recs'; ## Records, loaded from .asc files.

sub BUILD
{
  my $self = shift;
  my $defs =
  {
    vars =>              # the variables defined in the survey.
    {
      byname  => {},     # Lookup done by NAME field.
      byid    => {},     # Lookup done by VARIABLE id.
      ordered => [],     # A plain ordered array.
    },
  };
  $self->set_defs($defs);
  $self->set_recs([]);
}

=item add_var($hashref)

Adds a new variable definition to the system. 

NOTE: There should really be no need to call this directly, use load_defs() 
instead, it can load more than one definition file, as long as they specify 
different variables.

=cut

sub add_var
{
  my ($self, $variable) = @_;
  my $id = $variable->{id};
  $self->defs->{vars}->{byid}->{$id} = $variable;
  if (exists $variable->{name})
  {
    my $name = $variable->{name};
    $self->defs->{vars}->{byname}->{$name} = $variable;
  }
  push(@{$self->defs->{vars}->{ordered}}, $variable);
}

=item get_vars_by_name()

Returns a Hash Reference of definition variables, where the hash keys are the
NAME field from the survey definition.

  my $vars = $sss->get_vars_by_name();

=cut 

sub get_vars_by_name
{
  my ($self) = @_;
  return $self->defs->{vars}->{byname};
} 

=item get_var_by_name($name)

Returns a Hash Reference representing the variable with the given NAME field.

  my $var = $sss->get_var_by_name($name);

=cut

sub get_var_by_name
{
  my ($self, $name) = @_;
  if (!defined $name) { croak "Must specify a variable name in get_var_by_name()"; }
  my $vars = $self->get_vars_by_name();
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

=item get_vars_by_id()

Returns a Hash Reference of definition variables, where the hash keys are the
VARIABLE ID from the survey definition.

  my $vars = $sss->get_vars_by_id();

=cut

sub get_vars_by_id
{
  my ($self) = @_;
  return $self->defs->{vars}->{byid};
}

=item get_var_by_id()

Return a Hash Reference representing the variable with the given VARIABLE ID.

  my $var = $sss->get_var_by_id($id);

=cut

sub get_var_by_id
{
  my ($self, $id) = @_;
  if (!defined $id) { croak "Must specify a variable id in get_var_by_id()"; }
  my $vars = $self->get_vars_by_id();
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

=item get_vars()

Returns an Array representing the variables, in the order they were defined.

  my @vars = $sss->get_vars();

=cut

sub get_vars
{
  my ($self) = @_;
  my @vars = @{$self->defs->{vars}->{ordered}};
  my $varcount = scalar @vars;
  if ($varcount < 1) { croak "No variables found, cannot continue."; }
  return @vars;
}

=item get_field($fieldname)

Return the top-level field if it was specified.

  my $date = $sss->get_field('date');

=cut

sub get_field
{
  my ($self, $field) = @_;
  if (!defined $field) { croak "You must specify a field to get in get_field()"; }
  if (exists $self->defs->{$field})
  {
    return $self->defs->{$field};
  }
  return;
}

=item load_defs()

Load a definition file (.sss extension)

  $sss->load_defs("survey.sss");

Stores the definitions in an object member called defs.

=cut

sub load_defs
{
  my ($self, $file) = @_;
  my ($variable, $values); ## Private members for storage of VARIABLE and VALUES.
  my @topkeys = ('date', 'time', 'origin', 'user', 'title');
  my @varkeys = ('name', 'label');
  my @types = ('SINGLE', 'MULTIPLE', 'QUANTITY', 'CHARACTER', 'LOGICAL');
  if (!$file || !-f $file) { croak "Missing or invalid definition file."; }
  my @lines = lines($file);
  ##[load_defs] == Definitions ==
  for my $line (@lines)
  {
    chomp($line);
    ##[load_defs]= $line
    given ($line)
    { ## Look for known Triple-S 1.1 statements.
      ## Note: All Triple-S 1.1 statements are case-insensitive.
      if (defined $values)
      { ## We are parsing a VALUES block.
        when (/^\s*(-?[\d\.]+)\s*TO\s*(-?[\d\.]+)\s*(?:WITH)?$/i)
        { ## We found a 'start' and 'finish' value.
          $values->{start} = $1;
          $values->{finish} = $2;
        }
        when (/^\s*(\d+)\s*"(.*?)"\s*(?:(SPECIAL)\s*)?$/i)
        { ## We found a categorical label.
          my $catval = 
          { 
            id   => $1,
            text => $2,
          };
          if ($3)
          {
            $catval->{special} = 1;
          }
          $values->{cats}->{byid}->{$1} = $catval;
          push(@{$values->{cats}->{ordered}}, $catval);
        }
        when (/^\s*END\s*VALUES\s*$/)
        { ## End a VALUES block, saving the values to the variable.
          $variable->{values} = $values;
          undef($values);
        }
      }
      elsif (defined $variable)
      { ## We are parsing a VARIABLE block.
        for my $key (@varkeys)
        { ## Look for variable-specific keys.
          when (/^\s*$key\s*"(.*?)"\s*$/i)
          { ## Set variable data.
            $variable->{$key} = $1;
          }
        }
        for my $type (@types)
        { ## Look for TYPE statements.
          when (/^\s*TYPE\s*$type\s*$/i)
          { ## Set the type.
            $variable->{type} = $type;
          }
        }
        when (/^\s*POSITION\s*(\d+)\s*(?:TO\s*(\d+)\s*)?$/i)
        { ## Position markers.
          $variable->{start} = $1;
          if ($2)
          {
            $variable->{finish} = $2;
            if ($variable->{finish} == $variable->{start})
            {
              $variable->{length} = 1;
            }
            else
            {
              $variable->{length} = $variable->{finish} - ($variable->{start} - 1);
            }
          }
          else
          {
            $variable->{finish} = $1;
            $variable->{length} = 1;
          }
        }
        my $type = $variable->{type};
        if ($type eq 'CHARACTER')
        { ## The SIZE statement only applies to CHARACTER variables.
          when (/^\s*SIZE\s*(\d+)\s*$/i)
          {
            $variable->{size} = $1;
          }
        }
        elsif ($type eq 'SINGLE' || $type eq 'MULTIPLE' || $type eq 'QUANTITY')
        { ## If we're MULTIPLE, look for a SPREAD
          if ($type eq 'MULTIPLE')
          {
            when (/^\s*SPREAD\s*(\d+)\s*(?:OF\s*(\d+)\s*)?$/i)
            { 
              $variable->{subfields} = $1;
              if ($2)
              {
                $variable->{width} = $2;
              }
            }
          }
          ## Check for VALUES blocks
          when (/^\s*VALUES\s*$/i)
          { ## Start tracking values.
            $values = 
            {
              cats =>          ## Categories with defined labels.
              {
                byid    => {}, ## Indexed by category id.
                ordered => [], ## Indexed by defined order.
              },
            };
          }
        }
        when (/^\s*END\s*VARIABLE\s*$/i)
        { ## End a variable block.
          if 
          ( $variable->{type} eq 'MULTIPLE' 
            && exists $variable->{subfields}
            && ! exists $variable->{width}
          ) ## Okay, we have no width field, let's calculate it.
          {
            $variable->{width} = $variable->{length} / $variable->{subfields};
          }
          ## You can look them up by id, name, or an ordered array.
          $self->add_var($variable);
          undef($variable); ## Clear out the variable.
        }
      }
      else
      { ## Top-level statements, outside VARIABLE and VALUES blocks.
        when (/^\s*VERSION\s*(\d\.\d)\s*$/i)
        { ## Ensure the version is correct.
          if ($1 ne "1.1") { croak ".sss file is not Triple-S v1.1, sorry."; }
        }
        for my $key (@topkeys)
        { ## Look for survey-wide keys.
          when (/^\s*$key\s*"(.*?)"\s*$/i)
          { ## Set data based on the keys.
            $self->defs->{$key} = $1;
          }
        }
        when (/^\s*RECORD\s*(\w)\s*$/i)
        { ## Record ID
          $self->defs->{record} = $1;
        }
        when (/^\s*VARIABLE\s*(\d+)\s*$/i)
        { ## Starting a variable block.
          $variable = { id => $1 };
        }
      }
    }
  }
}

=item load_recs()

Load a records file (typically with an .asc extension)

  $sss->load_recs("survey.asc");

=cut

sub load_recs
{
  my ($self, $file) = @_;
  if (!$file || !-f $file) { croak "Missing or invalid records file."; }
  my @defs = $self->get_vars(); 
  my @lines = lines($file);
  for my $line (@lines)
  { ## First, let's store the raw record.
    chomp($line);
    my $rec =
    {
      raw     => $line,
      byname  => {},
      byid    => {},
      ordered => [],
    };
    ## Next, let's process our known definitions.
    foreach my $var (@defs)
    { 
      my $start  = $var->{start}-1;
      my $finish = $var->{finish};
      my $length = $var->{length};
      my $id     = $var->{id};
      my $name   = $var->{name};
      my $recspec = {};
      $rec->{byname}->{$name} = $recspec;
      $rec->{byid}->{$id}     = $recspec;
      push(@{$rec->{ordered}}, $recspec);      
      ## Okay, let's get the value.
      my $rawvalue = substr($line, $start, $length);
      $recspec->{rawvalue} = $rawvalue;
      my $value = $rawvalue;
      $value =~ s/^\s*//g; # strip leading whitespace.
      $value =~ s/\s*$//g; # strip trailing whitespace.
      $recspec->{value} = $value;

      if ($var->{type} eq 'MULTIPLE')
      { ## Okay, let's process multiples.
        my $multiples = 
        {
          byid    => {}, ## Indexed by value id.
          ordered => [], ## Indexed by original order.
        };
        my @cats = @{$var->{values}->{cats}->{ordered}};
        my $catcount = scalar @cats;
        my $reccount = length($rawvalue);
        if (exists $var->{subfields})
        { ## We're in SPREAD format.
          my $subfields = $var->{subfields};
          ## Okay, we're going to generate a cache of known values.
          my @found;
          my $width = $var->{width};
          for (my $st = 0; $st <= $reccount - $width; $st += $width)
          { ## Find our values.
            my $inval = substr($rawvalue, $st, $width);
            my $imval = 
            {
              value => $inval
            };
            push @found, $imval;
          }
          ## Now let's set our data.
          foreach my $cat (@cats)
          { ## Let's see if we are set.
            my $key = $cat->{id};
            my $subval = 0;
            foreach my $found (@found)
            { my $fval = $found->{value};
              if ($fval =~ /^\s*$/) { next; } ## skip empty.
              ##[load_recs] Comparing $key to $fval
              if ($fval == $key)
              {
                $subval = 1;
                $found->{text} = $cat->{text};  ## reference.
              }
            }
            my $mval = 
            {
              value => $subval,
              text  => $cat->{text},  ## reference.
            };
            $multiples->{byid}->{$key} = $mval;
            #push(@{$multiples->{ordered}}, $mval);
          }
          $multiples->{ordered} = \@found;
        }
        else
        { ## We're in Bitstring format.
          if ($reccount < $catcount)
          { ## You can't have a field smaller than the number of values.
            croak "Field size ($catcount) is smaller than values ($reccount) on variable $name";
          }
          foreach my $cat (@cats)
          { ## Let's get our subvalue.
            my $key = $cat->{id};
            my $start = $key - 1;
            my $subval = substr($rawvalue, $start, 1);
            my $mval = {};
            $mval->{value} = $subval;
            $mval->{text}  = $cat->{text}; ## reference.
            $multiples->{byid}->{$key} = $mval;
            push(@{$multiples->{ordered}}, $mval);
          }
        }
        $recspec->{values} = $multiples;
      }
      else
      { ## We're not a multiple, let's see if we have values.
        if (exists $var->{values} && exists $var->{values}->{cats}->{byid}->{$value})
        {
          $recspec->{text} = $var->{values}->{cats}->{byid}->{$value}->{text};
        }
      }
    }
    push(@{$self->recs}, $rec);
  }
}

=item get_recs()

Returns an Array representing the records.

  my @recs = $sss->get_recs();

=cut

sub get_recs
{
  my ($self, %opts) = @_;
  my @recs = @{$self->recs};
  my $reccount = scalar @recs;
  if ($reccount < 1) { croak "No records found, cannot continue."; }
  if (exists $opts{filter} && $opts{filter} && ref $opts{filter} eq 'HASH')
  { ## Filters have been defined. Let's filter the results.
    my @return;
    RECORD: for my $rec (@recs)
    {
      for my $key (keys %{$opts{filter}})
      {
        my $value = $opts{filter}->{$key};
        if 
        ( !exists $rec->{byname}->{$key} 
          || $rec->{byname}->{$key}->{value} ne $value
        )
        {
          next RECORD; ## Skip filtered records.
        }
      }
      push @return, $rec;
    }
    return @return;
  }
  return @recs;
}

=item get_recs_by_name()

Returns an Array of Hash references representing the records, 
where each hash key is the NAME field from the survey definitions.

  my @recs = $sss->get_recs_by_name();
  foreach my $rec (@recs)
  {
    my $cost = $rec->{cost}; ## a VARIABLE with a NAME of 'cost' must exist.
    do_something_with($cost->{value});
  }

=cut

sub get_recs_by_name
{
  my ($self, %opts) = @_;
  my @recs = $self->get_recs(%opts);
  my @return;
  for my $rec (@recs)
  { ## We are only interested in the name index.
    push @return, $rec->{byname};
  }
  return @return;
}

=item get_recs_by_id()

Returns an Array of Hash references representing the records,
where each hash key is the VARIABLE ID from the survey definitions.

  my @recs = $sss->get_recs_by_id();
  foreach my $rec (@recs)
  {
    my $var15 = $rec->{15}; ## a VARIABLE with an ID of '15' must exist.
    do_something_with($var15->{value});
  }

=cut

sub get_recs_by_id
{
  my ($self, %opts) = @_;
  my @recs = $self->get_recs(%opts);
  my @return;
  for my $rec (@recs)
  { ## We are only interested in the id index.
    push @return, $rec->{byid};
  }
  return @return;
}

=back

=head1 TESTING

A full suite of tests are included in the 't' folder.
Just run 'prove' or 'prove -v' to run all the tests,
or run 'perl ./t/name-of-test.t' to run a single test.

=head1 DEPENDENCIES

Perl 5.10 or higher

=head1 BUGS AND LIMITATIONS

This library is written with the assumption that the Formatting Recommendations
in the specification have been followed, in particular recommendations 1 and 2.

=head1 AUTHOR

Timothy Totten <2010@huri.net>

=head1 LICENSE

Artistic License 2.0

=cut

## End of package.
1;