package SSS::Definitions::Parser::XML;

use v5.10;
use Moo;
use Carp;
use XML::LibXML;

use SSS::Definitions::Variable;
use SSS::Definitions::Variable::Value;
use SSS::Definitions::Variable::Label;

#use Huri::Debug show=>['load_defs'];

## This MUST be the SSS::Definitions object that called us.
has 'parent' =>
(
  is       => 'ro',
  required => 1,
);

sub load_defs
{
  my ($self, $text, %opts) = @_;

  my @top_keys = ('date', 'time', 'origin', 'user');

  my $doc = XML::LibXML->load_xml(string => $text);
  my $sss = $doc->documentElement;

  my $ver = $sss->getAttribute('version');
  if ($ver eq '1.1' || $ver eq '1.2' || $ver eq '2.0')
  {
    $self->parent->sss_version($ver);
  }
  else
  {
    carp "Unsupported SSS version.";
    return;
  }

  if ($sss->hasAttribute('languages'))
  {
    my $langs = $sss->getAttribute('languages');
    $langs =~ s/^\s+//g;
    $langs =~ s/\s+$//g;
    my @langs = split(/\s+/, $langs);
    $self->parent->langs(\@langs);
  }
  if ($sss->hasAttribute('modes'))
  {
    my $modes = $sss->getAttribute('modes');
    $modes =~ s/^\s+//g;
    $modes =~ s/\s+$//g;
    my @modes = split(/\s+/, $modes);
    $self->parent->modes(\@modes);
  }

  my @statements = $sss->nonBlankChildNodes;

  for my $statement (@statements)
  {
    my $tag = $statement->nodeName;
    if ($tag eq 'hierarchy')
    {
      croak "Sorry, this version of the SSS library does not support Hierarchial data.";
    }
    elsif ($tag eq 'survey')
    {
      ## process survey tags here.
      $self->_process_survey($statement);
    }
    else
    {
      ## Top-level statement keys.
      for my $key (@top_keys)
      {
        if ($tag eq $key)
        {
          $self->parent->$key($statement->textContent);
          last;
        }
      }
    }
  }

}

sub _process_survey
{
  my ($self, $survey) = @_;

  my @survey_keys = ('name', 'version');

  my @statements = $survey->nonBlankChildNodes;

  for my $statement (@statements)
  {
    my $tag = $statement->nodeName;
    if ($tag eq 'record')
    {
      $self->_process_record($statement);
    }
    elsif ($tag eq 'title')
    {
      $self->_process_label($statement, $self->parent);
    }
    else
    {
      for my $key (@survey_keys)
      {
        if ($tag eq $key)
        {
          my $field = "survey_$key";
          $self->parent->$field($statement->textContent);
          last;
        }
      }
    }
  }
}

sub _process_record
{
  my ($self, $record) = @_;

  $self->parent->record_id($record->getAttribute('ident'));

  my @record_keys = ('format', 'skip');

  if ($record->hasAttribute('href'))
  {
    $self->parent->record_uri($record->getAttribute('href'));
  }

  for my $key (@record_keys)
  {
    if ($record->hasAttribute($key))
    {
      my $field = "record_$key";
      $self->parent->$field($record->getAttribute($key));
    }
  }

  my @variables = $record->nonBlankChildNodes;

  for my $variable (@variables)
  {
    $self->_process_variable($variable);
  }
}

sub _process_variable
{
  my ($self, $variable) = @_;

  my $vid  = $variable->getAttribute('ident');
  my $type = $variable->getAttribute('type');

  my $var = SSS::Definitions::Variable->new(id => $vid, type => $type);

  my @var_keys = ('use', 'format');

  for my $key (@var_keys)
  {
    if ($variable->hasAttribute($key))
    {
      $var->$key($variable->getAttribute($key));
    }
  }

  my @statements = $variable->nonBlankChildNodes;

  for my $statement (@statements)
  {
    my $tag = $statement->nodeName;
    if ($tag eq 'name')
    {
      $var->name($statement->textContent);
    }
    elsif ($tag eq 'label')
    {
      $self->_process_label($statement, $var);
    }
    elsif ($tag eq 'position')
    {
      my $start = $statement->getAttribute('start');
      $var->position_start($start);
      my $finish;
      if ($statement->hasAttribute('finish'))
      {
        $finish = $statement->getAttribute('finish');
      }
      else
      {
        $finish = $start;
      }
      $var->position_end($finish);

      if ($start == $finish)
      {
        $var->length(1);
      }
      else
      {
        $var->length($finish - ($start - 1));
      }
    }
    elsif ($tag eq 'filter')
    {
      $var->filter($statement->textContent);
    }
    elsif ($type eq 'character' && $tag eq 'size')
    {
      $var->size($statement->textContent);
    }
    elsif ($type eq 'multiple' && $tag eq 'spread')
    {
      $var->subfields($statement->getAttribute('subfields'));
      if ($statement->hasAttribute('width'))
      {
        $var->subfield_width($statement->getAttribute('width'));
      }
    }
    elsif 
    (
      ($type eq 'single' || $type eq 'multiple' || $type eq 'quantity')
      &&
      $tag eq 'values'
    ) 
    {
      my @values = $statement->nonBlankChildNodes;
      for my $value (@values)
      {
        my $valType = $value->nodeName;
        if ($valType eq 'range')
        {
          $var->range_start($value->getAttribute('from'));
          $var->range_end($value->getAttribute('to'));
        }
        elsif ($valType eq 'value')
        {
          my $code = $value->getAttribute('code');
          my $val = SSS::Definitions::Variable::Value->new(value => $code);
          if ($value->hasAttribute('score'))
          {
            $val->score($value->getAttribute('score'));
          }
          $self->_process_label($value, $val);
          $var->add_val($val);
        }
      }
    }
  }
  $self->parent->add_var($var);
}

## Used for anything that does the Labelled role.
sub _process_label
{
  my ($self, $label, $object) = @_;

  my @nodes = $label->nonBlankChildNodes;

  for my $node (@nodes)
  {
    my $type = $node->nodeType;
    if ($type == XML_TEXT_NODE)
    {
      $object->label($node->nodeValue);
    }
    elsif ($type == XML_ELEMENT_NODE)
    {
      my $label = SSS::Definitions::Variable::Label->new(
        text => $node->textContent
      );
      if ($node->hasAttribute('xml:lang'))
      {
        $label->lang($node->getAttribute('xml:lang'));
      }
      if ($node->hasAttribute('mode'))
      {
        $label->mode($node->getAttribute('mode'));
      }
      $object->add_label($label);
    }
  }
}

1;

