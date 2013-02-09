package SSS::Records::Record::Field::Spread;

use v5.10;
use Mouse;

extends 'SSS::Records::Record::Field::Multiple';

#use Huri::Debug show => ['values'];

sub values_by_id
{
  my ($self) = @_;
  my @values = @{$self->variable->values};
  my @haveit = @{$self->realvalues};
  my %results;
  ##[values]= @haveit
  for my $value (@values)
  {
    my $valid = $value->value;
    ##[values]= $valid
    my $found = 0;
    for my $have (@haveit)
    {
      if ($valid == $have)
      {
        $results{$valid} = 1;
        $found = 1;
        last;
      }
    }
    if (!$found)
    {
      $results{$valid} = 0;
    }
  }
  return \%results;
}

1;
