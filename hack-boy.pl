#!/usr/bin/env perl
#
# #######################################################################
# DESCRIPTION
=head1 NAME

hack-boy.pl - Interactive script to guess Fallout terminal passwords.

=head1 AUTHOR

Matthew Cox <mcox@cpan.org>

=head1 SYNOPSIS

B<hack-boy.pl> [B<--help>] [B<-d>] [B<-nv>] [B<-z>]

=head2 -h, --help

This output

=head2 -d, --debug

5 levels of debug are supported.

   -d -d -d -d -d or -d 5

=head2 -nv, --newvegas

Set the terminal color to that of New Vegas

=head2 -z, --zerocolor

The -zerocolor option disables ANSI color output on message strings

=head1 REQUIRES

Perl5.004, L<strict>, L<warnings>, L<Smart::Comments>

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

Interactive script to guess Fallout terminal passwords.

=cut

#
# #############################################################################

# #############################################################################
# BEGIN

# these need to be outside the BEGIN
use strict;
use warnings;

# see this page for an explanation regarding the levels of warnings:
# http://search.cpan.org/~nwclark/perl-5.8.9/pod/perllexwarn.pod
no warnings qw( redefine prototype );

BEGIN {
  # pre-check requested debug level and load Smart::Comments appropriately
  my( @d ) = grep( /^d/, split( //, join( '', grep( /^[-]+d/i, @ARGV ) ) ) );
  if ( scalar( @d ) >= 1 ) {
    my $c = 3;
    $ENV{Smart_Comments} = join( ':', map { '#' x $c++ } @d );
    require Smart::Comments; import Smart::Comments -ENV;
  };
} ## end BEGIN

# was help asked for?
grep( /^[-]+(h|help)/i, @ARGV ) && do{ exec "perldoc $0"; };

#
# #############################################################################

# #############################################################################
#
# CLI ARGS and IMPORTANT VARIABLES
#
our $DEBUG     = scalar( grep( /^d/, split( //, join( '', grep( /^[-]+d/i, @ARGV ) ) ) ) );
our $NO_COLOR  = grep( /^[-]+z/i, @ARGV );
# What character to use to create the "UI"
our $H_CHAR    = "#";
# How wide to make the "ui"
our $H_LEN     = $ENV{COLUMNS} || 100;
# Minimum width
our $H_MIN_WIDTH = 80;
# much much padding to center?
our $H_PAD = " " x (($H_LEN - $H_MIN_WIDTH) / 2);

# Fallout 3/4: 2
# Fallout New Vegas: 3
our $PIP_COLOR = 2;
if ( !$NO_COLOR && grep( /^[-]+(nv|newvegas)/i, @ARGV ) ) { $PIP_COLOR = 3; };
### $PIP_COLOR
#
# this is global *only* for debug mode
#
our( @words ) = ();
#
# #############################################################################
#
# ACSII Art Messages
#
# figlet -k -c -f slant -w 80 'Hack-Boy' | sed -e 's/\\/\\\\/g'
our $HACK_BOY = <<EOF;
               __  __              __           ____                          
              / / / /____ _ _____ / /__        / __ ) ____   __  __           
             / /_/ // __ `// ___// //_/______ / __  |/ __ \\ / / / /           
            / __  // /_/ // /__ / ,<  /_____// /_/ // /_/ // /_/ /            
           /_/ /_/ \\__,_/ \\___//_/|_|       /_____/ \\____/ \\__, /             
                                                          /____/              
EOF

$HACK_BOY =~ s|^|${H_CHAR}${H_PAD}|mg;
$HACK_BOY =~ s|$/|${H_PAD}${H_CHAR}$/|mg;

# figlet -k -c -f slant -w 80 'Match Found!' | sed -e 's/\\/\\\\/g' -e 's/^/ /g'
our $MATCH_FOUND = <<EOF;
     __  ___        __         __       ______                          __ __ 
    /  |/  /____ _ / /_ _____ / /_     / ____/____   __  __ ____   ____/ // / 
   / /|_/ // __ `// __// ___// __ \\   / /_   / __ \\ / / / // __ \\ / __  // /  
  / /  / // /_/ // /_ / /__ / / / /  / __/  / /_/ // /_/ // / / // /_/ //_/   
 /_/  /_/ \\__,_/ \\__/ \\___//_/ /_/  /_/     \\____/ \\__,_//_/ /_/ \\__,_/(_)    
                                                                              
EOF

$MATCH_FOUND =~ s|^|${H_CHAR}${H_PAD}|mg;
$MATCH_FOUND =~ s|$/|${H_PAD}${H_CHAR}$/|mg;

# figlet -k -c -f slant -w 80 'Abort!' | sed -e 's/\\/\\\\/g'
our $ABORT = <<EOF;
                       ___     __                  __   __                    
                      /   |   / /_   ____   _____ / /_ / /                    
                     / /| |  / __ \\ / __ \\ / ___// __// /                     
                    / ___ | / /_/ // /_/ // /   / /_ /_/                      
                   /_/  |_|/_.___/ \\____//_/    \\__/(_)                       
                                                                              
EOF

$ABORT =~ s|^|${H_CHAR}${H_PAD}|mg;
$ABORT =~ s|$/|${H_PAD}${H_CHAR}$/|mg;
#
# #############################################################################
#
# Debug mode
#
if ( $DEBUG == 1 ) {
  push( @words, qw(fargo loves sells hopes dazed hears sizes spent deeds crazy since tires surge parts ) );
}
elsif ( $DEBUG == 2 ) {
  # erik,1
  # trap,0
  # RAIN
  push( @words, qw(erik fork safe maul song loud last trap note shop rain this game road ) );
}
elsif ( $DEBUG >= 3 ) {
  push( @words, qw(hire warm want hard part tent hall fate wait each seem fast kept walk ) );
}

#
# #############################################################################
#
# Sub-routines
#
# #############################################################################
#
# sub _termReset() - restore default color
#
sub _termReset() {
  print "\e[0m";
  system( "tput setaf 9" );
}
#
# #############################################################################
#
# sub _termColor() - set the output color
#
sub _termColor($) {
  my( $color ) = @_;
  
  if ( !$NO_COLOR ) {
    print "\e[3${color}m";
    system( "tput setaf $color" );
  }
}
#
# #############################################################################
#
# _findWordSimilarity() - calculate the similairty of two words (chars in same position)
#
sub _findWordSimilarity($$){
  my( $w1, $w2 ) = @_;
  my( @w1 ) = split( //, $w1 );
  my( @w2 ) = split( //, $w2 );

  my( $alike, $c ) = (0,0);
  while( $c <= $#w1 ) {
    ( $w1[$c] eq $w2[$c] ) && $alike++;
    $c++;
  }
  return $alike;
}
#
# #############################################################################
#
# bestWordGuess() - given a list of words, suggest one that eliminates the most
#
sub findBestWorstGuess(@){
  my( @the_words ) = @_;
  my( %scores );
  my( $max, $min ) = (0,scalar(@the_words));
  foreach my $word ( @the_words ) {
    my( $totalAlike ) = 0;

    foreach my $w ( @the_words ) {
      # skip the word itself
      next unless ( "$word" ne "$w" );
      if ( _findWordSimilarity( $word, $w ) ) {
        $totalAlike++;
      }
    }

    if ( !exists($scores{$totalAlike} ) ) {
      $scores{$totalAlike} = [];
    }

    push( @{$scores{$totalAlike}}, $word );

    if ( $totalAlike > $max ) {
      $max = $totalAlike;
    }

    if ( $totalAlike < $min ) {
      $min = $totalAlike;
    }
  }
  ### %scores
  return ($scores{$max}[rand @{$scores{$max}}], $scores{$min}[rand @{$scores{$min}}]);
}
#
# #############################################################################
#
# searchWords() - Given an entered word and number of matching chars: filter the list of words
#
sub searchWords($$@){
  my( $the_word, $num_right, @the_words ) = @_;

  if ( length( $the_word ) == $num_right ) {
    return ( $the_word );
  }

  my( @possible );
  foreach my $w ( @the_words ) {
    # skip the word itself
    next unless ( "$the_word" ne "$w" );

    if ( _findWordSimilarity( $the_word, $w ) == $num_right ) {
      push( @possible, $w );
    }
  }
  ### @possible
  return ( @possible );
}
#
# #############################################################################
#
# sub _readLine() - handle input from STDIN
#
sub _readLine() {

  my( $read );

  if ( -t \*STDIN ) {
    no warnings qw(uninitialized);
    chomp( $read = <STDIN> );
    !defined( $read ) && die( "\a$/*** Can't read from STDIN!$/" );
  }
  else {
    # can't read == teh badness
    die( "Can't read from STDIN!$/" );
  }

  # handle when backspaces/deletes are passed in to us
  $read = _removeBackspaceFromSting( $read );

  return $read;
} ## end sub _readLine
#
# #############################################################################
#
# _removeBackspaceFromSting() - As the name says: do
#
sub _removeBackspaceFromSting( $ ) {
  my( $str ) = @_;
  $str =~ s/^[\cH\c?]+//;

  while ( $str =~ /[\cH\c?]/ ) {
    $str =~ s/[^\cH\c?][\cH\c?]//g;
  }
  return $str;
}
#
# #############################################################################
#
# sub PromptString() - hacked version of PromptString
#
sub PromptString( $;$ ) {
  my( $question, $default ) = @_;

  my $answer;
  print "$question ";

  $answer = _readLine();

  if ( $default && not( $answer ) ) {
    $answer = $default;
  }

  return $answer;
} ## end sub PromptString( $;$ )
#
# #############################################################################
#
# sub PromptWithChoices() - prompt for a var and provide a list of choices
#
sub PromptWithChoices( $@ ) {
  my( $prompt, @choices ) = @_;

  if ( !scalar( @choices ) || ( $#choices == 0 && $choices[0] eq "" ) ) {
    print STDERR "*** The are no choices. Exiting.$/";
    exit;
  }

  my( $read ) = "";
  while ( $read eq "" ) {

    print "$prompt$/";

    my( $i ) = 1;
    foreach my $t ( @choices ) {
      print sprintf( "%4d) %s$/", $i++, "$t" );
    }

    print "$/Choose (1-" . scalar(@choices) . "): ";
    $read = _readLine();

    if ( $read !~ /^\d+$/ || $read < 1 || $read > scalar(@choices) ) {
      print "\a$/*** That is not a valid choice.$/";
      $read = "";
    }
    else {
      return $choices[--$read];
    }
  } ## end while ( $read eq "" )
} ## end sub PromptWithChoices( $@ )
#
# #############################################################################
#
# sub _printSep() - stupid little formatter to D.R.Y. the code
#
sub _printSep(;$){
  my( $print_lead ) = @_;
  $print_lead = $print_lead || 0;

  $print_lead &&
    print "${H_CHAR}${H_PAD}" . " " x ($H_MIN_WIDTH-2) . "${H_PAD}${H_CHAR}$/";

  print "${H_CHAR}" x $H_LEN . "$/";
  
  ( $print_lead > 1 ) &&
    print "${H_CHAR}${H_PAD}" . " " x ($H_MIN_WIDTH-2) . "${H_PAD}${H_CHAR}$/";
}
#
# sub _printText() - stupid little formatter to D.R.Y. the code
#
sub _printText($){
  my( $mesg ) = @_;
  my $PAD = " " x (($H_LEN - length($mesg) - 2) / 2);
  # if the string is even length, all is well. odd: off by one
  if ( length($mesg) % 2 == 0 ) {
    print "${H_CHAR}${PAD}${mesg}${PAD}${H_CHAR}$/";
  }
  else {
    print "${H_CHAR}${PAD}${mesg} ${PAD}${H_CHAR}$/";
  }
}

#
# #############################################################################
#
# sub readWords() - Read words for guessing against
#
sub readWords(@) {
  my( @words ) = @_;

  my( $word ) = "";
  print "$/Enter terminal words (hit return to stop)$/";
  while( 1 ) {
    $word = PromptString( sprintf( "Word (%02d) :", (scalar(@words)+1) ), "." );
    if ( $word ne "." ) {
    
      $word = lc( $word );
      if ( $word =~ /\W/ ) {
        print "\a*** That word has non-word characters in it!$/";
        next;
      }
      elsif ( grep( /^${word}$/, @words ) ) {
        print "\a*** That word already exists in the list!$/";
        next;
      }
      elsif ( scalar( @words ) && ( length( "$word") != length( $words[0] ) ) ) {
        my( $len1, $len2 ) = ( length( "$word"), length( $words[0] ) );
        print "\a*** That word doesn't match the length of previous words ('$len1' != '$len2')!$/";
        next;
      }
      else {
        push( @words, $word)  
      }
    }
    else {
      last;
    }
  }
  ### @words
  return( @words );
}
#
# #############################################################################
#
# sub processGuesses() - Handle the guessing portion
#
sub processGuesses( @ ) {
  my( @words ) = @_;

  while( scalar( @words ) > 1 ) {
    my( $best, $worst ) = findBestWorstGuess( @words );
    #### $best
    #### $worst
    my( $bestIndex  ) = grep { $words[$_] eq $best } 0..$#words;
    my( $worstIndex ) = grep { $words[$_] eq $worst } 0..$#words;

    _printSep( 2 );
    print "$/";
    print sprintf("%20s: %s$/", "Words remaining", scalar( @words ) );
    print sprintf("%20s: '%s' (choice %2s)$/", "Most similar words", $best, ++$bestIndex );
    ( $best ne $worst ) &&
      print sprintf("%20s: '%s' (choice %2s)$/", "Least similar words", $worst, ++$worstIndex );
    print "$/";

    my( $the_word ) = "";
    while ( !grep( /^${the_word}$/, @words ) ) {
      $the_word = PromptWithChoices( "Available:", @words );
    }
    my( $num_right ) = PromptString( "$/ Selected Word : '$the_word'$/Correct Letters:" );
    @words = searchWords( $the_word, $num_right, @words );
    #### @words
  }
  return( @words );
}
#
# #############################################################################
#
# sub main() - Procedural work here
#
sub main() {
  system( "clear" );

  # trap INT and reset terminal
  $SIG{INT} = sub{ _termReset(); exit 0; };

  _termColor( $PIP_COLOR );
  _printSep();
  print $HACK_BOY;
  _printSep( 2 );

  # read the words in
  @words = readWords( @words );

  # handle the guessing
  @words = processGuesses( @words );

  #
  # We broke out of the loop, only two possibilities
  #
  if ( scalar( @words ) == 1 ) {
    my( $final_word ) = uc( $words[0] );
    _printSep(1);
    print $MATCH_FOUND;
    _printText( "The matching word is: $final_word" );
    _printSep(1);
  }
  else {
    _printSep(2);
    print "\a$ABORT";
    _printText( "Something went wrong! No words found!" );
    _printSep(1);
  }

  _termReset();
}
#
# #############################################################################
#
# Do the thing
#
main();
