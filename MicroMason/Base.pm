package Text::MicroMason::Base;

use strict;
require Carp;

######################################################################

use vars qw( %Defaults );

# Debugging flag activates warns throughout the code
$Defaults{ debug } = 0;

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

sub defaults {
  return %Defaults
}

######################################################################

my $re_eol = "(?:\\r\\n|\\r|\\n|\\z)";
my $re_sol = "(?:\\A|(?<=\\r|\\n) )";

# @tokens = $mason->lex( $template );
sub lex {
  my $self = shift;
  local $_ = "$_[0]";
  
  my @tokens;
  until ( /\G\z/gc ) {
    push ( @tokens, 
      
      # Blocks in <%word> ... <%word> tags.
      /\G \<\%(perl|args|once|init|cleanup|doc)\> (.*?) \<\/\%\1\> $re_eol? 
	/xcogs ? ( $1 => $2 ) :
      
      # Blocks in <% ... %> tags.
      /\G \<\% ( .*? ) \%\> /xcogs ? ( 'output' => $1 ) :
      
      # Blocks in <& ... &> tags.
      /\G \<\& ( .*? ) \&\> /xcogs ? ( 'include' => $1 ) :
      
      # Lines begining with %
      /\G $re_sol \% ( [^\n\r]* ) $re_eol /xcogs ? ( 'perl' => $1 ) :
      
      # Things that don't match the above.
      /\G ( (?: [^\<\r\n%]+ | \<(?!\%|\&) | (?<=[^\r\n\<])% |
	    $re_eol (?:\z|[^\r\n\%\<]|(?=\r\n|\r|\n|\%)|\<[^\%\&]|(?=\<[\%\&])) 
	    )+ (?: $re_eol +(?:\z|(?=\%|\<\[\%\&])) )?
      ) /xcogs ? ( 'text' => $1 ) :
      
      /\G ( .{0,40} ) /xcogs 
	&& $self->croak_msg("Couldn't find applicable parsing rule at '$1'")
    );
  }
  return @tokens;
}

######################################################################

# Text elements used for subroutine assembly
use vars qw( %Assembler );
$Defaults{ assembler } = \%Assembler;

$Assembler{ sub_start } = 'sub { 
  local $SIG{__DIE__} = sub { die "MicroMason execution failed: ", @_ }';
$Assembler{ sub_end } = '}';

# Argument processing elements
$Assembler{ args_start } = 'my %ARGS = @_ if ($#_ % 2)';
$Assembler{ args_required } = '($#_ % 2) or Carp::croak("Odd number of parameters passed to sub expecting name/value pairs")';

# Output generation
# $Assembler{out_start} = 'my $OUT = ""; my $_out = sub {$OUT .= join "", @_}';
# $Assembler{out_do} = '  &$_out';
# $Assembler{out_end} = 'return $OUT';

$Assembler{out_start} = 'my @OUT; my $_out = sub { push @OUT, @_ }';
$Assembler{out_do} = '  push @OUT, ';
$Assembler{out_end} = 'return join("", @OUT)';

$Assembler{template} = [ qw( @once $sub_start $args_start $out_start @init
				  @perl !@cleanup $out_end $sub_end -@doc )];

######################################################################

# $perl_code = $mason->assemble( @tokens );
sub assemble {
  my $self = shift;
  my @tokens = @_;
  
  my $assembler = $self->{ assembler }
	or $self->croak_msg("MicroMason: missing assembler information");
  my @assembly = @{ $self->{ assembler }{ template } };
  
  my %token_streams = ( map { $_ => [] } map { ( /^\W?\@(\w+)$/ ) } @assembly );
  
  while ( scalar @tokens ) {
    my $type = shift @tokens;
    my $token = shift @tokens;
    my @functions;
    
    if ( $type eq 'text' ) {
      ( $type, $token ) = ( perl => "$assembler->{out_do}( qq(\Q$token\E) )" )
    
    } elsif ( $type eq 'output' ) {
      ( $type, $token ) = ( perl => "$assembler->{out_do}( do { $token } )" )
    
    } elsif ( $type eq 'include' ) {
      ($type, $token) = ( perl => 
	    "$assembler->{out_do}( \$m->execute( file => do { $token } ) )" )
    }
    
    unless ( $token_streams{$type} ) {
      my $method = "assemble_$type";
      my $sub = $self->can( $method ) 
	or $self->croak_msg( "Unexpected token type '$type': '$token'" );
      ($type, $token) = &$sub( $self, $token );
    }
    
    my $ary = $token_streams{$type}
	or $self->croak_msg( "Unexpected token type '$type': '$token'" );
    
    push @$ary, $token
  }
    
  join(' ', '#', 'line', 1, '"' . ( ( caller(2) )[1] || 'unknown' ) . ' template near"' . "\n" ) .
  join( ";\n",  map { 
    /^(\W+)(\w+)$/ or $self->croak_msg("Can't assemble $_");
    if ( $1 eq '$' ) {
      $self->{ assembler }{ $2 }
    } elsif ( $1 eq '@' ) {
      @{ $token_streams{ $2 } }
    } elsif ( $1 eq '!@' ) {
      reverse @{ $token_streams{ $2 } }
    } elsif ( $1 eq '-@' ) {
      ()
    }
  } @assembly );
}

