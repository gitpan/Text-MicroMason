package Text::MicroMason;
$VERSION = 1.07;

@EXPORT_OK = qw( 
  compile execute safe_compile safe_execute compile_file execute_file 
);
sub import { require Exporter and goto &Exporter::import } # lazy Exporter

require 5.0; # The tests use the new subref->() syntax, but the module doesn't
use strict;
require Carp;

use vars qw( $Debug );
$Debug ||= 0;

######################################################################

%Text::MicroMason::Escape = ( 
  ( map { chr($_), unpack('H2', chr($_)) } (0..255) ),
  "\\"=>'\\', "\r"=>'r', "\n"=>'n', "\t"=>'t', "\""=>'"' 
);

# $special_characters_escaped = _printable( $source_string );
sub _printable ($) {
  local $_ = scalar(@_) ? (shift) : $_;
  return unless defined;
  s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$Text::MicroMason::Escape{$1}/sg;
  return "'$_'";
}

######################################################################

# Constant pre/postfix used for subroutine generation
$Text::MicroMason::Prefix ||= 'sub {
  local $SIG{__DIE__} = sub { die "MicroMason execution failed: ", @_ };
  my $OUT = ""; my $_out = sub { $OUT .= join "", @_ }; 
  my %ARGS = @_ if ($#_ % 2); ';

$Text::MicroMason::Postfix ||= '  ; return $OUT;' . "\n}";

$Text::MicroMason::FileIncluder ||= 'Text::MicroMason::execute_file';

# $perl_code = parse( $mason_text );
sub parse {
  my $template = join("\n", @_);
  
  my @tokens = ( $template =~ /\G (
    # Lines begining with %
    (?: \A|(?<=\r|\n) ) \% [^\n\r]* (?:\r\n|\r|\n|\z) |
    # Blocks in <%word> ... <%word> tags.
    \<\%(?:perl|args|once|init|cleanup)\> .*? \<\/\%\w{4,7}\> (?:\r\n|\r|\n)? | 
    # Blocks in <% ... %> tags.
    \<\% .*? \%\> | 
    # Blocks in <& ... &> tags.
    \<\& .*? \&\> | 
    # Things that don't match the above.
    (?: 
      [^\<\r\n%]+ | \<(?!\%|\&) | (?<=[^\r\n\<])% |
      (?:\r\n|\r|\n)(?:\z|[^\r\n\%\<]|(?=\r\n|\r|\n|\%)|\<[^\%\&]|(?=\<[\%\&])) 
    )+ (?:(?:\r\n|\r|\n)+(?:\z|(?=\%|\<\[\%\&])) )?
  )/gxs );
  
  my $parsed = join('', @tokens);
  if ( $Debug ) {
    warn( "Source: " . length($template) . " " . _printable($template) . "\n" ); 
    warn( "Parsed: " . length($parsed) . " " . _printable($parsed) . "\n" ); 
    warn( "Tokens: " . join(', ', map _printable($_), @tokens ) . "\n" ); 
  }
  
  if ( ( (my $count = length($parsed)) != length( $template ) ) ) {
    Carp::croak("MicroMason parsing halted at $count of " . length($template) .
	 " characters: " . _printable(substr($template, $count)) . ", after " .
	 join(', ', map _printable($_), reverse( (reverse @tokens)[0..2]) ) );
  }

  my @pre = $Text::MicroMason::Prefix;
  my @post = $Text::MicroMason::Postfix;
  my @code; push @code, map( {
    if ( s/\A\n?\%\s?// ) {
      # Lines begining with %
      $_
    } elsif ( s/\A\<\%perl\>// ) {
      # Blocks in <%perl> ... <%perl> tags.
      s/\<\/\%perl\>\Z// and $_
    } elsif ( s/\A\<\%init\>// ) {
      # Blocks in <%init> ... <%init> tags get moved up to start of sub
      s/\<\/\%init\>\Z// and unshift(@code, "$_;") and ()
    } elsif ( s/\A\<\%cleanup\>// ) {
      # Blocks in <%cleanup> ... <%cleanup> tags get moved down to end of sub
      s/\<\/\%cleanup\>\Z// and unshift(@post, "$_;") and ()
    } elsif ( s/\A\<\%once\>// ) {
      # Blocks in <%once> ... <%once> tags get moved up above the sub
      s/\<\/\%once\>\Z// and unshift(@pre, "$_;") and ()
    } elsif ( s/\A\<\%args\>// ) {
      # Blocks in <%args> ... <%args> tags.
      s/\<\/\%args\>\Z//;
      s/^\s*([\$\@\%])(\w+) (?:\s* => \s* ([^\r\n]+))?/
	"my $1$2 = exists \$ARGS{$2} ? " . 
	( ($1 eq '$') ? "\$ARGS{$2}" : "$1\{ \$ARGS{$2} }" ) . " : " . 
	($3 ? $3 : qq{Carp::croak("no value sent for required parameter '$2'")}) 
	. ";"/gexm;
      $_ = qq{($#_ % 2) or Carp::croak("Odd number of parameters passed to sub expecting name/value pairs"); $_}.
      push(@pre,$_) and ();
    } elsif ( /\A\<\%(.*)\%\>/ ) {
      # Blocks in <% ... %> tags.
      "  &\$_out( do { $1 } );"
    } elsif ( /\A\<\&\s*(.*)\&\>/ ) {
      # Blocks in <& ... &> tags.
      "  &\$_out( $Text::MicroMason::FileIncluder( $1 ) );"
    } else {
      # Things that don't match the above.
      s/([\\\'])/\\$1/g; "  &\$_out('$_');"
    }
  } @tokens );
  
  my $code = join "\n", @pre, @code, @post;
  if ( $Debug ) {
    warn "MicroMason subroutine: $code\n";
  }

  return $code;
} 

######################################################################

# $code_ref = compile( $mason_text );
sub compile {
  my $code = parse( @_ );

  # Template code will be compiled in the below package; strict it.
  package Text::MicroMason::Commands; 
  use strict; 
  
  eval($code) or Carp::croak("MicroMason compilation failed: $@\n" . 
	"Error in template subroutine: $code");
} 

# $result = execute( $mason_text, %args );
sub execute {
  my $sub_ref = (ref($_[0]) eq 'CODE') ? (shift) : compile( shift ); 
  &$sub_ref( @_ )
}

######################################################################

# $code_ref = compile_file( $filename );
sub compile_file {
  my $file = shift 
    or Carp::croak("MicroMason: filename is missing or empty");

  # warn "MicroMason reading file: $file\n";
  my $content;
  READ_FILE: {
    local *FILE;
    open FILE, "$file" or Carp::croak("MicroMason can't read from $file: $!");
    local $/ = undef;
    $content = <FILE>;
    close FILE;
  }
  
  my $code = parse( $content );
  
  eval($code) or Carp::croak("MicroMason compilation failed: $@\n" . 
	"Error in template file $file, interpreted as: $code");
}

# $result = execute_file( $filename, %args );
sub execute_file {
  my $sub_ref = (ref($_[0]) eq 'CODE') ? (shift) : compile_file( shift ); 
  &$sub_ref( @_ )
}

######################################################################

# $code_ref = safe_compile( $mason_text );
# $code_ref = safe_compile( $safe_ref, $mason_text );
sub safe_compile {
  require Safe;
  my $safe = ( ref $_[0] ? shift : Safe->new );
  my $code = parse( @_ ); 
  $safe->reval($code) or Carp::croak("MicroMason compilation failed: $@\n" . 
	"Error in template subroutine: $code");
}

# $result = safe_execute( $mason_text, %args );
# $result = safe_execute( $safe_ref, $mason_text, %args );
sub safe_execute {
  my $sub_ref = safe_compile(splice @_, 0, ref($_[0]) ? 2 : 1  ); 
  &$sub_ref( @_ )
}

######################################################################

foreach my $sub ( @Text::MicroMason::EXPORT_OK ) {
  no strict 'refs';
  my $code = *{__PACKAGE__."::$sub"}{CODE};
  *{__PACKAGE__."::try_$sub"} = sub {
    my $result = eval { local $SIG{__DIE__}; &$code(@_) };
    wantarray ? ($result, $@) : $result;
  }
}
push @Text::MicroMason::EXPORT_OK, map "try_$_", @Text::MicroMason::EXPORT_OK;

######################################################################

1;

__END__

######################################################################

### Experimental ###
# To support use of Cache::Cache without focing a dependency on it
MICRO_CACHE_CLASS: {
  package Text::MicroMason::BasicCache;
  sub new { my $class = shift; bless { @_ }, $class }
  sub get { (shift)->{ (shift) } }
  sub set { (shift)->{ (shift) } = (shift) }
  sub clear { %{ (shift) } = () }
}

### Experimental ###
use vars qw( $FileCodeCache );
$FileCodeCache = Text::MicroMason::BasicCache->new();

### Experimental ###
# $code_ref = compile_file_codecache( $filename );
# $code_ref = compile_file_codecache( $filename, $cache );
sub compile_file_codecache {
  my $file = shift 
    or Carp::croak("MicroMason: filename is missing or empty");
  
  my $cache = shift || $FileCodeCache;
  
  my $time = time();
  
  my $cache_entry = $cache->get( $file );
  if ( $cache_entry ) {
    unless ( ref( $cache_entry) eq 'ARRAY' and $#$cache_entry == 2 ) {
      Carp::croak("MicroMason: file code cache '$cache' hold corrupted data; " . 
			      "value for '$file' is '$cache_entry'");
    }
  } else {
    $cache_entry = [ 0, 0, undef ];
  }
  
  if ( $cache_entry->[0] < $time ) {
    $cache_entry->[0] = time();
    my $mtime = -M $file;
    if ( $cache_entry->[1] < $mtime ) {
      $cache_entry->[1] = $mtime;
      $cache_entry->[2] = compile_file( $file );
    }
    $cache->set( $file, $cache_entry );
  }

  return $cache_entry->[2]
}

### Experimental ###
# $result = execute_file_codecache( $filename, $cache, %args );
sub execute_file_codecache {
  my $sub_ref = compile_file_codecache( shift, shift ); 
  &$sub_ref( @_ )
}

######################################################################

# $code_ref = compiler( text => $mason_text, %options );
# $code_ref = compiler( file => $filename, %options );
#     %options: safe_partition => 1, 
#		safe_options => [ share => \&Text::MicroMason::execute_file ],
#		compile_errors => 1, 
#		runtime_errors => 1, 
#		file_code_cache => 1, 
#		runtime_cache => 1
# sub compiler { ... }

######################################################################

1;

__END__

=head1 NAME

Text::MicroMason - Simplified HTML::Mason Templating


=head1 SYNOPSIS

Mason syntax provides several ways to mix Perl into a text template:

    $template = <<'END_TEMPLATE';
    <%args>
      $name
    </%args>
    % if ( $name eq 'Dave' ) {
      I'm sorry <% $name %>, I'm afraid I can't do that right now.
    % } else {
      <%perl>
	my $hour = (localtime)[2];
	my $daypart = ( $hour > 11 ) ? 'afternoon' : 'morning'; 
      </%perl>
      Good <% $daypart %>, <% $name %>!
    % }
    END_TEMPLATE

Use the execute function to parse and evalute a template:

    use Text::MicroMason qw( execute );
    print execute($template, 'name'=>'Dave');

Or compile it into a subroutine, and evalute repeatedly:

    use Text::MicroMason qw( compile );
    $coderef = compile($template);
    print $coderef->('name'=>'Dave');
    print $coderef->('name'=>'Bob');

Templates stored in files can be run directly or included in others:

    use Text::MicroMason qw( execute_file );
    print execute_file( "./greeting.msn", 'name'=>'Charles');

Safe usage restricts templates from accessing your files or data:

    use Text::MicroMason qw( safe_execute );
    print safe_execute( $template, 'name'=>'Bob');

All above functions are available in an error-catching "try_*" form:

    use Text::MicroMason qw( try_execute );
    ($result, $error) = try_execute( $template, 'name'=>'Alice');


=head1 DESCRIPTION

Text::MicroMason interpolates blocks of Perl code embedded into text
strings, using the simplest features of HTML::Mason.

Here's an example of Mason-style templating, taken from L<HTML::Mason>:

    % my $noun = 'World';
    Hello <% $noun %>!
    How are ya?

Interpreting this template with Text::MicroMason produces the same output as it would in HTML::Mason:

    Hello World!
    How are ya?

=head1 TEMPLATE SYNTAX

Text::MicroMason supports the following subset of the HTML::Mason syntax:

=over 4

=item *

I<literal_text>

Anything not specifically parsed by one of the below rules is interpreted as literal text.

=item *

E<lt>% I<perl_expr> %E<gt>

A Perl expression to be interpolated into the result.

For example, the following template text will return a scheduled
greeting:

    Good <% (localtime)[2]>11 ? 'afternoon' : 'morning' %>.

The block may span multiple lines and is scoped inside a "do" block,
so it may contain multiple Perl statements and it need not end with
a semicolon.

    Good <% my $h = (localtime)[2]; $h > 11 ? 'afternoon' 
                                            : 'morning'  %>.

=item *

% I<perl_code>

Lines which begin with the % character, without any leading
whitespace, may contain arbitrary Perl code to be executed when
encountering this portion of the template.  Their result is not
interpolated into the result.

For example, the following template text will return a scheduled
greeting:

    % my $daypart = (localtime)[2]>11 ? 'afternoon' : 'morning';
    Good <% $daypart %>.

The line may contain one or more statements.  This code is not
placed in its own scope, and so should include a semicolon at the
end, unless it deliberately forms a spanning block scope closed by
a later perl block. Without a semicolon, the Perl code can include
flow-control statements whose scope stretches across multiple
blocks.

For example, the following template text will return one of two different messages each time it's interpreted:

    % if ( int rand 2 ) {
      Hello World!
    % } else {
      Goodbye Cruel World!
    % }

This also allows you to quickly comment out sections of a template by prefacing each line with C<% #>.

=item *

E<lt>%perlE<gt> I<perl_code> E<lt>/%perlE<gt>

Blocks surrounded by %perl tags may contain arbitrary Perl code.
Their result is not interpolated into the result.

These blocks may span multiple lines in your template file. For
example, the below template initializes a Perl variable inside a
%perl block, and then interpolates the result into a message.

    <%perl> 
      my $count = join '', map "$_... ", ( 1 .. 9 ); 
    </%perl>
    Here are some numbers: <% $count %>

The block may contain one or more statements. 
This code is not placed in its own scope, and so should include a
semicolon at the end, unless it deliberately forms a spanning block
scope closed by a later perl block.

For example, when the below template text is evaluated it will
return a sequence of digits:

    Here are some numbers: 
    <%perl> 
      foreach my $digit ( 1 .. 9 ) { 
    </%perl>
	<% $digit %>... 
    <%perl> 
      } 
    </%perl>

Note that the above example includes extra whitespace for readability,
some of which will also show up in the output, but these blocks are not
whitespace sensitive, so the template could be combined into a
single line if desired.

=item *

E<lt>%initE<gt> I<perl_code> E<lt>/%initE<gt>

Similar to a %perl block, except that the code is moved up to the start of the subroutine. This allows a template's initialization code to be moved to the end of the file rather than requiring it to be at the top.

For example, the following template text will return a scheduled
greeting:

    Good <% $daypart %>.
    <%init> 
      my $daypart = (localtime)[2]>11 ? 'afternoon' : 'morning';
    </%init>

=item *

E<lt>%cleanupE<gt> I<perl_code> E<lt>/%cleanupE<gt>

Similar to a %perl block, except that the code is moved down to the end of the subroutine. 

=item *

E<lt>%onceE<gt> I<perl_code> E<lt>/%onceE<gt>

Similar to a %perl block, except that the code is executed once,
when the template is first compiled. (If a caller is using execute,
this code will be run repeatedly, but if they call compile and then
invoke the resulting subroutine multiple times, the %once code will
only execute during the compilation step.)

This code does not have access to %ARGS and can not generate output.
It can be used to define constants, create persistent variables,
or otherwise prepare the environment.

For example, the following template text will return a increasing
number each time it is called:

    <%once> 
      my $counter = 1000;
    </%once>
    The count is <% ++ $counter %>.

=item *

E<lt>%argsE<gt> I<variable> => I<default> E<lt>/%argsE<gt>

Defines a collection of variables to be initialized from named arguments passed to the subroutine. Arguments are separated by one or more newlines, and may optionally be followed by a default value. If no default value is provided, the argument is required and the subroutine will croak if it is not provided. 

For example, adding the following block to a template will initialize the three named variables, and will fail if no C<a =E<gt> '...'> argument pair is passed:

  <%args>
    $a
    @b => qw( foo bar baz )
    %c => ()
  </%args>

All the arguments are available as lexically scoped ("my") variables in the rest of the component. Default expressions are evaluated in top-to-bottom order, and one expression may reference an earlier one.

Only valid Perl variable names may be used in <%args> sections. Parameters with non-valid variable names cannot be pre-declared and must be fetched manually out of the %ARGS hash. 

=item *

E<lt>& I<template_filename>, I<arguments> &E<gt>

Includes the results of a separate file containing MicroMason code, compiling it and executing it with any arguments passed after the filename.

For example, we could place the following template text into an separate 
file:

    Good <% $ARGS{hour} >11 ? 'afternoon' : 'morning' %>.

Assuming this file was named "greeting.msn", its results could be embedded within the output of another script as follows:

  <& "greeting.msn", hour => (localtime)[2] &>

=back

=head1 FUNCTION REFERENCE

Text containing MicroMason markup code is interpreted and executed by calling the following functions. 

You may import any of these functions by including them in your C<use Text::MicroMason> call.

=head2 Invocation

To evaluate a Mason-like template, pass it to execute():

  $result = execute( $mason_text );

Alternately, you can call compile() to generate a subroutine for your template, and then run the subroutine:

  $result = compile( $mason_text )->();

If you will be interpreting the same template repeatedly, you can save the compiled version for faster execution:

  $sub_ref = compile( $mason_text );
  $result = $sub_ref->();

(Note that the $sub_ref->() syntax is unavailable in older versions of Perl; use the equivalent &$sub_ref() syntax instead.)

=head2 Argument Passing

You can also pass a list of key-value pairs as arguments to execute, or to the compiled subroutine:

  $result = execute( $mason_text, %args );
  
  $result = $sub_ref->( %args );

Within the scope of your template, any arguments that were provided will be accessible in the global @_, the C<%ARGS> hash, and any variables named in an %args block.

For example, the below calls will all return '<b>Foo</b>':

  execute('<b><% shift(@_) %></b>', 'Foo');
  execute('<b><% $ARGS{label} %></b>', label=>'Foo');
  execute('<%args>$label</%args><b><% $label %></b>', label=>'Foo');

=head2 Error Checking

Both compilation and run-time errors in your template are handled
as fatal exceptions. MicroMason will croak() if you attempt to
compile or execute a template which contains a incorrect fragment
of Perl syntax. Similarly, if the Perl code in your template causes
die() or croak() to be called, this will interupt your program
unless caught by an eval block.

For convenience, you may use the provided try_execute() and
try_compile() functions, which wrap an eval { } block around the call
to the basic execute() or compile() functions. In a scalar context
they return the result of the call, or undef if it failed; in a
list context they return the results of the call (undef if it
failed) followed by the error message (undef if it succeeded). For
example:

  ($result, $error) = try_execute( $mason_text );
  if ( ! $error ) {
    print $result;
  } else {
    print "Unable to execute template: $error";
  }

=head2 Template Files

A parallel set of functions exist to handle templates which are stored in a file:

  $template = compile_file( './report_tmpl.msn' );
  $result = $template->( %args );

  $result = execute_file( './report_tmpl.msn', %args );

A matching pair of try_*() wrappers are available to catch run-time errors in reading the file or parsing its contents:

  ($template, $error) = try_compile_file( './report_tmpl.msn' );

  ($result, $error) = try_execute_file( './report_tmpl.msn', %args );

Template documents are just plain text files that contains the string to be parsed. The files may have any name you wish, and the .msn extension shown above is not required.

=head2 Safe Compartments

If you wish to restrict the operations that a template can perform,
use the safe_compile() and safe_execute() functions, or their
try_*() wrappers.

By default, these safe calls prevent the code in a template from
performing any system activity or accessing any of your other Perl
code.  Violations may result in either compile-time or run-time
errors, so make sure you are using the try_* wrappers or your own
eval block to catch exceptions.

  ($result, $error) = try_safe_execute( $mason_text );

To enable some operations or share variables or functions with the
template code, create a Safe compartment and configure it, then
pass it in as the first argument to safe_compile() or safe_execute()
or their try_* equivalents:

  $safe = Safe->new();
  $safe->permit('time');
  $safe->share('$foo');
  ($result, $error) = try_safe_execute( $safe, $mason_text );

For example, if you want to be able to use the C<E<lt>& I<file> &E<gt>> include syntax from within a template interpreted by safe_compile(), you must share() the execute_file function so that it's visible within the compartment:

  $safe = Safe->new();
  $safe->share('&Text::MicroMason::execute_file');
  ($result, $error) = try_safe_execute( $safe, $mason_text );

In practice, for greater security, consider creating your own wrapper around execute_file that verifies its arguments and only opens files to which you wish to grant access, and then configure both Safe and MicroMason to allow its use:

  sub execute_permitted { 
    my ( $file, %args ) = @_;
    die "Not permitted" if ( $file =~ m{\.|/} );
    execute_file( $file, %args );
  }
  $safe = Safe->new();
  $safe->share('&execute_permitted');
  local $Text::MicroMason::FileIncluder = '&execute_permitted';
  ($result, $error) = try_safe_execute( $safe, $mason_text );

=head1 IMPLEMENTATION NOTES

When your template is compiled, all of the literal (non-Perl) pieces
are converted to C<$_out-E<gt>('text');> statements, and the
interpolated expressions are converted to C<$_out-E<gt>( expr );>
statements. Code from %perl blocks and % lines are included exactly
as-is. 

Your code is eval'd in the C<Text::MicroMason::Commands> package. 
The C<use strict;> pragma is enabled by default to simplify debugging.

=head2 Internal Sub-templates

You can create sub-templates within your template text by defining
them as anonymous subroutines and then calling them repeatedly.
For example, the following template will concatenate the results of 
the draw_item sub-template for each of three items:

    <h1>We've Got Items!</h1>
    
    % my $draw_item = sub {
      <p><b><% $_[0] %></b>:<br>
	<a href="/more?item=<% $_[0] %>">See more about <% $_[0] %>.</p>
    % };
    
    <%perl>
      foreach my $item ( qw( Foo Bar Baz ) ) {
	$draw_item->( $item );
      }
    </%perl>

=head2 Returning Text from Perl Blocks

To append to the result from within Perl code, call $_out->(I<text>). 
(The $_out->() syntax is unavailable in older versions of Perl; use the
equivalent &$_out() syntax instead.)

For example, the below template text will return '123456789' when it is
evaluated:

    <%perl>
      foreach my $digit ( 1 .. 9 ) {
	$_out->( $digit )
      }
    </%perl>

You can also directly manipulate the value $OUT, which contains the
accumulating result. 

For example, the below template text will return an altered version of its
message if a true value for 'minor' is passed as an argument when the
template is executed:

    This is a funny joke.
    % $OUT =~ tr[a-z][n-za-m] if $ARGS{minor};


=head1 DIAGNOSTICS

The following diagnostic messages are produced for the indicated error conditions (where %s indicates variable message text):

=over 4

=item *

MicroMason parsing halted at %s

Indicates that the parser was unable to finish tokenising the source text. Generally this means that there is a bug somewhere in the regular expressions used by parse(). 

(If you encounter this error, please feel free to file a bug report or send an example of the error to the author using the addresses below, and I'll attempt to correct it in a future release.)

=item *

MicroMason compilation failed: %s

The template was parsed succesfully, but the Perl subroutine declaration it was converted to failed to compile. This is generally a result of a syntax error in one of the Perl expressions used within the template. 

=item * 

Error in template subroutine: %s

Additional diagnostic for compilation errors, showing the text of the subroutine which failed to compile.

=item * 

Error in template file %s, interpreted as: %s

Additional diagnostic for compilation errors in external files, showing the filename and the text of the subroutine which failed to compile.

=item * 

MicroMason execution failed: %s

After parsing and compiling the template succesfully, the subroutine was run and caused a fatal exception, generally because that some Perl code used within the template caused die() to be called (or an equivalent function like croak or confess).

=item *

MicroMason: filename is missing or empty

One of the compile_file or execute_file functions was called with no arguments, or with an empty or undefined filename.

=item *

MicroMason can't read from %s: %s

One of the compile_file or execute_file functions was called but we were unable to read the requested file, because the file path is incorrect or we have insufficient priveleges to read that file.

=back


=head1 MOTIVATION

The HTML::Mason module provides a useful syntax for dynamic template
interpretation (sometimes called embedded scripting):  plain text
(or HTML) containing occasional chunks of Perl code whose results
are interpolated into the text when the template is "executed."

However, HTML::Mason also provides a full-featured web application
framework with mod_perl integration, a caching engine, and numerous
other functions, and there are times in which I'd like to use the
templating capability without configuring a full Mason installation.

Thus, the Text::MicroMason module was born: it supports the core
aspects of the HTML::Mason syntax ("<%...%>" expressions, "%...\n"
and "<%perl>...</%perl>" blocks, "<& file &>" includes, "%ARGS"
and "$_out->()" ), and omits the features that are web specific
(like autohandlers) or are less widely used (like "<%method>"
blocks).

=head2 Related Modules

You may well be thinking "yet another dynamic templating module?
Sheesh!" And you'd have a good point. There certainly are a variety
of templating toolkits on CPAN already; even restricting ourselves
to those which use Perl syntax for both interpolated expressions
and flow control (as opposed to "little languages") there's a fairly
crowded field, including L<Template::Toolkit|Template::Toolkit>,
L<Template::Perl|Template::Perl>, L<Text::Template|Text::Template>,
and L<Text::ScriptTemplate|Text::ScriptTemplate>, as well as those
that are part of full-blown web application frameworks like
L<Apache::ASP|Apache::ASP>, ePerl, L<HTML::Embperl|HTML::Embperl>,
and L<HTML::Mason|HTML::Mason>.

Nonetheless, I think this module occupies a useful niche: it provides
a reasonable subset of HTML::Mason syntax in a very light-weight
fashion. In comparison to the other modules listed, MicroMason aims
to be fairly lightweight, using one eval per parse, converting the
template to an cacheable unblessed subroutine ref, eschewing method
calls, and containing just over a hundred lines of Perl code.


=head2 Compatibility with HTML::Mason

See L<HTML::Mason> for a much more full-featured version of the
capabilities provided by this module.

If you've already got HTML::Mason installed, configured, and loaded
into your process, you're probably better off using it rather than
this package. HTML::Mason's C<$interp-E<gt>make_component()> method
allows you to parse a text string without saving it to disk first.

The following sets of HTML::Mason features are B<not> supported by Text::MicroMason:

=over 4

=item *

No %attr, %shared, %method, or %def blocks.

=item *

No |h or |u options to escape the result of interpolated expressions.

=item *

No $m Mason interpreter context.

=item *

No $r request object

=item *

No shared files like autohandler and dhandler.

=item *

No mod_perl integration or configuration capability.

=back

=head1 DISTRIBUTION, INSTALLATION AND SUPPORT

=head2 Version

This is version 1.07 of Text::MicroMason.

=head2 Prerequisites

This module should work with any version of Perl 5, without platform
dependencies or additional modules beyond the core distribution.

=head2 Installation

You should be able to install this module using the CPAN shell interface:

  perl -MCPAN -e 'install Text::MicroMason'

Alternately, you may retrieve this package from CPAN or from the author's site:

=over 2

=item *

http://search.cpan.org/~evo/

=item *

http://www.cpan.org/modules/by-authors/id/E/EV/EVO

=item *

http://www.evoscript.org/Text-MicroMason/dist/

=back

After downloading the distribution, follow the normal procedure to unpack and install it, using the commands shown below or their local equivalents on your system:

  tar xzf Text-MicroMason-*.tar.gz
  cd Text-MicroMason-*
  perl Makefile.PL
  make test && sudo make install

=head2 Release Status

This module's CPAN registration should read:

  Name            DSLIP  Description
  --------------  -----  ---------------------------------------------
  Text::
  ::MicroMason    Rdpfp  Simplified HTML::Mason Templating

This module should be categorized under group 11, Text Processing
(although there's also an lesser argument for placing it 15 Web/HTML, 
where HTML::Mason appears).

This module has been available on CPAN for over two years, with a
relatively stable interface and feature set. If you encounter
any problems, please inform the author and I'll endeavor to patch
them promptly. 

=head2 Tested Platforms

This release has been tested succesfully on the following platforms:

  5.6.1 on darwin

Earlier releases have also tested OK on a wide variety of platforms.
You may review the current test results from CPAN-Testers:

=over 2

=item *

http://testers.cpan.org/show/Text-MicroMason.html

=back

=head2 Support

If you have questions or feedback about this module, please feel
free to contact the author at the below address. Although there is
no formal support program, I do attempt to answer email promptly. 

I would be particularly interested in any suggestions towards
improving the documentation, correcting any Perl-version or platform
dependencies, as well as general feedback and suggested additions.

Bug reports that contain a failing test case are greatly appreciated,
and suggested patches will be promptly considered for inclusion in
future releases.

To report bugs via the CPAN web tracking system, go to 
C<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-MicroMason> or send mail 
to C<Dist=Text-MicroMason#rt.cpan.org>, replacing C<#> with C<@>.

=head2 Community

If you've found this module useful or have feedback about your
experience with it, consider sharing your opinion with other Perl
users by posting your comment to CPAN's ratings system:

=over 2

=item *

http://cpanratings.perl.org/rate/?distribution=Text-MicroMason

=back

For more general discussion, you may wish to post a message on PerlMonks or the comp.lang.perl.misc newsgroup:

=over 2

=item *

http://www.perlmonks.org/index.pl?node=Seekers%20of%20Perl%20Wisdom

=item *

http://groups.google.com/groups?group=comp.lang.perl.misc

=back

=head2 Development Plans

=over 4 

=item *

Complete and test compile_file_codecache and related functions.

=item *

Consider deprecating most or all of the existing public interface in favor of a single compiler() function that supports all of the possible options, including files, code and result caches, and exception handling.

=back

=head2 Change History

=over 4

=item 2003-09-26

Discard line break after <%perl> block as suggested by Tommi
Maekitalo. Note that removing these line breaks may affect the
rendering of your current templates! Although I am typically hesitant
to change established behavior, this does improve the template
output and brings us into line with HTML::Mason's behavior.

Added $Debug flag and support for <%args> blocks based on a
contribution by Tommi Maekitalo.

Adjusted internals to allow block reordering, and added support
for <%init> and <%once>.

Released as Text-MicroMason-1.07.tar.gz.

=item 2003-09-04

Changed the way that subroutines were scoped into the
Text::MicroMason::Commands namespace so that Safe compartments with
separate namespaces and shared symbols have the visibility that
one would expect.

Fixed a bug in which an unadorned percent sign halted parsing, as
reported by William Kern at PixelGate. Added a test to the end of
6-regression.t that fails under 1.05 but passes under 1.06 to
confirm this.

Simplified parser regular expressions by using non-greedy matching.

Added documentation for *_file() functions. 
Corrected documentation to reflect the fact that template code is not compiled with "use safe" in effect by default, but that this might change in the future.

Released as Text-MicroMason-1.06.tar.gz.

=item 2003-08-11

Adjusted regular expression based on parsing problems reported by Philip King and Daniel J. Wright, related to newlines and EOF. Added regression tests that fail under 1.04 but pass under 1.05 to ensure these features keep working as expected. 

Added non-printing-character escaping to parser failure and debugging messages to better track future reports of whitespace-related bugs.

Moved tests from test.pl into t/ subdirectory. 

Added experimental suppport for file code cache in compile_file_codecache.

Released as Text-MicroMason-1.05.tar.gz.

=item 2002-06-23 

Adjusted regular expression based on parsing problems reported by Mark Hampton. 

Added file-include support with <& ... &> syntax. 

Documentation tweaks. Adjusted version number to simpler 0.00 format.
Released as Text-MicroMason-1.04.tar.gz.

=item 2002-01-14 

Documentation tweaks based on feedback from Pascal Barbedor. Updated author's contact information.

=item 2001-07-01

Renamed from HTML::MicroMason to Text::MicroMason. Documentation tweaks. Released as Text-MicroMason-1.0.3.tar.gz.

=item 2001-04-10 

Munged interface for clarity. Added Safe support. 
Adjusted docs to reflect feedback from mason-users.
Released as HTML-MicroMason-1.0.2.tar.gz.

=item 2001-03-28 

Parser tweakage; additional documentation.
Added Exporter support.
Released as HTML-MicroMason-1.0.1.tar.gz.

=item 2001-03-26 

Added try_interpret; documented error messages.
  
=item 2001-03-23 

Extended documentation; added makefile, test script. 
Renamed accumulator to $OUT to match Text::Template.
Released as HTML-MicroMason-1.0.0.tar.gz.

=item 2001-03-22 

Created.

=back


=head1 CREDITS AND COPYRIGHT

=head2 Author

Developed by Matthew Simon Cavalletto at Evolution Softworks. 
More free Perl software is available at C<www.evoscript.org>.

You may contact the author directly at C<evo@cpan.org> or C<simonm@cavalletto.org>. 

=head2 The Shoulders of Giants

Based on the superb HTML::Mason, originally developed by Jonathan Swartz. 

=head2 Feedback and Suggestions 

My sincere thanks to the following users who have provided feedback:

  Pascal Barbedor
  Mark Hampton
  Philip King
  Daniel J. Wright
  William Kern
  Tommi Maekitalo

=head2 Copyright

Copyright 2002, 2003 Matthew Simon Cavalletto. 

Portions copyright 2001 Evolution Online Systems, Inc.

=head2 License

You may use, modify, and distribute this software under the same terms as Perl.

=cut
