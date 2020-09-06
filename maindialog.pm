#! /usr/bin/perlntervalms = shift;
 
package MainDialog;

use strict;
use warnings;

use Tk;
use Tk::ROText;
use Tk::DialogBox;

use Data::Dumper;
use Tk::After;

use dialogfields;

sub init {
   my $class = shift;
   my $callback = shift;

   my $self = {};
   bless($self, $class);

   $self->{w} = MainWindow->new();

   $self->{w}->fontCreate('msgbox',-family=>'helvetica', -size=>-14);

   my $mwdf = $self->{mwdf} = DialogFields->init($self->{w},$callback,300);

   my $clickarea = $self->{mwdf}->{g}->Label(-text=>'Click here to enter Morse code with left mouse button', -font=>'msgbox', -height=>10, -background=>'white', -padx=>20);
   $clickarea->grid(-row=>1, -column=>1, -columnspan=>2, -pady=>10);
   $self->{c} = $clickarea;

   $self->{e} = $mwdf->entries; # gridframe control values
   $self->{d} = $mwdf->addWideTextField(undef, 'exercisetext', 10, 75, '');
   $self->{timerid} = undef;

   # buttons use callback by default
   $mwdf->addButtonField('Start', 'start',  's');
   $mwdf->addButtonField('Finish', 'finish',  'f');
   $mwdf->addButtonField('Quit', 'quit',  'q', sub{$self->{w}->destroy});

   $self->{mwdf}->{controls}->{finish}->configure(-state=>'disabled');
   $self->{mwdf}->{controls}->{start}->configure(-state=>'normal');

   return $self;
}

sub show {
   my $self = shift; 
   $self->{w}->MainLoop();
}

sub eow {
   my $self = shift;
   my $ch = 'eow';
   my $callback = $self->{mwdf}->{callback};
   &$callback($ch);
   $self->{timerid} = undef;
}

sub clicked {
   my $obj = shift; # automatically supplied reference to callback sender
   my $ch = shift;
   my $mwdf = shift;
   my $ts = shift;
   my $callback = $mwdf->{callback};
   &$callback($ch, $ts);
}

sub startusertextinput {
   my $self = shift;

#   $self->{d}->bind('<KeyPress>', [\&clicked, Ev('s'), $self->{mwdf}]); # automatically supplies a reference to $d as first argument
   $self->{c}->bind('<ButtonPress-1>', [\&clicked, 'd1', $self->{mwdf}, Ev('t')]); # automatically supplies a reference to $d as first argument
   $self->{c}->bind('<ButtonRelease-1>', [\&clicked, 'u1', $self->{mwdf}, Ev('t')]); # automatically supplies a reference to $d as first argument

   $self->{mwdf}->{controls}->{finish}->configure(-state=>'normal');
   $self->{mwdf}->{controls}->{start}->configure(-state=>'disabled');
}

sub stopusertextinput {
   my $self = shift;

   $self->{c}->bind('<Button1-KeyPress>', undef);
   $self->{c}->bind('<Button1-KeyRelease>', undef);
   $self->{c}->bind('<Button2-KeyPress>', undef);
   $self->{c}->bind('<Button2-KeyRelease>', undef);

   $self->{mwdf}->{controls}->{finish}->configure(-state=>'disabled');
   $self->{mwdf}->{controls}->{start}->configure(-state=>'normal');
}

sub settimer {
   my $self = shift;
   my $intervalms = shift;

   $self->{timerid} = $self->{w}->after($intervalms, sub {$self->eow()});
}

sub canceltimer {
   my $self = shift;

   if ($self->{timerid}) {
      $self->{w}->afterCancel($self->{timerid});
      $self->{timerid} = undef;
   }
}

1;

