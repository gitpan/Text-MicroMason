package Text::MicroMason;
$VERSION = 1.94_0;

require 5.0; # The tests use the new subref->() syntax, but the module doesn't
use strict;
require Carp;

require Text::MicroMason::Mason;

######################################################################

sub import {
  my $class = shift;
  
  return unless ( @_ );

  require Exporter; 
  require Text::MicroMason::Functions; 
  unshift @_, 'Text::MicroMason::Functions'; 
  goto &Exporter::import
}

######################################################################

sub class {
  my $callee = shift;
  Text::MicroMason::Mason->class( @_ );
}

sub new { 
  my $callee = shift;
  my @traits;
  while ( scalar @_ and $_[0] =~ /^\-(\w+)$/ ) {
    push @traits, $1;
    shift;
  }
  Text::MicroMason::Mason->class( @traits )->new( @_ ) 
}

######################################################################

1;

__END__

######################################################################

=head1 NAME

Text::MicroMason - Simplified HTML::Mason Templating


=head1 SYNOPSIS

Mason syntax provides several ways to mix Perl into a text template:

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

    <& "includes/standard_footer.msn" &>

    <%doc>
      Here's a private developr comment describing this template. 
    </%doc>

Create a Mason object to interpret the templates:

    use Text::MicroMason;
    $mason = Text::MicroMason->new();

Use the execute method to parse and evalute a template:

    print $mason->execute( text=>$template, 'name'=>'Dave' );

Or compile it into a subroutine, and evaluate repeatedly:

    $coderef = $mason->compile( text=>$template );
    print $coderef->('name'=>'Alice');
    print $coderef->('name'=>'Bob');

Templates stored in files can be run directly or included in others:

    print $mason->execute( file=>"./greeting.msn", 'name'=>'Charles');

For additional features, name the mixin classes to add to your Mason object:

    $mason = Text::MicroMason->new( qw( -CatchErrors -Safe -Filters ) );

You can import various functions if you prefer to avoid method calls:

    use Text::MicroMason::Functions qw( compile execute );

    print execute($template, 'name'=>'Dave');

    $coderef = compile($template);
    print $coderef->('name'=>'Bob');


=head1 DESCRIPTION

Text::MicroMason interpolates blocks of Perl code embedded into text
strings, using the simpler features of HTML::Mason.

MicroMason converts a template from a block of source text with special
embedded tags into a Perl subroutine which can accept arguments and returns
an output string.

The template syntax supported by Text::MicroMason and some useful template
developer techniques are described in L</"TEMPLATE SYNTAX">.

=head2 Function Exporter Interface

Importable functions are provided for users who prefer a procedural interface. 

The supported functions are listed in L<Text::MicroMason::Functions>. (For backwards compatibility, those functions can also be imported from the main Text::MicroMason package.) 

=head2 Object-Oriented Interface

The underlying implementation of MicroMason is object-oriented, with several mixin classes which can be dynamically combined to create subclasses with the requested combination of traits. 

The core functionality is provided by the abstract Base class and the Mason subclass. See L<Text::MicroMason::Base> and L<Text::MicroMason::Mason> for documentation of private methods and extension mechanisms. 

The following methods comprise the public interface for Text::MicroMason:

=over 4

=item new()

  $mason = Text::MicroMason->new();

Creates a new Text::MicroMason object. 

  $mason = Text::MicroMason->new( -Mixin1, -Mixin2, %attributes );

To obtain the functionality of one of the supported mixin classes, pass their names as arguments with leading dashes. Any other optional attributes can also be passed as key-value pairs.

This is a shortcut for calling the class() and new() methods:

  $mason = Text::MicroMason->class( @Mixins )->new( %attributes );

=item class()

  $subclass = Text::MicroMason->class( @Mixins );

Generates a subclass of Text::MicroMason::Mason that combines the list of provided mixin classes. 

=item compile()

  $code_ref = $mason->compile( $type => $source, %options );

Parses the provided template and converts it into a new Perl subroutine.

=item execute()

  $result = $mason->execute( $type => $source, \%options, @arguments );

Returns the results produced by the template, given the provided arguments.

=back


=head1 USAGE

=head2 Interpreting Templates

To compile a Mason-like template, pass it to the compile() method:

  $sub_ref = $mason->compile( text => $template );

