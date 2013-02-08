package SSS::Definitions::Variable::Value;

use Mouse;

=item value

The Value value (aka the Value id.)

=cut

has 'value' =>
(
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

=item label

The default Value label. There may also be language-specific labels.

=cut

has 'label' =>
(
  is       => 'rw',
  isa      => 'Str',
);

=item labels

Language-specific labels. SSS XML 1.2+ only.

=cut

has 'labels' =>
(
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

=item special

Used in SSS Classic 1.1 only, to mark "special" values.

=cut

has 'special' =>
(
  is      => 'rw',
  isa     => 'Bool',
  default => 0,
);

=item get_label($language)

See if a label for the requested language exists. 
If it does, return it. If it doesn't return the default label.

=cut

sub get_label
{
  my ($self, $lang) = @_;
  if (exists $self->labels->{$lang})
  {
    return $self->labels->{$lang};
  }
  else
  {
    return $self->label;
  }
}

1;
