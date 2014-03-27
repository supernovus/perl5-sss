package SSS::Definitions::Variable::Label;

use Moo;

=item text

The string content of the label.

=cut

has 'text' =>
(
  is       => 'rw',
  required => 1,
);

=item lang

The language of the label.

If undefined, defaults to a magic language called '_DEFAULT_'.

=cut

has 'lang' =>
(
  is      => 'rw',
  default => sub { '_DEFAULT_' },
);

=item mode

The "mode" of the label.

If undefined, defaults to a magic mode called '_DEFAULT_'.

=cut

has 'mode' =>
(
  is      => 'rw',
  default => sub { '_DEFAULT_' },
);

1;
