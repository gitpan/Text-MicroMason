package Text::MicroMason::ServerPages;

use strict;
use Carp;

use Safe;

use vars qw( @MIXIN );

######################################################################

my %block_types = ( 
  ''   => 'perl',	# <% perl statements %>
  '='  => 'output',	# <%= perl expression %>
  '--' => 'doc',	# <%-- this text will not appear in the output --%>
  '&'  => 'include',	# <%& filename argument %>
);

my $re_eol = "(?:\\r\\n|\\r|\\n|\\z)";

sub lex {
  my $self = shift;
  local $_ = "$_[0]";
  my @tokens;
  until ( /\G\z/gc ) {
    push ( @tokens, 
      
      # Blocks in <%word> ... <%word> tags.
      /\G \<\%(perl|args|once|init|cleanup|doc)\> (.*?) \<\/\%\1\> $re_eol? 
	/gcxs ? ( $1 => $2 ) :
      
      # Blocks in <%-- ... --%> tags.
      /\G \<\% \-\- ( .*? ) \-\- \%\> /gcxs ? ( 'doc' => $1 ) :
      
      # Blocks in <% ... %> tags.
      /\G \<\% (\=|\&)? ( .*? ) \%\> /gcxs ? ( $block_types{$1 || ''} => $2 ) :
      
      # Things that don't match the above -- XXX below regex should be simpler!
      /\G ( (?: [^\<\r\n%]+ | \<(?!\%) | (?<=[^\r\n\<])% |
	    $re_eol (?:\z|[^\r\n\%\<]|(?=\r\n|\r|\n|\%)|\<[^\%]|(?=\<[\%])) 
	    )+ (?: $re_eol +(?:\z|(?=\%|\<\[\%])) )?
      ) /gcxs ? ( 'text' => $1 ) :
      
      /\G ( .{0,20} ) /gcxs 
	&& die "Couldn't find applicable parsing rule at '$1'\n"
    );
  }
  $self->debug_msg( "Source:", length($_), $_ ); 
  $self->debug_msg( "Tokens:", @tokens ); 
  return @tokens;
}

######################################################################

1;

__END__

######################################################################

=head1 NAME

Text::MicroMason::ServerPages - Support syntax similar to ASP/JSP


=head1 SYNOPSIS

Server Pages syntax provides a way to mix Perl into a text template:

    <% my $name = $ARGS{name};
      if ( $name eq 'Dave' ) {  %>
      I'm sorry <% $name %>, I'm afraid I can't do that right now.
    <% } else { 
	my $hour = (localtime)[2];
	my $daypart = ( $hour > 11 ) ? 'afternoon' : 'morning'; 
      %>
      Good <%= $daypart %>, <%= $name %>!
    % } %>

Instead of using this class directly, pass its name to be mixed in:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new( -ServerPages );

Use the execute method to parse and evalute a template:

    print $mason->execute( text=>$template, 'name'=>'Dave' );

Or compile it into a subroutine, and evaluate repeatedly:

    $coderef = $mason->compile( text=>$template );
    print $coderef->('name'=>'Dave');


=head1 DESCRIPTION

This subclass replaces MicroMason's normal lexer with one that supports a syntax similar to Active Server Pages and Java Server Pages.

=head2 Template Syntax

The following elements are recognized by the ServerPages lexer:

=over 4

=item <% perl statements %>

Arbitrary Perl code to be executed at this point in the template.

=item <%= perl expression %>

A Perl expression to be evaluated and included in the output.

=item <%-- comment --%>

Documentation or inactive code to be skipped over silently.

=item <%& file arguments %>

Includes an external template file.

=item <%name> ... <%/name>

Supported names are: 'perl', 'args', 'once', 'init', 'cleanup', and 'doc'.

=back

=head2 Private Methods

=over 4

=item lex

  @tokens = $mason->lex( $template );

Parses the provided template text and returns a list of token types and values.

=back

=cut


=head1 SEE ALSO

For the core functionality of this package see L<Text::MicroMason> and L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut
