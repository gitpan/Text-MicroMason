package Text::MicroMason::Base;

use strict;
require Carp;

######################################################################

use vars qw( %Defaults );

# Debugging flag activates warns throughout the code
$Defaults{ debug } = 0;

sub defaults {
  return %Defaults
}

######################################################################

# $mason = $class->new( %options );
# $clone = $object->new( %options );
sub new {
  my $referent = shift;
  if ( ! ref $referent ) {
    bless { $referent->defaults(), @_ }, $referent;
  } else {
    bless { $referent->defaults(), %$referent, @_ }, ref $referent;
  }
}

######################################################################

# @token_pairs = $mason->lex( $template );
sub lex {
  my $self = shift;
  local $_ = "$_[0]";
  my @tokens;
  my $lexer = $self->can('lex_token') 
	or $self->croak_msg('No lex_token method');
  # warn "Lexing: " . pos($_) . " of " . length($_) . "\n";
  until ( /\G\z/gc ) {
    my @parsed = &$lexer( $self ) or      
	/\G ( .{0,20} ) /gcxs 
	  && die "Couldn't find applicable parsing rule at '$1'\n";
    push @tokens, @parsed;
  }
  $self->debug_msg( "Source:", length($_), $_ ); 
  $self->debug_msg( "Tokens:", @tokens ); 
  return @tokens;
}

# ( $type, $value ) = $mason->lex_token();
sub lex_token {
  die "The lex_token() method is abstract and must be provided by a subclass";
}

######################################################################

# Text elements used for subroutine assembly
use vars qw( %Assembler );

sub assembler_rules {
  my $self = shift;
  return %Assembler,
}

%Assembler = (
  template => [ qw( $sub_start $init_errs $init_output
		    $init_args @perl $return_output $sub_end ) ],

  sub_start  => 'sub { ',
  sub_end  => '}',

  init_errs => 
    'local $SIG{__DIE__} = sub { die "MicroMason execution failed: ", @_ };',

  # Argument processing elements
  init_args => 'my %ARGS = @_ if ($#_ % 2);',

  # Output generation
  init_output => 'my @OUT; my $_out = sub { push @OUT, @_ };',
  add_output => '  push @OUT, ',
  return_output => 'join("", @OUT)',

  # Mapping between token types
  text_token => 'perl OUT( QUOTED );',
  expr_token => 'perl OUT( do{ TOKEN } );',
  file_token => 'perl OUT( $m->execute( file => do { TOKEN } ) );',
);

# $perl_code = $mason->assemble( @tokens );
sub assemble {
  my $self = shift;
  my @tokens = @_;
  
  my %assembler = $self->assembler_rules();
  my @assembly = @{ $assembler{ template } };
  
  my %token_streams = map { $_ => [] } map { ( /^\W?\@(\w+)$/ ) } @assembly;
  my %token_map = map { ( /^(.*?)_token$/ )[0] => $assembler{$_} } 
					    grep { /_token$/ } keys %assembler;
  
  while ( scalar @tokens ) {
    my $type = shift @tokens;
    my $token = shift @tokens;
    my @functions;
    
    unless ( $token_streams{$type} or $token_map{$type} ) {
      my $method = "assemble_$type";
      my $sub = $self->can( $method ) 
	or $self->croak_msg( "Unexpected token type '$type': '$token'" );
      ($type, $token) = &$sub( $self, $token );
    }

    if ( my $typedef = $token_map{ $type } ) {
      $typedef =~ s{\bTOKEN\b}{$token}g;
      $typedef =~ s{\bQUOTED\b}{qq(\Q$token\E)}g;
      $typedef =~ s{\bOUT\b}{$assembler{add_output}}g;
      ( $type, $token ) = split ' ', $typedef, 2;
    }
    
    my $ary = $token_streams{$type}
	or $self->croak_msg( "Unexpected token type '$type': '$token'" );
    
    push @$ary, $token
  }
    
  join(' ', '#', 'line', 1, '"' . ( ( caller(2) )[1] || 'unknown' ) . ' template near"' . "\n" ) .
  join( "\n",  map { 
    /^(\W+)(\w+)$/ or $self->croak_msg("Can't assemble $_");
    if ( $1 eq '$' ) {
      $assembler{ $2 }
    } elsif ( $1 eq '@' ) {
      @{ $token_streams{ $2 } }
    } elsif ( $1 eq '!@' ) {
      reverse @{ $token_streams{ $2 } }
    } elsif ( $1 eq '-@' ) {
      ()
    } else {
      $self->croak_msg("Can't assemble $_");
    }
  } @assembly );
}

