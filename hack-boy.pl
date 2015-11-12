#!/usr/bin/env perl
#
# #######################################################################
# DESCRIPTION
=head1 NAME

hack-boy.pl - Interactive script to breack Fallout terminal passwords.

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

Interactive script to breack Fallout terminal passwords.

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
# CLI ARGS and IMPORTANT VARIABLES
#
our $DEBUG     = scalar( grep( /^d/, split( //, join( '', grep( /^[-]+d/i, @ARGV ) ) ) ) );
our $NO_COLOR  = grep( /^[-]+z/i, @ARGV );
# What character to use to create the "UI"
our $H_CHAR    = "#";
# How wide to make the "ui"
our $H_LEN     = $ENV{COLUMNS} || 100;
# much much padding to center?
our $H_PAD = " " x (($H_LEN - 80) / 2);

# Fallout 3/4: 2
# Fallout New Vegas: 3
our $PIP_COLOR = 2;
if ( !$NO_COLOR && grep( /^[-]+(nv|newvegas)/i, @ARGV ) ) { $PIP_COLOR = 3; };
### $PIP_COLOR
our( @words ) = ();

if ( $DEBUG ) {
  push( @words, qw(fargo loves sells hopes dazed hears sizes spent deeds crazy since tires surge parts ) );
}

#
# #############################################################################
#
# Sub-routines
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
# searchWords() - Given an entered word and number of matching chars: filter the list of words
#
sub searchWords(){
  my( $the_word, $num_right, @the_words ) = @_;
  my( @word_parts ) = split( //, $the_word );

  my( @possible );
  foreach my $w ( @the_words ) {
    # skip the word itself
    if ( "$the_word" eq "$w" ) {
      next;
    }
    my( $alike, $c ) = (0,0);
    my( @parts ) = split( //, $w );

    while( $c <= $#word_parts ) {
      ( $word_parts[$c] eq $parts[$c] ) && $alike++;
      $c++;
    }
    
    if ( $alike == $num_right ) {
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
# sub _printSep() - stupid little formatter to D.R.Y. the code
#
sub _printSep(;$){
  my( $print_lead ) = @_;
  $print_lead = $print_lead || 0;

  $print_lead && print <<EOF;
${H_CHAR}${H_PAD}                                                                              ${H_PAD}${H_CHAR}
EOF
  
  print "${H_CHAR}" x $H_LEN . "$/";
  
  if ( $print_lead > 1 ) { print <<EOF;
${H_CHAR}${H_PAD}                                                                              ${H_PAD}${H_CHAR}
EOF
  }
}
#
# #############################################################################
#
# Procedural work here
#
#figlet -k -c -f slant -w 80 'Hack-Boy' | sed -e 's/^ /\${H_CHAR}\${H_PAD}/' -e 's/\\/\\\\/g' -e 's/ $/\${H_PAD}\${H_CHAR}/'
system( "clear" );

# trap INT and reset terminal
$SIG{INT} = sub{ _termReset(); exit 0; };

_termColor( $PIP_COLOR );
_printSep();
print <<EOF;
${H_CHAR}${H_PAD}               __  __              __           ____                          ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}              / / / /____ _ _____ / /__        / __ ) ____   __  __           ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}             / /_/ // __ `// ___// //_/______ / __  |/ __ \\ / / / /           ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}            / __  // /_/ // /__ / ,<  /_____// /_/ // /_/ // /_/ /            ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}           /_/ /_/ \\__,_/ \\___//_/|_|       /_____/ \\____/ \\__, /             ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}                                                          /____/              ${H_PAD}${H_CHAR}
EOF
_printSep( 2 );
#
# #############################################################################
#
# read the words for processing
#
my( $word ) = "";
print "$/Enter terminal words (hit return to stop)$/";
while( 1 ) {
  $word = PromptString( "Word (" . (scalar( @words ) + 1) . ") :", "." );
  if ( $word ne "." ) {
    
    $word = lc( $word );
    if ( $word =~ /\W/ ) {
      print "*** That word has non-word charaters in it!$/";
      next;
    }
    elsif ( grep( /^${word}$/, @words ) ) {
      print "*** That word already exists in the list!$/";
      next;
    }
    elsif ( scalar( @words ) && ( length( "$word") != length( $words[0] ) ) ) {
      my( $len1, $len2 ) = ( length( "$word"), length( $words[0] ) );
      print "*** That word doesn't match the length of previous words ('$len1' != '$len2')!$/";
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
# #############################################################################
#
# Here's the guess and matching portion
#
while( scalar( @words ) > 1 ) {
  _printSep( 2 );
  print "$/Words remaining: " . scalar( @words ) . $/;
  print "  " . join( ' ', @words ) . "$/$/";
  
  my( $the_word ) = "";
  while ( !grep( /^${the_word}$/, @words ) ) {
    $the_word = PromptString( "Word:" );
  }
  my( $num_right ) = PromptString( "Chars:" );
  @words = searchWords( $the_word, $num_right, @words );
  #### @remaining_words
}
# #############################################################################
#
# We broke out of the loop, only two possibilities
#
#figlet -k -c -f slant -w 80 'Match Found!' | sed -e 's/^ /\${H_CHAR}\${H_PAD}/' -e 's/\\/\\\\/g' -e 's/$/\${H_PAD}\${H_CHAR}/'
if ( scalar( @words ) == 1 ) {
  my( $final_word ) = uc( $words[0] );
  _printSep(1);
  print <<EOF;
${H_CHAR}${H_PAD}     __  ___        __         __       ______                          __ __ ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}    /  |/  /____ _ / /_ _____ / /_     / ____/____   __  __ ____   ____/ // / ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}   / /|_/ // __ `// __// ___// __ \\   / /_   / __ \\ / / / // __ \\ / __  // /  ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}  / /  / // /_/ // /_ / /__ / / / /  / __/  / /_/ // /_/ // / / // /_/ //_/   ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD} /_/  /_/ \\__,_/ \\__/ \\___//_/ /_/  /_/     \\____/ \\__,_//_/ /_/ \\__,_/(_)    ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}                                                                              ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD} The matching word is: $final_word
EOF
_printSep(1);

}
else {
  # figlet -k -c -f slant -w 80 'Abort!' | sed -e 's/^ /\${H_CHAR}\${H_PAD}/' -e 's/\\/\\\\/g' -e 's/$/\${H_PAD}\${H_CHAR}/'
  _printSep(2);
  print <<EOF;
\a${H_CHAR}${H_PAD}                       ___     __                  __   __                    ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}                      /   |   / /_   ____   _____ / /_ / /                    ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}                     / /| |  / __ \\ / __ \\ / ___// __// /                     ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}                    / ___ | / /_/ // /_/ // /   / /_ /_/                      ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}                   /_/  |_|/_.___/ \\____//_/    \\__/(_)                       ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD}                                                                              ${H_PAD}${H_CHAR}
${H_CHAR}${H_PAD} Something went wrong! No words found!                                        ${H_PAD}${H_CHAR}
EOF
  _printSep(1);
}

_termReset();
