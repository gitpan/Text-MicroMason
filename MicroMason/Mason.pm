package Text::MicroMason::Mason;

require Text::MicroMason::Base;
@ISA = 'Text::MicroMason::Base';

use strict;

######################################################################

my $re_eol = "(?:\\r\\n|\\r|\\n|\\z)";
my $re_sol = "(?:\\A|(?<=\\r|\\n) )";

# ( $type, $value ) = $mason->lex_token();
sub lex_token {
  # Blocks in <%word> ... <%word> tags.
  /\G \<\%(perl|args|once|init|cleanup|doc)\> (.*?) \<\/\%\1\> $re_eol? 
    /xcogs ? ( $1 => $2 ) :
  
  # Blocks in <% ... %> tags.
  /\G \<\% ( .*? ) \%\> /xcogs ? ( 'output' => $1 ) :
  
  # Blocks in <& ... &> tags.
  /\G \<\& ( .*? ) \&\> /xcogs ? ( 'include' => $1 ) :
  
  # Lines begining with %
  /\G $re_sol \% ( [^\n\r]* ) $re_eol /xcogs ? ( 'perl' => $1 ) :
  
  # Things that don't match the above
  /\G ( (?: [^\<\r\n%]+ | \<(?!\%|\&) | (?<=[^\r\n\<])% |
	$re_eol (?:\z|[^\r\n\%\<]|(?=\r\n|\r|\n|\%)|\<[^\%\&]|(?=\<[\%\&])) 
	)+ (?: $re_eol +(?:\z|(?=\%|\<\[\%\&])) )?
  ) /xcogs ? ( 'text' => $1 ) : 

  # Lexer error
  ()
}

######################################################################

# Text elements used for subroutine assembly
use vars qw( %Assembler );

sub assembler_rules {
  my $self = shift;
  $self->NEXT('assembler_rules', @_), %Assembler
}

$Assembler{template} = [ qw( @once $sub_start $err_hdlr $out_start $args_start
			      @init @perl !@cleanup $out_end $sub_end -@doc ) ];

######################################################################

sub assemble_args {
  my ( $self, $token ) = @_;
    $token =~ s/^\s*([\$\@\%])(\w+) (?:\s* => \s* ([^\r\n]+))?/
      "my $1$2 = exists \$ARGS{$2} ? " . 
	      ( ($1 eq '$') ? "\$ARGS{$2}" : "$1\{ \$ARGS{$2} }" ) . 
      " : " . ( defined($3) ? "(\$ARGS{$2} = $3)" : 
	      qq{Carp::croak("no value sent for required parameter '$2'")} ) .
      ";"/gexm;
  return ( 'init' => '($#_ % 2) or Carp::croak("Odd number of parameters passed to sub expecting name/value pairs"); ' . $token );
}

######################################################################

1;

__END__

######################################################################

=head1 NAME

Text::MicroMason::Mason - Simple Compiler for Mason-style Templating 


=head1 SYNOPSIS

Create a Mason object to interpret the templates:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new();

Use the execute method to parse and evalute a template:

    print $mason->execute( text=>$template, 'name'=>'Dave' );

Or compile it into a subroutine, and evaluate repeatedly:

    $coderef = $mason->compile( text=>$template );
    print $coderef->('name'=>'Dave');
    print $coderef->('name'=>'Bob');

Templates stored in files can be run directly or included in others:

    print $mason->execute( file=>"./greeting.msn", 'name'=>'Charles');


=head1 DESCRIPTION

The Text::MicroMason::Mason class provides lexer and assembler methods that allow Text::MicroMason to handle most elements of HTML::Mason's template syntax.


=head2 Template Syntax

The template syntax supported by Text::MicroMason and some useful template developer techniques are described in L<Text::MicroMason::Devel>.


=head2 Compatibility with HTML::Mason

HTML::Mason is a full-featured application server toolkit with many fatures, of which only the templating functionality is emulated.

The following sets of HTML::Mason features B<are> supported by Text::MicroMason:

=over 4

=item *

Template interpolation with <% expr %> 

=item *

Literal Perl lines with leading % 

=item *

Named %args, %perl, %once, %init, %cleanup, and %doc blocks

=item *

The $m mason object, although with many fewer methods

=item *

Expression filtering with |h and |u (via -Filter mixin)

=back

The following sets of HTML::Mason features are B<not> supported by Text::MicroMason:

=over 4

=item *

No %attr, %shared, %method, or %def blocks.

=item *

No $r request object.

=item *

No shared files like autohandler and dhandler.

=item *

No mod_perl integration or configuration capability.

=back

Contributed patches to add these features of HTML::Mason 
would be welcomed by the author.


=head2 Private Methods

The following internal methods are used to implement the public interface described above, and may be overridden by subclasses and mixins.

=over 4

=item lex_token

  ( $type, $value ) = $mason->lex_token();

Supports HTML::Mason's markup syntax.

Attempts to parse a token from the template text stored in the global $_ and returns a token type and value. Returns an empty list if unable to parse further due to an error.

=item assembler_rules()

Returns a hash of text elements used for Perl subroutine assembly. Used by assemble(). 

Supports HTML::Mason's named blocks of Perl code and documentation: %once, %init, %cleanup, and %doc.

=item assemble_args

Called by assemble(), this method provides support for Mason's <%args> blocks.

=back

=head1 SEE ALSO

For a full-featured web application system using this template syntax, see L<HTML::Mason>.

For an overview of this distribution, see L<Text::MicroMason>.

This is a subclass intended for use with L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut

