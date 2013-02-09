package SSS::Records::Record::Field::Multiple;

use Mouse;

#use Huri::Debug show => ['values'];

extends 'SSS::Records::Record::Field';

has 'realvalues' =>
(
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);

has 'realvalues_cache' =>
(
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

sub add_value
{
  my ($self, $value) = @_;
  push(@{$self->realvalues}, $value);
  $self->realvalues_cache->{$value} = 1;
}

sub has_value
{
  my ($self, $value) = @_;
  return exists $self->realvalues_cache->{$value};
}

sub values
{
  my ($self) = @_;
  my %values = %{$self->variable->values_by_id};
  my @results;
  for my $real (@{$self->realvalues})
  {
    ##[values]= $real
    if (exists $values{$real})
    {
      push(@results, $values{$real});
    }
    else
    {
      push(@results, $real);
    }
  }
  return \@results;
}

1;