To execute the template and obtain the output, call the compiled function: 

  $result = $sub_ref->( @args );

(Note that the $sub_ref->() syntax is unavailable in older versions of Perl; use the equivalent &$sub_ref() syntax instead.)

To compile and evaluate in one step, call the execute() method:

  $result = $mason->execute( text => $template, @args );

Calling execute repeatedly will be slower than compiling once and calling the template function repeatedly, unless you enable compilation caching; for details see L<Text::MicroMason::CompileCache>.

Each time you execute the template all of the logic will be re-evaluated, unless you enable execution caching, which stores the output of each template for each given set of arguments; for details see L<Text::MicroMason::ExecuteCache>.


=head2 Template Files

A parallel set of functions exist to handle templates which are stored in a file:

  $sub_ref = $mason->compile( file => $filename );
  $result = $sub_ref->( @args );

  $result = $mason->execute( file => $filename, @args );

Template documents are just plain text files that contains the string to be parsed. The files may have any name you wish, and the .msn extension shown above is not required.

The filename specifid can be absolute or relative to the current directory. If you want to specify a base path for template files, see L<Text::MicroMason::TemplateDir>.

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

Both compilation and run-time errors in your template are handled as fatal
exceptions. To prevent a template error from ending your program, enclose it in an eval block:

  my $result = eval { $mason->execute( text => $template ) };
  if ( $@ ) {
    print "Unable to execute template: $@";
  } else {
    print $result;
  }

To transparently add this functionality to your Mason object, see L<Text::MicroMason::CatchErrors>.

=head2 Security

By default, the code embedded in a template has accss to all of the capabilities of your Perl process, and could potentially perform dangerous activities such as accessing or modifying files and starting other programs. 

If you need to execute untrusted templates, use the Safe module, which can restrict the operations and data structures that template code can access.
To add this functionality to your Mason object, see L<Text::MicroMason::Safe>.


=head1 TEMPLATE SYNTAX

Here's an example of Mason-style templating, taken from L<HTML::Mason>:

    % my $noun = 'World';
    Hello <% $noun %>!
    How are ya?

Interpreting this template with Text::MicroMason produces the same output as it would in HTML::Mason:

    Hello World!
    How are ya?

Text::MicroMason::Mason supports a syntax that is mostly a subset of that used by HTML::Mason.

=head2 Template Markup

The following types of markup are recognized in template pages:

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

The line may contain one or more statements.  This code is automatically
terminated by a semicolon but it is not placed in its own block scope, so
it can still open a spanning block scope closed by a later perl block.

For example, the following template text will return one of two different messages each time it's interpreted:

    % if ( int rand 2 ) {
      Hello World!
    % } else {
      Goodbye Cruel World!
    % }

This also allows you to quickly comment out sections of a template by prefacing each line with C<% #>.

This is equivalent to a <%perl>...</%perl> block.

=item *

E<lt>& I<template_filename>, I<arguments> &E<gt>

Includes the results of a separate file containing MicroMason code, compiling it and executing it with any arguments passed after the filename.

For example, we could place the following template text into an separate 
file:

    Good <% $ARGS{hour} >11 ? 'afternoon' : 'morning' %>.

Assuming this file was named "greeting.msn", its results could be embedded within the output of another script as follows:

  <& "greeting.msn", hour => (localtime)[2] &>

=item *

E<lt>%I<name>E<gt> ... E<lt>/%I<name>E<gt>

A named block contains a span of text. The name at the start and end must match, and must be one of the supported block names. 

Depending on the name, performs one of the behaviors described in L</"Named Blocks">.

=back

=head2 Named Blocks

The following types of named blocks are supported:

=over 4

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

The code may contain one or more statements.  This code is automatically
terminated by a semicolon but it is not placed in its own block scope, so
it can still open a spanning block scope closed by a later perl block.

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

If the block is immediately followed by a line break, that break is
discarded.  These blocks are not whitespace sensitive, so the template
could be combined into a single line if desired.

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

E<lt>%initE<gt> I<perl_code> E<lt>/%initE<gt>

Similar to a %perl block, except that the code is moved up to the start of
the subroutine. This allows a template's initialization code to be moved to
the end of the file rather than requiring it to be at the top.

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