######################################################################

# $code_ref = $mason->eval_sub( $perl_code );
sub eval_sub {
  my ( $m, $code ) = @_;
  package Text::MicroMason::Commands; 
  eval( $code )
}

######################################################################

# ( $type, $data ) = $mason->resolve( $type, $data );
sub resolve {
  my ( $self, $src_type, $src_data ) = @_;
  if ( $src_type eq 'lines' ) {
    'text' => join "\n", @$src_data
  } else {
    $src_type, $src_data 
  }
}

# $template = $mason->read_text( $template );
sub read_text {
  ref($_[1]) ? $$_[1] : $_[1];
}

# ( $contents, %path_info ) = $mason->read_file( $filename );
sub read_file {
  my ( $self, $file ) = @_;
  $self->{debug} and $self->debug_msg( "MicroMason reading file:", $file );
  
  local *FILE;
  open FILE, "$file" or $self->croak_msg("MicroMason can't open $file: $!");
  local $/ = undef;
  $self->debug_msg("MicroMason reading from '$file'");
  local $_ = <FILE>;
  close FILE or $self->croak_msg("MicroMason can't close $file: $!");;
  return ( $_, source_file => $file );
}

######################################################################

# $code_ref = $mason->compile( text => $template, %options );
# $code_ref = $mason->compile( file => $filename, %options );
sub compile {
  my ( $self, $src_type, $src_data, %options ) = @_;
  $self = $self->new( %options ) if ( scalar keys %options );
  
  ( $src_type, $src_data, %options ) = $self->resolve( $src_type, $src_data );
  $self->{debug} and $self->debug_msg("MicroMason read:", $src_type, $src_data); 
  $self = $self->new( %options ) if ( scalar keys %options );
  
  my $src_method = "read_$src_type";
  ( my $template, %options ) = $self->$src_method( $src_data );
  $self->{debug} and $self->debug_msg( "MicroMason source:", $template ); 
  $self = $self->new( %options ) if ( scalar keys %options );

  my @tokens = $self->lex( $template, $options{source_file} );
  $self->{debug} and $self->debug_msg( "MicroMason tokens:", @tokens ); 

  my $code = $self->assemble( @tokens );
  $self->{debug} and $self->debug_msg( "MicroMason subdef: $code" );
  
  $self->eval_sub( $code ) 
    or $self->croak_msg( "MicroMason compilation failed:\n$code\n$@\n" )
}

######################################################################

# $result = $mason->execute( text => $template, @arguments );
# $result = $mason->execute( file => $filename, @arguments );
# $result = $mason->execute( text => $template, \%options, @arguments );
# $result = $mason->execute( file => $filename, \%options, @arguments );
sub execute {
  my $self = shift;
  my $sub = ( $_[0] eq 'code' ) ? do { shift; shift } : 
	$self->compile( shift, shift, ref($_[0]) ? %{ shift() } : () )
    or $self->croak_msg("Couldn't compile: $@");
  &$sub( @_ );
}

######################################################################

sub debug_msg {
  (shift)->{debug} and warn( ( ( @_ == 1 ) ? $_[0] : join( ' ', map _printable(), @_ ) ) . "\n")
}

sub croak_msg {
  local $Carp::CarpLevel = 2;
  shift and Carp::croak( ( @_ == 1 ) ? $_[0] : join(' ', map _printable(), @_) )
}

