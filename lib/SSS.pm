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

use v5.10;
use strict;
use warnings;
use Carp;

## Private method for debugging purposes.
##   $self->debug($level, $message);
sub debug
{
  my $self = shift;
  my $level = shift;
  if ($self->{debug} >= $level) {
    print "# ";
    say @_;
  }
}

=head1 PUBLIC METHODS

=over 1

=item new()

Create a new SSS object. Does not load any data.

  my $sss = SSS->new();

=cut

sub new
{ 
  my $class = shift;
  my $self  = 
  { 
    debug => 0,           # set to different levels of debugging details.
    defs  =>              # survey definition, stored in a '.sss' file.
    {
      vars =>             # the variables defined in the survey.
      {
        byname  => {},     # Lookup done by NAME field.
        byid    => {},     # Lookup done by VARIABLE id.
        ordered => [],     # A plain ordered array.
      },
    },              
    recs  => [],          # records, stored in a '.asc' file.
  };
  bless $self, $class;
  return $self;
}

=item load_defs()

Load a definition file (.sss extension)

  $sss->load_defs("survey.sss");

=cut

sub load_defs
{
  my ($self, $file) = @_;
  my ($variable, $values); ## Private members for storage of VARIABLE and VALUES.
  my @topkeys = ('date', 'time', 'origin', 'user', 'title');
  my @varkeys = ('name', 'label');
  my @types = ('SINGLE', 'MULTIPLE', 'QUANTITY', 'CHARACTER', 'LOGICAL');
  if (!$file || !-f $file) { croak "Missing or invalid definition file."; }
  open (my $in, $file);
  my @lines = <$in>;
  $self->debug(2, "== Definitions ==");
  for my $line (@lines)
  {
    chomp($line);
    $self->debug(2, $line);
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
          $values->{cats}->{$1} = 
          { 
            text => $2,
          };
          if ($3)
          {
            $values->{cats}->{$1}->{special} = 1;
          }
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
          }
          else
          {
            $variable->{finish} = $1;
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
              cats => {},   # Storage of labeled categories.
            };
          }
        }
        when (/^\s*END\s*VARIABLE\s*$/i)
        { ## End a variable block.
          ## You can look them up by id, name, or an ordered array.
          my $id = $variable->{id};
          $self->{defs}->{vars}->{byid}->{$id} = $variable;
          if (exists $variable->{name})
          {
            my $name = $variable->{name};
            $self->{defs}->{vars}->{byname}->{$name} = $variable;
          }
          push(@{$self->{defs}->{vars}->{ordered}}, $variable);
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
            $self->{defs}->{$key} = $1;
          }
        }
        when (/^\s*RECORD\s*(\w)\s*$/i)
        { ## Record ID
          $self->{defs}->{record} = $1;
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
  ## TODO: implement me.
  croak "Not implemented yet.";
}

=back

=head1 TESTING

A full suite of tests are included in the 't' folder.
Just run 'prove' or 'prove -v' to run all the tests,
or run 'perl ./t/name-of-test.t' to run a single test.

=head1 DEPENDENCIES

Perl 5.10 or higher

=head1 BUGS AND LIMITATIONS

None to report yet.

=head1 AUTHOR

Timothy Totten <2010@huri.net>

=cut

## End of package.
1;