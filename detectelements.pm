package DetectElements;

use strict;
use warnings;

use Tk;
use Tk::ROText;
use Tk::DialogBox;

use Data::Dumper;
use Tk::After;
use IO::Handle;
use Time::HiRes qw(time usleep);
use dialogfields;
use maindialog;
use histogram;
use charcodes;

sub init {
   my $class = shift;
   my $initwpm = shift;
   my $self = {};
   $self->{prevtimems} = undef;
   $self->{reftotal} = 60 / $initwpm * 1000; # one standard word
   $self->{pulsecnt} = 50;
   $self->{pulseref}  =  $self->{reftotal} / $self->{pulsecnt};
   $self->{markstate} = undef;
   $self->{elementpulses} = Histogram->new();

   return bless($self, $class);
}
   
sub wpm {
   my $self = shift;
   return int(1200 / $self->{pulseref} + 0.5);
}

my $timerid;

my $elementsequence;

sub keyUp { # detect a dit or dah
   my $self = shift;
   my $ts = shift; # time of event

   my $element = '';

   $self->{markstate} = undef;
   my $markpulses = ($ts - $self->{prevtimems}) / $self->{pulseref};
   $self->{prevtimems} = $ts;

   if ($markpulses > 2) {
      $element = '-';
      $self->{elementpulses}->add($element, $markpulses);
      $self->updateWpm($markpulses, 3);
   } elsif ($markpulses > 0.33) {
      $element = '.';
      $self->{elementpulses}->add($element, $markpulses);
      $self->updateWpm($markpulses, 1);
   }

   return $element;
}


sub keyDown { # start a dit or dah
   my $self = shift;
   my $ts = shift; # time of event;

   my $element = '';

   $self->{markstate} = 1;

   if (defined $self->{prevtimems}) {
      my $spacepulses = ($ts - $self->{prevtimems}) / $self->{pulseref};

      if ($spacepulses > 2) { # if reached minimum for inter-word gap, prevtimems will be undef
         $element = ' ';
         $self->{elementpulses}->add($element, $spacepulses);
      } elsif ($spacepulses > 0.33) {
         $self->{elementpulses}->add($element, $spacepulses);
         $self->updateWpm($spacepulses, 1);
      }
   }

   $self->{prevtimems} = $ts;
   return $element;
}

sub charGapTimeout { # gap long enough to count as the end of a word
   my $self = shift;

   my $element = '';

   if(not $self->{markstate}) {
      $element = "\n";
   }

   $self->{prevtimems} = undef; # don't also detect character gap
   return $element;
}

sub updateWpm {
   my $self = shift;
   my $elementpulses = shift;
   my $pulses = shift;
   $self->{reftotal} += $elementpulses * $self->{pulseref};
   $self->{pulsecnt} += $pulses;
   $self->{pulseref}  =  $self->{reftotal} / $self->{pulsecnt};

   if ($self->{pulsecnt} > 100) { # maintain agility in adapting to actual keying rate
      $self->{pulsecnt} = int($self->{pulsecnt} / 2);
      $self->{reftotal} = $self->{pulsecnt} * $self->{pulseref};
   }
}

1;
