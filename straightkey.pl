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
my $inputword;

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

   my $inputchar = detectChar($element);
   $d->insert('end', $inputchar);

   $inputword .= $inputchar;

   if ($inputword =~ / $/) {
      my $response = processWord(substr($inputword, 0, -1)); # remove trailing blank before processing
      # response could be audible as well as visual
      $d->insert('end', $response);
      $d->see('end');
      $inputword = '';
   }
}

sub startAuto {
   $elementDetector = DetectElements->init($argwpm);
   $elementsequence = '';
   $inputword = '';

   my $wpm = $elementDetector->wpm();
   print "\nInitial wpm = $wpm\n";

   $d->Contents('');
   $d->focus;
 
   $mdlg->startusertextinput();
}

sub abortAuto {
   $mdlg->stopusertextinput(); 
   reportFist();
}

sub detectChar {
   my $element = shift;
   my $char = '';

   if ($element =~ /[.-]/) {
      $elementsequence .= $element;
   } else {
      if ($element ne '') {
         $char = codeIndex->{$elementsequence};

         if (not defined $char) {
            $char =  '*' # dummy char to indicate unrecognised code
         }

         if ($element eq "\n") {
            # end of word
            $char .= ' ';
         }

         $elementsequence = ''
      }
   }

   return $char;
}

sub reportFist {
   my $wpm = $elementDetector->wpm();
   print "\nFinal wpm = $wpm\n";

   my $elementpulses = $elementDetector->{elementpulses};

   if ($elementpulses->grandcount() > 0) {
      my $elementaverages = $elementpulses->averages();
      my $avgditpulses = ($elementaverages->{'.'} or 1);
      my $avgdahpulses = ($elementaverages->{'-'} or 1);
      my $avgelementgappulses = ($elementaverages->{''} or 1);
      my $avgchargappulses = ($elementaverages->{' '} or 1);

      printf("Dit length factor:    %5.1f\n",  $avgditpulses);
      printf("Dah length factor:    %5.1f\n",  $avgdahpulses);
      printf("Element gap factor:   %5.1f\n",  $avgelementgappulses);
      printf("Character gap factor: %5.1f\n",  $avgchargappulses);
   }
}

sub processWord {
   my $word = shift;
   my $response = '';

   # attempt some logical formatting by detecting the end of a sentence or section
   if ($word eq 'k' or $word =~ /[\]=\?]$/ or $word =~ /]k$/) {
      $response = "\n";
   }

   # perform any other response to user's entry

   return $response;
}

