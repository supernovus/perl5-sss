package SSS::Definitions::Labelled;

use Moo::Role;

=item label

The default Value label. There may also be language-specific labels.

=cut

has 'label' =>
(
  is       => 'rw',
);

=item labels

Specialized labels. SSS XML 1.2+ only.

=cut

has 'labels' =>
(
  is      => 'ro',
  default => sub { [] },
);

=item add_label()

Used by the XML parser to add a new Label object to our list of labels.

=cut

sub add_label
{
  my ($self, $label) = @_;
  push(@{$self->labels}, $label);
}

=item get_label(lang=>$lang, mode=>$mode)

Look up a specialized language by desired language and/or mode.

=cut

sub get_label
{
  my ($self, %query) = @_;
  for my $label (@{$self->labels})
  {
    if (exists $query{lang})
    {
      if ($label->lang ne $query{lang}) { next; }
    }
    if (exists $query{mode})
    {
      if ($label->mode ne $query{mode} && $label->mode ne '_DEFAULT_')
      {
        next;
      }
    }
    return $label;
  }
  ## If we reached here, we didn't find what we were looking for, so we
  ## return the default label.
  return $self->label;
}

1;
