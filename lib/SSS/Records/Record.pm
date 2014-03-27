package SSS::Records::Record;

use Moo;

has 'raw' =>
(
  is  => 'rw',
);

has 'fields' =>
(
  is      => 'ro',
  default => sub { [] },
);

has 'fields_by_id' =>
(
  is      => 'ro',
  default => sub { {} }, 
);

has 'fields_by_name' =>
(
  is      => 'ro',
  default => sub { {} },
);

sub add_field
{
  my ($self, $field) = @_;

  $self->fields_by_id->{$field->variable->id} = $field;
  $self->fields_by_name->{$field->variable->name} = $field;
  push(@{$self->fields}, $field);

}

1;

