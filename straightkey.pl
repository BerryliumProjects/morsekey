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

my $initwpm = 20;

my $prevtimems;
my $pulsecnt = 10; 
my $reftotal = 1200 / $initwpm * $pulsecnt;

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

   my $pulseref = $reftotal / $pulsecnt;
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
         $reftotal += $marktime;
         $pulsecnt += 3;
      } elsif ($marktime > $mindit) {
         $element = '.';
         $reftotal += $marktime;
         $pulsecnt += 1;
      }

      $mdlg->settimer($minwordgap);
   } elsif ($id eq 'd1') {
      $markstate = 1;

      if (defined $prevtimems) {
         my $spacetime = $ts - $prevtimems;

         if ($spacetime > $minchargap) { # if reached minimum for inter-word gap, prevtimems will be undef
            $element = ' ';
         } elsif ($spacetime > $mindit) {
            $reftotal += $spacetime;
            $pulsecnt += 1;
         }
      }

      $prevtimems = $ts;
      $mdlg->canceltimer();
   } elsif ($id eq 'eow') {
      if(not $markstate) {
         $element = "\n";
      } else {print "*";}; ### diags
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
   $pulsecnt = 10; 
   $reftotal = 1200 / $initwpm * $pulsecnt;
   print "\nInitial wpm = $initwpm\n";

   $d->Contents('');
   $d->focus;
 
   $mdlg->startusertextinput();
}

sub abortAuto {
   my $wpm = 1200 / ($reftotal / $pulsecnt);
   print "\nActual wpm = $wpm\n";
   $initwpm = int($wpm + 0.5);

   $mdlg->stopusertextinput(); 
}


