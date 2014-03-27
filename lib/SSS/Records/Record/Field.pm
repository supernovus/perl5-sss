package SSS::Records::Record::Field;

use Moo;

has 'variable' =>
(
  is       => 'ro',
  required => 1,
);

has 'rawvalue' =>
(
  is  => 'rw',
);

1;
