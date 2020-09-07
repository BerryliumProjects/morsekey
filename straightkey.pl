#! /usr/bin/perl 
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
use detectelements;

my $argwpm = ($ARGV[0] or 20);
my $elementDetector;
my $timerid;

my $elementsequence;

my $mdlg = MainDialog->init(\&mainwindowcallback);
my $e = $mdlg->{e};
my $d = $mdlg->{d};

$mdlg->show;
exit 0;

sub mainwindowcallback {
   my $id = shift; # name of control firing event
   my $ts = shift(); # time of event

   my $element = '';

   if ($id eq 'u1') {
      $element = $elementDetector->keyUp($ts);
      $mdlg->settimer($elementDetector->{pulseref} * 5);
   } elsif ($id eq 'd1') {
      $element = $elementDetector->keyDown($ts);
      $mdlg->canceltimer();
   } elsif ($id eq 'eow') {
      $element = $elementDetector->charGapTimeout();
   } elsif ($id eq 'start') {
      startAuto();
   } elsif ($id eq 'finish') {
      abortAuto();
   }

   print $element;

   if ($element =~ /[.-]/) {
      $elementsequence .= $element;
   } elsif ($element ne '') {
      my $char = codeIndex->{$elementsequence};

      if (defined $char) {
         $d->insert('end', $char);
      } else {
         # write dummy char to display
         $d->insert('end', '*');
      }

      if ($element eq "\n") {
         # write space to display
         $d->insert('end', ' ');
      }

      $elementsequence = ''
   }
}

sub startAuto {
   $elementDetector = DetectElements->init($argwpm);
   $elementsequence = '';

   my $wpm = $elementDetector->wpm();
   print "\nInitial wpm = $wpm\n";

   $d->Contents('');
   $d->focus;
 
   $mdlg->startusertextinput();
}

sub abortAuto {
   my $wpm = $elementDetector->wpm();
   print "\nFinal wpm = $wpm\n";

   my $elementpulses = $elementDetector->{elementpulses};

   if ($elementpulses->grandcount() > 0) {
      my $averagepulses = $elementpulses->averages();
      my $averagepulse = ($averagepulses->{'.'} + $averagepulses->{''} + $averagepulses->{'-'} / 3.0) / 3.0;
      my $ditratio = $averagepulses->{'.'} / $averagepulse;
      my $dahratio = $averagepulses->{'-'} / $averagepulse;
      my $chargapratio = $averagepulses->{' '} / $averagepulse;

      printf("Dit mark/space ratio: %5.2f\n",  $ditratio);
      printf("Dah mark/space ratio: %5.2f\n",  $dahratio);
      printf("Character gap ratio:  %5.2f\n",  $chargapratio);
   }

   $mdlg->stopusertextinput(); 
}


