package SSS::Records::Record::Field::Bitstring;

use Mouse;

extends 'SSS::Records::Record::Field::Multiple';

#use Huri::Debug show => ['values'];

sub values_by_id
{
  my ($self) = @_;
  my %values = %{$self->variable->values_by_id};
  my %haveit = %{$self->realvalues_cache};
  my %results;
  for my $valid (keys %values)
  {
    if ($haveit{$valid})
    {
      $results{$valid} = 1;
    }
    else
    {
      $results{$valid} = 0;
    }
  }
  return \%results;
}

1;
