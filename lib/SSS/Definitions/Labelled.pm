package SSS::Definitions::Labelled;

use Mouse::Role;

=item label

The default Value label. There may also be language-specific labels.

=cut

has 'label' =>
(
  is       => 'rw',
  isa      => 'Str',
);

=item labels

Specialized labels. SSS XML 1.2+ only.

=cut

has 'labels' =>
(
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);

=item labels_by_lang

The label objects, indexed by language. SSS XML 1.2+ only.

=cut

has 'labels_by_lang' =>
(
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

=item labels_by_mode

The label objects, indexed by mode. SSS XML 2.0+ only.

=cut

has 'labels_by_mode' =>
(
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

=item add_label()

Used by the XML parser to add a new Label object to our list of labels.

=cut

sub add_label
{
  my ($self, $label) = @_;
  push(@{$self->labels}, $label);
  my $lang = $label->lang;
  $self->labels_by_lang->{$lang} = $label;
  my $mode = $label->mode;
  $self->labels_by_mode->{$mode} = $label;
}

1;
