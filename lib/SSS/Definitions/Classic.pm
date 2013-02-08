package SSS::Definitions::Classic;

use v5.10;
use Mouse;
use Carp;
use Text::ParseWords;

use SSS::Definitions::Variable;
use SSS::Definitions::Variable::Value;

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
  my @tokens = quotewords('\s+', 0, $text);

  my ($survey, $record, $variable, $values); ## Storage of internals.
  my @top_keys = ('date', 'time', 'origin', 'user');
  my @survey_keys = ('title', 'version', 'title');
  my @var_keys = ('name', 'label', 'type');

  my (@include, @exclude); ## Filters. May be useful in certain cases.

  my $tc = @tokens;

  TOKEN: for (my $i = 0; $i < $tc; $i++)
  {
    ## The current token. Used in all but VALUE blocks.
    my $tok; 
    if (!defined $values)
    {
      $tok = lc($tokens[$i]);
    }

    if (defined $values)
    {
      ## Process VALUE blocks.
      $tok = $tokens[$i];
      ##[load_defs]= $tok
      if (lc($tok) eq 'end' && lc($tokens[$i+1]) eq 'values')
      {
        ##[load_defs] end value.
        undef $values;
        $i++;
        next TOKEN;
      }
      elsif (lc($tokens[$i+1]) eq 'to')
      {
        $variable->range_start($tok);
        $i++;
        my $range_end = $tokens[++$i];
        $variable->range_end($range_end);
        next TOKEN;
      }
      else
      {
        my $label = $tokens[++$i];
        my $value = SSS::Definitions::Variable::Value->new(value => $tok, label => $label);
        if (lc($tokens[$i+1]) eq 'special')
        {
          $value->special(1);
          $i++;
        }
        $variable->add_val($value);
        next TOKEN;
      }
    }
    elsif (defined $variable)
    {
      ## Process VARIABLE blocks.
      for my $key (@var_keys)
      {
        if ($tok eq $key)
        {
          $variable->$key($tokens[++$i]);
          next TOKEN;
        }
      }

      ## POSITION command.
      if ($tok eq 'position')
      {
        my $start = $tokens[++$i];
        $variable->position_start($start);
        if (lc($tokens[$i+1]) eq 'to')
        {
          $i++; ## Skip ahead to the TO statement.
          my $finish = $tokens[++$i];
          $variable->position_end($finish);
          if ($start == $finish)
          {
            $variable->length(1);
          }
          else
          {
            $variable->length($finish - ($start - 1));
          }
        }
        else
        {
          $variable->position_end($start);
          $variable->length(1);
        }
        next TOKEN;
      }

      ## Now, type-specific command tokens.
      if (defined $variable->type)
      {
        my $type = lc($variable->type);
        if ($type eq 'character')
        {
          if ($tok eq 'size')
          {
            $variable->size($tokens[++$i]);
            next TOKEN;
          }
        }
        elsif ($type eq 'single' || $type eq 'multiple' || $type eq 'quantity')
        {
          if ($type eq 'multiple')
          {
            if ($tok eq 'spread')
            {
              my $subfields = $tokens[++$i];
              $variable->subfields($subfields);
              if (lc($tokens[$i+1]) eq 'of')
              {
                $i++; ## Skip ahead to the OF statement.
                my $width = $tokens[++$i];
                $variable->subfield_width($width);
              }
              next TOKEN;
            }
          }
          if ($tok eq 'values')
          {
            $values = 1; ## Parsing values now.
            next TOKEN;
          }
        }
      }
      if ($tok eq 'end' && lc($tokens[$i+1]) eq 'variable')
      {
        $self->parent->add_var($variable);
        undef $variable;
        $i++;
        next TOKEN;
      }
    }
    elsif (defined $record)
    {
      ## Process directives within the RECORD block.
      if ($tok eq 'variable')
      {
        $variable = SSS::Definitions::Variable->new(id => $tokens[++$i]);
        next TOKEN;
      }
      elsif ($tok eq 'end' && lc($tokens[$i+1]) eq 'record')
      {
        undef $record;
        $i++;
        next TOKEN;
      }
    }
    elsif (defined $survey)
    {
      ## Process directives within the SURVEY block.
      for my $key (@survey_keys)
      {
        if ($tok eq $key)
        {
          my $field = "survey_$key";
          $self->parent->$field($tokens[++$i]);
          next TOKEN;
        }
      }
      if ($tok eq 'record')
      {
        $record = $tokens[++$i];
        $self->parent->record_id($record);
        next TOKEN;
      }
      elsif ($tok eq 'end' && lc($tokens[$i+1]) eq 'survey')
      {
        undef $survey;
        $i++;
        next TOKEN;
      }
    }
    else
    {
      for my $key (@top_keys)
      {
        if ($tok eq $key)
        {
          $self->parent->$key($tokens[++$i]);
          next TOKEN;
        }
      }
      if ($tok eq 'survey')
      {
        $survey = 1; ## We're in the survey.
      }
      elsif ($tok eq 'version')
      {
        if ($tokens[$i+1] ne '1.1')
        {
          carp "Unsupported SSS version.";
          return;
        }
        $i++;
        next TOKEN;
      }
      elsif ($tok eq 'end' && lc($tokens[$i+1]) eq 'sss')
      {
        return; ## No further processing past the END SSS statement.
      }
    }
  }
}

1;

