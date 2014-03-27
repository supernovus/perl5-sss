package SSS::Records::Parser::Fixed;

use v5.10;
use Moo;
use Carp;

use SSS::Records::Record;
use SSS::Records::Record::Field::Singular;
use SSS::Records::Record::Field::Spread;
use SSS::Records::Record::Field::Bitstring;

## This MUST be the SSS::Records object that called us.
has 'parent' =>
(
  is       => 'ro',
  required => 1,
);

sub load_recs
{
  my ($self, $text, %opts) = @_;
  
  my @lines = split(/[\n\r]+/, $text);

  my @vars = @{$self->parent->parent->vars};

  for my $line (@lines)
  {
    chomp($line);
    my $record = SSS::Records::Record->new(raw => $line);
    for my $var (@vars)
    {
      my $start  = $var->position_start - 1;
      my $length = $var->length;

      my $rawvalue = substr($line, $start, $length);

      my $type = lc($var->type);

      my $field; ## Will be populated by the correct object.

      if ($type eq 'multiple')
      {
        ## MULTIPLE record type.
        my $reccount = length $rawvalue;

        if ($var->subfields)
        {
          ## We're in Spread format.
          $field = SSS::Records::Record::Field::Spread->new(
            variable => $var,
            rawvalue => $rawvalue,
          );
          my $width = $var->subfield_width;
          for (my $st = 0; $st <= $reccount - $width; $st += $width)
          {
            my $inval = substr($rawvalue, $st, $width);
            $inval =~ s/^0+//g;
            if ($inval)
            {
              $field->add_value($inval);
            }
          }
        }
        else
        {
          ## We're in Bitstring format.
          $field = SSS::Records::Record::Field::Bitstring->new(
            variable => $var,
            rawvalue => $rawvalue,
          );

          my @values = @{$var->values};
          my $valcount = scalar @values;

          if ($reccount < $valcount)
          {
            carp "The field length is shorter than the number of values.";
            return;
          }

          foreach my $value (@values)
          {
            my $val = $value->value;
            my $offset = $val - 1; ## The SSS spec says value is position.
            if ($reccount < $offset)
            {
              carp "A value was longer than the field.";
              return;
            }
            my $subval = substr($rawvalue, $offset, 1);
            if ($subval)
            {
              $field->add_value($val);
            }
          }
        }
      }
      else
      {
        ## A singular record type.
        my $strvalue = $rawvalue;
        $strvalue =~ s/^\s*//g; ## Strip leading whitespace.
        $strvalue =~ s/\s*$//g; ## Strip trailing whitespace.
        $field = SSS::Records::Record::Field::Singular->new(
          variable => $var,
          rawvalue => $rawvalue,
          value => $strvalue,
        );
      }
      
      $record->add_field($field);
    }

    push(@{$self->parent->records}, $record);
  }

}

1;
