package SSS::Records::Record::Field;

use Mouse;

has 'variable' =>
(
  is       => 'ro',
  isa      => 'SSS::Definitions::Variable',
  required => 1,
);

has 'rawvalue' =>
(
  is  => 'rw',
  isa => 'Str',
);

1;
