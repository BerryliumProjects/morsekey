# includes proxy characters for prosigns
our %charcodes = (
   
   a=>'.- ',
   b=>'-... ',
   c=>'-.-. ',
   d=>'-.. ',
   e=>'. ',
   f=>'..-. ',
   g=>'--. ',
   h=>'.... ',
   i=>'.. ',
   j=>'.--- ',
   k=>'-.- ',
   l=>'.-.. ',
   m=>'-- ',
   n=>'-. ',
   o=>'--- ',
   p=>'.--. ',
   q=>'--.- ',
   r=>'.-. ',
   s=>'... ',
   t=>'- ',
   u=>'..- ',	
   v=>'...- ',
   w=>'.-- ',
   x=>'-..- ',
   y=>'-.-- ',
   z=>'--.. ',
   0=>'----- ',
   1=>'.---- ',
   2=>'..--- ',
   3=>'...-- ',
   4=>'....- ',
   5=>'..... ',
   6=>'-.... ',
   7=>'--... ',
   8=>'---.. ',
   9=>'----. ',
   '.'=>'.-.-.- ',
   ','=>'--..-- ',
   '?'=>'..--.. ',
   '/'=>'-..-. ',
   '='=>'-...- ',
   ':'=>'---... ',
   '+'=>'.-.-.',
   '!'=>'-...-.-',
   '|'=>'-.-..-..',
   '>'=>'-.--.',
   '}'=>'...-.-',
   ' '=>'  '
);


sub codeIndex {
   # create secondary index on codes (excluding the separator)
   my %codeIndex;

   foreach my $char (keys(%charcodes)) {
      my $code = $charcodes{$char};
      $code =~ s/ //g;
      if ($code ne '') {
         $codeIndex{$code} = $char;
      }
   }

   return \%codeIndex;
}



1;
