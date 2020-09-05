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

my $argwpm = ($ARGV[0] or 20);
updateWpm(60 / $argwpm * 1000, 50); # One standard word

my $prevtimems;
my $pulseref;
my $pulsecnt;
my $reftotal;
my $wpm;

my $markstate;
my $timerid;

my $mdlg = MainDialog->init(\&mainwindowcallback);
my $e = $mdlg->{e};
my $d = $mdlg->{d};

$mdlg->show;
exit 0;

sub mainwindowcallback {
   my $id = shift; # name of control firing event
   my $ts = shift(); # time of event

   my $mindit = $pulseref / 3;
   my $mindah = $pulseref * 2;
   my $minchargap = $pulseref * 2;
   my $minwordgap = $pulseref * 5;
   my $element = '';

   if ($id eq 'u1') {
      $markstate = undef;
      my $marktime = $ts - $prevtimems;
      $prevtimems = $ts;

      if ($marktime > $mindah) {
	 $element = '-';
         updateWpm ($marktime, 3);
      } elsif ($marktime > $mindit) {
         $element = '.';
         updateWpm ($marktime, 1);
      }

      $mdlg->settimer($minwordgap);
   } elsif ($id eq 'd1') {
      $markstate = 1;

      if (defined $prevtimems) {
         my $spacetime = $ts - $prevtimems;

         if ($spacetime > $minchargap) { # if reached minimum for inter-word gap, prevtimems will be undef
            $element = ' ';
         } elsif ($spacetime > $mindit) {
            updateWpm ($spacetime, 1);
         }
      }

      $prevtimems = $ts;
      $mdlg->canceltimer();
   } elsif ($id eq 'eow') {
      if(not $markstate) {
         $element = "\n";
      }

      $prevtimems = undef;
   } elsif ($id eq 'start') {
      startAuto();
   } elsif ($id eq 'finish') {
      abortAuto();
   }

   print $element;
}

sub startAuto {
   $prevtimems = undef;
   $markstate = undef;
   print "\nInitial wpm = $wpm\n";

   $d->Contents('');
   $d->focus;
 
   $mdlg->startusertextinput();
}

sub abortAuto {
   print "\nFinal wpm = $wpm\n";
   $mdlg->stopusertextinput(); 
}

sub updateWpm {
   my $elementtime = shift;
   my $pulses = shift;
   $reftotal += $elementtime;
   $pulsecnt += $pulses;
   $pulseref  =  $reftotal / $pulsecnt;
   $wpm = int(1200 / $pulseref + 0.5);

   if ($pulsecnt > 100) { # maintain agility in adapting to actual keying rate
      $pulsecnt = int($pulsecnt / 2);
      $reftotal = $pulsecnt * $pulseref;
   }
}