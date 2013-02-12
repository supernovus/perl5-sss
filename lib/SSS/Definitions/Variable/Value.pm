package SSS::Definitions::Variable::Value;

use Mouse;

with qw(SSS::Definitions::Labelled);

=item value

The Value value (aka the Value id.)

=cut

has 'value' =>
(
  is       => 'rw',
  isa      => 'Str',
  required => 1,
);

=item score

The Value score (optional, SSS XML 2.0+ only.)

=cut

has 'score' =>
(
  is  => 'rw',
  isa => 'Num',
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

1;
