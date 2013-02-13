package SSS::Records::Record;

use Mouse;

has 'raw' =>
(
  is  => 'rw',
  isa => 'Str',
);

has 'fields' =>
(
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);

has 'fields_by_id' =>
(
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} }, 
);

has 'fields_by_name' =>
(
  is      => 'ro',
  isa     => 'HashRef',
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