E<lt>%docE<gt> ... E<lt>/%docE<gt>

Provides space for template developer documentation or comments which are not included in the output.

=back

The following types of named blocks are not supported by HTML::Mason, but are supported here as a side-effect of the way the lexer and assembler are implemented.

=over 4

=item *

E<lt>%textE<gt> ... E<lt>/%textE<gt>

Produces literal text in the template output. Can be used to surround text
that contains other markup tags that should not be interpreted.

Equivalent to un-marked-up text.

=item *

E<lt>%outputE<gt> ... E<lt>/%outputE<gt>

A Perl expression to be interpolated into the result.
The block may span multiple lines and is scoped inside a "do" block,
so it may contain multiple Perl statements and it need not end with
a semicolon. 

Equivalent to the C<E<lt>% ... %E<gt>> markup syntax.

=item *

E<lt>%includeE<gt> I<template_filename>, I<arguments> E<lt>/%includeE<gt>

Includes the results of a separate file containing MicroMason code, compiling it and executing it with any arguments passed after the filename.

  <%include> "greeting.msn", hour => (localtime)[2] </%include>

Equivalent to the C<E<lt>& ... &E<gt>> markup syntax.

=back


=head1 TEMPLATE CODING TECHNIQUES

=head2 Assembling Perl Source Code

When Text::MicroMason::Base assembles your lexed template into the
equivalent Perl subroutine, all of the literal (non-Perl) pieces are
converted to C<$_out-E<gt>('text');> statements, and the interpolated
expressions are converted to C<$_out-E<gt>( do { expr } );> statements.
Code from %perl blocks and % lines are included exactly as-is.

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

You can also directly manipulate the value @OUT, which contains the
accumulating result. 

For example, the below template text will return an altered version of its
message if a true value for 'minor' is passed as an argument when the
template is executed:

    This is a funny joke.
    % if ( $ARGS{minor} ) { foreach ( @OUT ) { tr[a-z][n-za-m] } }


=head1 SYNTAX MIXINS

This behavior can be supplemented or overridden by subclasses and mixins. (Of particular interest are the private lex(), assemble(), and eval_sub() methods.) For more information about how these mixin behaviors are implemented and selected, see L<Text::MicroMason/"Object-Oriented Interface">.

The following mixin class adds an additional feature to the syntax described above.

=head2 Filters

HTML::Mason provides an expression filtering mechanism which is typically used for applying HTML and URL escaping functions to output. 

The Filters mixin provides this capability for Text::MicroMason templates. To select it, add its name to your Mason initialization call:

  my $mason = Text::MicroMason->new( -Filters );

Output expressions may then be followed by "|h" or "|u" escapes; for example this line would convert any ampersands in the output to the equivalent HTML entity:

  Welcome to <% $company_name |h %>

For more information see L<Text::MicroMason::Filters>

=head1 ALTERNATE SYNTAX

The following mixin classes replace the syntax described above with one that is quite different.

=head2 HTMLTemplate

The TextTemplate mixin replaces the supported template syntax with one similar to that used by the HTML::Template module.

For more information see L<Text::MicroMason::HTMLTemplate>

=head2 ServerPages

The ServerPages mixin replaces the supported template syntax with one similar to that used by the ASP and JSP templating systems.

For more information see L<Text::MicroMason::ServerPages>

=head2 TextTemplate

The TextTemplate mixin replaces the supported template syntax with one similar to that used by the Text::Template module.

For more information see L<Text::MicroMason::TextTemplate>


=head1 DIAGNOSTICS

The following diagnostic messages are produced for the indicated error conditions (where %s indicates variable message text):

=over 4

=item *

MicroMason parsing halted at %s

Indicates that the parser was unable to finish tokenising the source text. Generally this means that there is a bug somewhere in the regular expressions used by lex(). 

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

One of the compile or execute methods was called with an empty or undefined filename, or one of the compile_file or execute_file methods was called with no arguments.

=item *

MicroMason can't read from %s: %s

One of the compile_file or execute_file functions was called but we were unable to read the requested file, because the file path is incorrect or we have insufficient priveleges to read that file.

=back


=head1 SEE ALSO

For a full-featured web application system using this template syntax, see L<HTML::Mason>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut
