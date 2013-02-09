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

sub fields_by_id
{
  my ($self) = @_;
  my %fields;
  for my $field (@{$self->fields})
  {
    my $id = $field->variable->id;
    $fields{$id} = $field;
  }
  return \%fields;
}

sub fields_by_name
{
  my ($self) = @_;
  my %fields;
  for my $field (@{$self->fields})
  {
    my $name = $field->variable->name;
    $fields{$name} = $field;
  }
  return \%fields;
}

sub add_field
{
  my ($self, $field) = @_;

  push(@{$self->fields}, $field);

}

1;

