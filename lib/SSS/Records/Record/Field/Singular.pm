package SSS::Records::Record::Field::Singular;

use Mouse;

extends 'SSS::Records::Record::Field';

has 'value' =>
(
  is  => 'rw',
  isa => 'Str',
);

sub get_value
{
  my ($self) = @_;
  my $id = $self->value;
  my %values = %{$self->variable->values_by_id};
  if (exists $values{$id})
  {
    return $values{$id};
  }
  else
  {
    return $id;
  }
}

sub label
{
  my ($self, $lang) = @_;
  my $val = $self->get_value;
  if (defined $val && ref $val eq 'SSS::Definitions::Variable::Value')
  {
    if ($lang)
    {
      return $val->get_label($lang);
    }
    else
    {
      return $val->label;
    }
  }
  return;
}

1;
