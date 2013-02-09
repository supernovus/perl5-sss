sub load_recs
{
  my ($self, %opts) = @_;
  my @lines;
  if ($opts{file})
  {
    my $file = $opts{file};
    if (!$file || !-f $file) { croak "Missing or invalid records file."; }
    open (my $infile, $file);
    @lines = <$infile>;
    close $infile;
  }
  elsif ($opts{text})
  {
    @lines = split(/\n/, $opts{text});
  }
  else { croak "Either a file or text parameter is required in load_recs()"; }

  my @defs = $self->parent->get_vars(); 

  for my $line (@lines)
  { ## First, let's store the raw record.
    chomp($line);
    my $rec =
    {
      raw     => $line,
      byname  => {},
      byid    => {},
      ordered => [],
    };
    ## Next, let's process our known definitions.
    foreach my $var (@defs)
    { 
      my $start  = $var->{start}-1;
      my $finish = $var->{finish};
      my $length = $var->{length};
      my $id     = $var->{id};
      my $name   = $var->{name};
      my $recspec = {};
      $rec->{byname}->{$name} = $recspec;
      $rec->{byid}->{$id}     = $recspec;
      push(@{$rec->{ordered}}, $recspec);      
      ## Okay, let's get the value.
      my $rawvalue = substr($line, $start, $length);
      $recspec->{rawvalue} = $rawvalue;
      my $value = $rawvalue;
      $value =~ s/^\s*//g; # strip leading whitespace.
      $value =~ s/\s*$//g; # strip trailing whitespace.
      $recspec->{value} = $value;

      if ($var->{type} eq 'MULTIPLE')
      { ## Okay, let's process multiples.
        my $multiples = 
        {
          byid    => {}, ## Indexed by value id.
          ordered => [], ## Indexed by original order.
        };
        my @cats = @{$var->{values}->{cats}->{ordered}};
        my $catcount = scalar @cats;
        my $reccount = length($rawvalue);
        if (exists $var->{subfields})
        { ## We're in SPREAD format.
          my $subfields = $var->{subfields};
          ## Okay, we're going to generate a cache of known values.
          my @found;
          my $width = $var->{width};
          for (my $st = 0; $st <= $reccount - $width; $st += $width)
          { ## Find our values.
            my $inval = substr($rawvalue, $st, $width);
            my $imval = 
            {
              value => $inval
            };
            push @found, $imval;
          }
          ## Now let's set our data.
          foreach my $cat (@cats)
          { ## Let's see if we are set.
            my $key = $cat->{id};
            my $subval = 0;
            foreach my $found (@found)
            { my $fval = $found->{value};
              if ($fval =~ /^\s*$/) { next; } ## skip empty.
              ##[load_recs] Comparing $key to $fval
              if ($fval == $key)
              {
                $subval = 1;
                $found->{text} = $cat->{text};  ## reference.
              }
            }
            my $mval = 
            {
              value => $subval,
              text  => $cat->{text},  ## reference.
            };
            $multiples->{byid}->{$key} = $mval;
            #push(@{$multiples->{ordered}}, $mval);
          }
          $multiples->{ordered} = \@found;
        }
        else
        { ## We're in Bitstring format.
          if ($reccount < $catcount)
          { ## You can't have a field smaller than the number of values.
            croak "Field size ($catcount) is smaller than values ($reccount) on variable $name";
          }
          foreach my $cat (@cats)
          { ## Let's get our subvalue.
            my $key = $cat->{id};
            my $start = $key - 1;
            my $subval = substr($rawvalue, $start, 1);
            my $mval = {};
            $mval->{value} = $subval;
            $mval->{text}  = $cat->{text}; ## reference.
            $multiples->{byid}->{$key} = $mval;
            push(@{$multiples->{ordered}}, $mval);
          }
        }
        $recspec->{values} = $multiples;
      }
      else
      { ## We're not a multiple, let's see if we have values.
        if (exists $var->{values} && exists $var->{values}->{cats}->{byid}->{$value})
        {
          $recspec->{text} = $var->{values}->{cats}->{byid}->{$value}->{text};
        }
      }
    }
    push(@{$self->recs}, $rec);
  }
}


