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

use lib '.';
use dialogfields;
use maindialog;
use histogram;
use charcodes;
use detectelements;
use testwordgenerator;

my $argwpm = ($ARGV[0] or 20);
my $elementDetector;
my $timerid;
my $inputword;
my $inputover;
my $playeropen;
my $otherCallsign;
my $myCallsign = '';
my $otherName = 'Jim';
my $myName = '';
my $elementsequence;
my $dialogue = '';

my $w = TestWordGenerator->new(4,10);
$w->addCallsign(1, 0, 50); # euro-prefix simple callsigns

my $mdlg = MainDialog->init(\&mainwindowcallback);
my $e = $mdlg->{e};
my $d = $mdlg->{d};

$e->{initwpm} = $argwpm;

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
   } elsif ($id eq 'hearcq') {
      startAuto();
      playCQ();
   } elsif ($id eq 'callcq') {
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
   my $initwpm = ($e->{initwpm} or 20);
   $elementDetector = DetectElements->init($initwpm);
   $otherCallsign = $w->chooseWord;
   $otherName = 'Ben'; # stub
   $myCallsign = '';
   $myName = '';
   $elementsequence = '';
   $inputword = '';
   $inputover = '';
   $dialogue = '';

   $d->Contents('');
   $d->focus;
 
   $mdlg->startusertextinput();
   print "Other callsign: $otherCallsign\n"; #diags/cheat!
}

sub abortAuto {
   playText(); # close player
   $mdlg->stopusertextinput(); 
   print "\nDialogue:\n$dialogue\n";
   reportFist();
}

sub playCQ {
   my $cqcall = "cq cq cq de $otherCallsign $otherCallsign pse k";
   playText($cqcall);
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
   print "\nFinal wpm = $wpm based on average pulse length\n";

   my $elementpulses = $elementDetector->{elementpulses};

   if ($elementpulses->grandcount() > 0) {
      my $elementaverages = $elementpulses->averages();
      my $avgditpulses = ($elementaverages->{'.'} or 1);
      my $avgdahpulses = ($elementaverages->{'-'} or 1);
      my $avgelementgappulses = ($elementaverages->{''} or 1);
      my $avgchargappulses = ($elementaverages->{' '} or 1);
      my $effectivewpm = $wpm / (1 + 0.12 * ($avgchargappulses - 3)); # on Farnsworth basis

      printf("Dit length factor:    %5.1f (aim for 1.0)\n",  $avgditpulses);
      printf("Dah length factor:    %5.1f (aim for 3.0)\n",  $avgdahpulses);
      printf("Element gap factor:   %5.1f (aim for 1.0)\n",  $avgelementgappulses);
      printf("Character gap factor: %5.1f (aim for 3.0) - effective wpm %5.1f\n",  $avgchargappulses, $effectivewpm);
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
         $e->{initwpm} = $elementDetector->wpm();
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
      $dialogue .= "THEM: $ptext\n";
      # leave player pipe open after sending data, so UI is responsive
   }
}

sub respondToOver {
   my $inputover = shift;
   my $response = '';

   # name is the next word after the keyword which isn't 'hr' or 'is'
   if ($inputover =~ /( nam | name | op )(.+)/) {
      foreach (split(/ /, $2)) {
         next if /hr|is/;
         $myName = $_;
         last;
      }
   }

   if ($inputover =~ / cq de ([0-9a-z]+) /) {
      $myCallsign = $1;
      $myName = '';
      $response = "$myCallsign de $otherCallsign $otherCallsign >";
   } elsif ($inputover =~ / $otherCallsign de ([0-9a-z]+) /) {
      $myCallsign = $1;

      if ($inputover =~ / hw \? / or $myName eq '') {
         $response = "$myCallsign de $otherCallsign mni tnx fer call = ur rst 589 589 = name $otherName $otherName = hw? + $myCallsign de $otherCallsign >";
      } else {
         $response = "$myCallsign de $otherCallsign ge $myName es tnx fer nice qso = hpe cuagn sn es gud dx = 73 $myCallsign de $otherCallsign } tu ee";
      }
   } elsif ($inputover =~ / qrl \? /){
      $response = '';
   } else {
      $response = 'qrz?';
   }

   $dialogue .= "YOU :$inputover\n"; #inputover has blank prefixed

   return $response;
}
