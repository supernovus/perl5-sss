package SSS::Definitions::Variable;

use Moo;

with qw(SSS::Definitions::Labelled);

=item id

The VARIABLE ID

=cut

has 'id' =>
(
  is       => 'ro',
  required => 1,
);

=item name

The VARIABLE NAME

=cut

has 'name' =>
(
  is       => 'rw',
);

=item type

The VARIABLE TYPE

=cut

has 'type' =>
(
  is  => 'rw',
);

=item values

The VALUES as a flat array, in originally defined order.

=cut

has 'values' =>
(
  is      => 'ro',
  default => sub { [] },
);

=item values_by_id

The VALUES as a Hash, where the key is the value "id".

=cut

has 'values_by_id' =>
(
  is      => 'ro',
  default => sub { {} },
);

=item position_start

The starting point of the variable.

=cut

has 'position_start' =>
(
  is  => 'rw',
);

=item position_end

The end point of the variable.

=cut

has 'position_end' =>
(
  is  => 'rw',
);

=item length

Length of the variable.

=cut

has 'length' =>
(
  is  => 'rw',
);

=item size

Size of the character data.

=cut

has 'size' =>
(
  is  => 'rw',
);

=item range_start

If set, the beginning of our implicit values.

=cut

has 'range_start' =>
(
  is  => 'rw',
);

=item range_end

If set, the end of our implicit values.

=cut

has 'range_end' =>
(
  is  => 'rw',
);

=item subfields

Number of subfields in a spread.

=cut

has 'subfields' =>
(
  is  => 'rw',
);

=item subfield_width

Width of subfields.

=cut

has 'subfield_width' =>
(
  is      => 'rw',
  lazy    => 1,
  builder => 1,
);

sub _build_subfield_width
{
  my ($self) = @_;
  return $self->length / $self->subfields;
}

=item use

The variable use, SSS XML 1.2+ only.

=cut

has 'use' =>
(
  is  => 'rw',
);

=item format

The variable format, SSS XML 2.0+ only.

=cut

has 'format' =>
(
  is      => 'rw',
  default => 'numeric',
);

=item add_val ($value_object)

Adds a new explicit value to our valid list of values.

=cut

sub add_val
{
  my ($self, $value) = @_;
  push (@{$self->values}, $value);
  my $raw = $value->value;
  $self->values_by_id->{$raw} = $value;
}

1;