my %Escape = ( 
  ( map { chr($_), unpack('H2', chr($_)) } (0..255) ),
  "\\"=>'\\', "\r"=>'r', "\n"=>'n', "\t"=>'t', "\""=>'"' 
);

# $special_characters_escaped = _printable( $source_string );
sub _printable {
  local $_ = scalar(@_) ? (shift) : $_;
  return "(undef)" unless defined;
  s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$Escape{$1}/sgo;
  /[^\w\d\-\:\.\'\ ]/ ? "q($_)" : $_;
}

######################################################################

sub class {
  my ( $baseclass, @mixins ) = @_;
  return $baseclass if ( ! @mixins );
  my $basespace = ( $baseclass =~ m/^(.*\:\:)[^\:]+$/ )[0];
    
  my (@names, @packages);
  foreach my $mixin ( @mixins ) {
    push @packages, ( $mixin =~ /::/ ) ? $mixin : "$basespace$mixin";
    
    my $t_name = $mixin;
    $t_name =~ s/^$basespace//;
    $t_name =~ s/\:/_/g;
    push @names, $t_name;
  }

  my $name = join('_', @names);
  
  my $new_class = $baseclass . "::" . $name;
  
  no strict;
  if ( ! @{ $new_class . "::ISA" } ) {
    foreach my $mixin ( @packages ) {
      my $t_file = "$mixin.pm";
      $t_file =~ s{::}{/}g;
      unless ( $INC{ $t_file } ) {
	# warn "require $t_file";
	require $t_file
      }
    }
    @{ $new_class . "::ISA" } = ( reverse(@packages), $baseclass );
    # warn "-> $new_class ISA ". join(' ', @{ $new_class . "::ISA" }) ."\n";
  }
  
  return $new_class;
}

######################################################################

sub NEXT {
  my ( $self, $method, @args ) = @_;
  
  my ( $filename, $subname );
  my $depth = 1;
  do { ( $filename, $subname ) = ( caller( $depth ++ ) )[1,3] }
    while ($filename eq '(eval)' || $subname eq '(eval)');
  $subname =~ s/.*\:\://;
  my $package = ( caller($depth - 2) )[0];
  warn "-> $method - $depth - $subname $package\n" if ( $method ne $subname );
  
  my @classes = ref($self) || $self;
  my @isa;
  while ( my $class = shift @classes ) {
    push @isa, $class;
    no strict;
    unshift @classes, @{ $class . "::ISA" };
  }
  while ( my $class = shift @isa ) {
    last if ( $class eq $package )
  }
  while ( my $class = shift @isa ) {
    next unless my $sub = $class->can( $method );
    return &$sub( $self, @args );
  }
  $self->croak_msg( "Can't find NEXT method" );
}

######################################################################

1;

__END__

######################################################################

=head1 NAME

Text::MicroMason::Base - Abstract Compiler for Simple Templating 


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

The Text::MicroMason::Base class provides a parser and execution environment for a simple templating system based on HTML::Mason.


=head2 Public Methods

=over 4

=item class()

  $class = Text::MicroMason::Base->class( @Mixins );

Creates a subclass of this package that also inherits from the other classes named.

=item new()

  $mason = $class->new( %options );
  $clone = $mason->new( %options );

Creates a new instance with the provided key value pairs.

=item compile()

  $code_ref = $mason->compile( text => $template, %options );
  $code_ref = $mason->compile( file => $filename, %options );

Parses the provided template and converts it into a new Perl subroutine.

=item execute()

  $result = $mason->execute( text => $template, @arguments );
  $result = $mason->execute( file => $filename, @arguments );
  $result = $mason->execute( code => $code_ref, @arguments );

  $result = $mason->execute( $type => $source, \%options, @arguments );

Returns the results produced by the template, given the provided arguments.

=back

=head2 Private Methods

The following internal methods are used to implement the public interface described above, and may be overridden by subclasses and mixins.

=over 4

=item defaults

This class method is called by new() to provide key-value pairs to be included in the new instance.

=item lex

  @token_pairs = $mason->lex( $template );

Parses the source text and returns a list of pairs of token types and values. Loops through repeated calls to lex_token().

=item lex_token

  ( $type, $value ) = $mason->lex_token();

Attempts to parse a token from the template text stored in the global $_ and returns a token type and value. Returns an empty list if unable to parse further due to an error.

Abstract method; must be implemented by subclasses. 

=item assemble

  $perl_code = $mason->assemble( @tokens );

Assembles the parsed token series into the source code for the equivalent Perl subroutine.

=item assembler_rules()

Returns a hash of text elements used for Perl subroutine assembly. Used by assemble(). 

The assembly template defines the types of blocks supported and the order they appear in, as well as where other standard elements should go. Those other elements also appear in the assembler hash.

=item eval_sub

  $code_ref = $mason->eval_sub( $perl_code );

Compiles the Perl source code for a template using eval(), and returns a code reference. 

=item resolve

  ( $type, $data ) = $mason->resolve( $type, $data );

Called by compile(), the resolve method allows the template source type and value arguments to be normalized or resolved in various ways before the template is read using one of the read_type() methods. 

=item read_text

  $template = $mason->read_text( $template );

Called by compile() when the template source type is "text", this method simply returns the value of the text string passed to it. 

=item read_file

  ( $contents, %path_info ) = $mason->read_file( $filename );

Called by compile() when the template source type is "file", this method reads and returns the contents of the named file.

=item debug_msg

Called to provide a debugging message for developer reference. No output is produced unless the object's 'debug' flag is true.

=item croak_msg 

Called when a fatal exception has occured.

=item NEXT

Enhanced superclass method dispatch for use inside mixin class methods. Allows mixin classes to redispatch to other classes in the inheritance tree without themselves inheriting from anything. 

(This is similar to the functionality provided by NEXT::ACTUAL, but without using AUTOLOAD; for a more generalized approach to this issue see L<NEXT>.)

=back

=head2 Private Functions

=over 4

=item _printable

  $special_characters_escaped = _printable( $source_string );

Converts non-printable characters to readable form using the standard backslash notation, such as "\n" for newline.

=back

=head2 Supported Attributes

=over 4

=item debug

Boolean value. Debugging flag activates warns throughout the code. Used by debug_msg(). Defaults to 0.

=back

=head1 EXTENDING

You can add functionality to this module by creating subclasses or mixin classes. 

To create a subclass, just inherit from the base class or some dynamically-assembled class. To create your own mixin classes which can be combined with other mixin features, examine the operation of the class() and NEXT() methods.

Key areas for subclass writers are:

=over 4

=item resolve

You can intercept and re-write template source arguments by implementing this method.

=item read_*

You can support a new template source type by creating a method with a corresponding name prefixed by "read_". It is passed the template source value and should return the raw text to be lexed.

For example, if a subclass defined a method named read_from_db, callers could compile templates by calling C<-E<gt>compile( from_db =E<gt> 'welcome-page' )>.

=item lex_token

Replace this to parse a new template syntax. Is receives the text to be parsed in $_ and should match from the current position to return the next token type and its contents.

=item assembler_rules

The assembler data structure is used to construct the Perl subroutine for a parsed template.

=item assemble_*

You can support a new token type be creating a method with a corresponding name prefixed by "assemble_". It is passed the token value or contents, and should return a new token pair that is supported by the assembler template.

For example, if a subclass defined a method named assemble_sqlquery, callers could compile templates that contained a C<E<lt>%sqlqueryE<gt> ... E<lt>/%sqlqueryE<gt>> block. The assemble_sqlquery method could return a C<perl => $statements> pair with Perl code that performed some appropriate action.

=item compile

You can wrap or cache the results of this method, which is the primary public interface. 

=item execute

You typically should not depend on overriding this method because callers can invoke the compiled subroutines directly without calling execute.

=back

=head1 SEE ALSO

For an overview of this templating framework, see L<Text::MicroMason>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::Docs::ReadMe>.

=cut
