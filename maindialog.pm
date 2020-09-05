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
   $self->{e} = $mwdf->entries; # gridframe control values
   $self->{d} = $mwdf->addWideTextField(undef, 'exercisetext', 10, 75, '');
   $self->{d}->focus;
   $self->{timerid} = undef;
   $mwdf->{controls}->{exercisetext}->configure(-state=>'disabled');

   # buttons use callback by default
   $mwdf->addButtonField('Start', 'start',  's');
   $mwdf->addButtonField('Finish', 'finish',  'f');
   $mwdf->addButtonField('Quit', 'quit',  'q', sub{$self->{w}->destroy});

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
   $self->{d}->bind('<ButtonPress-1>', [\&clicked, 'd1', $self->{mwdf}, Ev('t')]); # automatically supplies a reference to $d as first argument
   $self->{d}->bind('<ButtonRelease-1>', [\&clicked, 'u1', $self->{mwdf}, Ev('t')]); # automatically supplies a reference to $d as first argument
   $self->{d}->bind('<ButtonPress-2>', [\&clicked, 'd2', $self->{mwdf}, Ev('t')]); # automatically supplies a reference to $d as first argument
   $self->{d}->bind('<ButtonRelease-2>', [\&clicked, 'u2', $self->{mwdf}, Ev('t')]); # automatically supplies a reference to $d as first argument
#   $self->{d}->bind('<Double-ButtonPress-1>', sub {Tk->break});

}

sub stopusertextinput {
   my $self = shift;

   $self->{d}->bind('<Button1-KeyPress>', undef);
   $self->{d}->bind('<Button1-KeyRelease>', undef);
   $self->{d}->bind('<Button2-KeyPress>', undef);
   $self->{d}->bind('<Button2-KeyRelease>', undef);
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

