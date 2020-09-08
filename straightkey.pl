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
my $inputover;
my $playeropen;

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
      processWord(substr($inputword, 0, -1)); # remove trailing blank before processing
      # response could be audible as well as visual
      $d->markSet('insert', 'end');
      $d->see('end');
      $inputword = '';
   }
}

sub startAuto {
   $elementDetector = DetectElements->init($argwpm);
   $elementsequence = '';
   $inputword = '';
   $inputover = '';

   my $wpm = $elementDetector->wpm();
   print "\nInitial wpm = $wpm\n";

   $d->Contents('');
   $d->focus;
 
   $mdlg->startusertextinput();
}

sub abortAuto {
   playText(); # close player
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
            if ($elementsequence =~ /\.\.\.\.\.\.\./) {
               $char = '<'; # ignore previous word
            } else {
               $char =  '*' # dummy char to indicate unrecognised code
            }
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

   if ($inputover eq '') {
      $inputover = $word;
   } else {
      $inputover .= " $word";
   }

   # Attempt some logical formatting by detecting the end of a sentence or section. 
   if ($word eq 'k' or $word =~ /[\!\|\>\}]k?$/) {
      # A break prosign at the start of an over doesn't count as a terminator
      if ($inputover ne '!') {
         $d->insert('end', "\n");
         $inputover =~ s/([\!\+\=\?\|\>\<\}])/ $1 /g; # treat as separate words
         $inputover = " $inputover "; # ensure spaces before/after all words
         $inputover =~ s/ +/ /g; # remove any duplicate spaces
         $inputover =~ s/ [^ \<]+ \<//g; # remove any cancelled words
         my $response = respondToOver($inputover);
         playText($response);
         $inputover = '';
      }
   }
}

sub playText {
   my $ptext = shift;

   my $morseplayer = "./morseplayer2.pl";
   my $wpm = $elementDetector->wpm();

   if ($playeropen) {
      close(MP);
      $playeropen = undef;
   }

   if (defined $ptext) {
      open(MP, "|  perl $morseplayer " . join(' ', $wpm, $wpm, 600, 1, 3, 0, '-t')) or die;
      autoflush MP, 1;
      $playeropen = 1;
      print MP "   $ptext\n#\n";
   }

   # leave player pipe open after sending data, so UI is responsive
}

sub respondToOver {
   my $inputover = shift;
   my $response = '';
   print "\"$inputover\"\n"; ### diags

   $response = 'r r';

   return $response;
}