sub assemble_args {
  my ( $self, $token ) = @_;
    $token =~ s/^\s*([\$\@\%])(\w+) (?:\s* => \s* ([^\r\n]+))?/
      "my $1$2 = exists \$ARGS{$2} ? " . 
	      ( ($1 eq '$') ? "\$ARGS{$2}" : "$1\{ \$ARGS{$2} }" ) . 
      " : " . ( defined($3) ? "(\$ARGS{$2} = $3)" : 
	      qq{Carp::croak("no value sent for required parameter '$2'")} ) .
      ";"/gexm;
  return ( 'init' => "$self->{ assembler }{ args_required }; $token" );
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
  } elsif ( $src_type eq 'ref' ) {
    'text' => $$src_data
  } else {
    $src_type, $src_data 
  }
}

# $template = $mason->read_text( $template );
sub read_text {
  $_[1];
}

# ( $contents, %path_info ) = $mason->read_file( $filename );
sub read_file {
  my ( $self, $file ) = @_;
  $self->{debug} and $self->debug_msg( "MicroMason reading file:", $file );
  
  local *FILE;
  open FILE, "$file" or $self->croak_msg("MicroMason can't open $file: $!");
  local $/ = undef;
  local $_ = <FILE>;
  close FILE or $self->croak_msg("MicroMason can't close $file: $!");;
  return ( $_, source_file => $file );
}

######################################################################

# $code_ref = $mason->compile( text => $template, %options );
# $code_ref = $mason->compile( file => $filename, %options );

# TO DO -- possible options: 
#		safe_share => [ '&Text::MicroMason::execute_file' ],
#		compile_errors => 1, 
#		runtime_errors => 1, 
#		file_code_cache => 1, 
#		runtime_cache => 1

sub compile {
  my ( $self, $src_type, $src_data, %options ) = @_;
  $options{caller} ||= join(' line ', (caller)[1,2] );
  
  ( $src_type, $src_data ) = $self->resolve( $src_type, $src_data );
  $self->{debug} and $self->debug_msg("MicroMason read:", $src_type, $src_data); 
  
  my $src_method = "read_$src_type";
  my ( $template, %more_options ) = $self->$src_method( $src_data );
  $self->{debug} and $self->debug_msg( "MicroMason source:", $template ); 

  # local %$self = ( %$self, %options, %more_options ); 

  my @tokens = $self->lex( $template, $options{source_file} );
  $self->{debug} and $self->debug_msg( "MicroMason tokens:", @tokens ); 

  my $code = $self->assemble( @tokens );
  $self->{debug} and $self->debug_msg( "MicroMason subdef: $code" );
  
  $self->eval_sub( $code ) 
    or $self->croak_msg( "MicroMason compilation failed: $@\n" . 
			 "Error at $options{caller}: $code" )
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
    or $self->croak_msg("Couldn't compile");
  &$sub( @_ );
}

######################################################################

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

sub debug_msg {
  (shift)->{debug} and warn join( ' ', map _printable(), @_ ) . "\n"
}

sub croak_msg {
  shift and Carp::croak( ( @_ == 1 ) ? $_[0] : join(' ', map _printable(), @_) )
}

######################################################################

1;

######################################################################

=head1 NAME

Text::MicroMason::Base - Core Class for Simple Mason Templating 


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

  @tokens = $mason->lex( $template );

Parses the provided template text and returns a list of token types and values.

=item assemble

  $perl_code = $mason->assemble( @tokens );

Assembles the parsed token series into the source code for the equivalent Perl subroutine.

=item assemble_args

Called by assemble(), this method provides support for Mason's <%args> blocks.

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

=back

=head2 Private Functions

=over 4

=item _printable

  $special_characters_escaped = _printable( $source_string );

Converts non-printable characters to readable form using the standard backslash notation, such as "\n" for newline.

=back

=head2 Package Variables

=over 4

=item $Defaults{ debug }

Debugging flag activates warns throughout the code. Used by debug_msg().

=item $Defaults{ assembler }

Text elements used for subroutine assembly. Used by assemble().

=back


=head1 SEE ALSO

For a full-featured web application system using this template syntax, see L<HTML::Mason>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut
