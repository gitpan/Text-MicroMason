package Text::MicroMason;
$VERSION = 1.97;

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

The template syntax supported by Text::MicroMason is described in 
L</"TEMPLATE SYNTAX">.

=head2 Function Exporter Interface

Importable functions are provided for users who prefer a procedural interface. 

The supported functions are listed in L<Text::MicroMason::Functions>. (For backwards compatibility, those functions can also be imported from the main Text::MicroMason package.) 

=head2 Template Compiler Objects

The underlying implementation of MicroMason is object-oriented, with several mixin classes which can be dynamically combined to create subclasses with the requested combination of traits. 

The core functionality is provided by the abstract Base class. See L<Text::MicroMason::Base> for documentation of private methods and extension mechanisms.

The standard template syntax is provided by the Mason subclass. See L<Text::MicroMason::Mason> for documentation of markup options. 

Other optional functionality is provided by mixin classes. For a list of available mixin classes, see L</"Usage Mixins"> and L</"Syntax Mixins">.

=head2 Public Methods

The following methods comprise the primary public interface for Text::MicroMason:

=over 4

=item class()

  $mason_class = Text::MicroMason->class( @Mixins );

Creates a Mason subclass that also inherits from the other classes named.

=item new()

  $mason = $mason_class->new( %attribs );

  $mason = Text::MicroMason->new( -Mixin1, -Mixin2, %attribs );

Creates a new Text::MicroMason object. 

To obtain the functionality of one of the supported mixin classes, you can either use the class() method to generate the mixed class before calling new(), or you can pass their names as arguments with leading dashes.

=item compile()

  $code_ref = $mason->compile( $type => $source, %attribs );

Parses the provided template and converts it into a new Perl subroutine. 

=item execute()

  $result = $mason->execute( $type => $source, @arguments );
  $result = $mason->execute( $type => $source, \%attribs, @arguments );

Returns the results produced by the template, given the provided arguments.

=back

Subclasses or mixins may define additional public methods.

=head2 Attributes

Some subclasses support or require values for various additional attributes.
You may pass attributes as key-value pairs to the new() method for persistant
use, or to the compile() or execute() methods to temporarily override the
persistant attributes for that template only.


=head1 USAGE

The compile() and execute() methods convert your template to runnable code.

=head2 Interpreting Templates

To compile a Mason-like template, pass it to the compile() method to produce a new Perl subroutine returned as a code reference:

  $sub_ref = $mason->compile( text => $template );

To execute the template and obtain the output, call the compiled function: 

  $result = $sub_ref->( @args );

(Note that the $sub_ref->() syntax is unavailable in older versions of Perl; use the equivalent &$sub_ref() syntax instead.)

To compile and evaluate in one step, call the execute() method:

  $result = $mason->execute( text => $template, @args );

=head2 Template Files

Change the first argument for acccess to templates which are stored in a file:

  $sub_ref = $mason->compile( file => $filename );
  $result = $sub_ref->( @args );

  $result = $mason->execute( file => $filename, @args );

Template files are just plain text files that contains the string to be parsed. The files may have any name you wish, and the .msn extension shown above is not required. The filename specified can either be absolute or relative to the program's current directory.

=head2 Argument Passing

You can also pass a list of key-value pairs as arguments to execute, or to the compiled subroutine:

  $result = $mason->execute( text => $template, %args );
  
  $result = $sub_ref->( %args );

Within the scope of your template, any arguments that were provided will be accessible in the global @_, the C<%ARGS> hash, and any variables named in an %args block.

For example, the below calls will all return '<b>Foo</b>':

  $mason->execute( text=>'<b><% shift(@_) %></b>', 'Foo');

  $mason->execute( text=>'<b><% $ARGS{label} %></b>', label=>'Foo');

  $mason->execute( text=>'<%args>$label</%args><b><% $label %></b>', label=>'Foo');

=head2 Usage Mixins

The following mixin classes can be layered on to your Mason object to provide additional functionality. 

To add a mixin's functionality, pass it's name with a dash to the new() method:

  $mason = Text::MicroMason->new( -CatchErrors, -PostProcess );

=over 4

=item CatchErrors

Both compilation and run-time errors in your template are handled as fatal
exceptions. To prevent a template error from ending your program, enclose it in an eval block:

  my $result = eval { $mason->execute( text => $template ) };
  if ( $@ ) {
    print "Unable to execute template: $@";
  } else {
    print $result;
  }

To transparently add this functionality to your Mason object, see L<Text::MicroMason::CatchErrors>.

=item CompileCache

Calling execute repeatedly will be slower than compiling once and calling the template function repeatedly, unless you enable compilation caching; for details see L<Text::MicroMason::CompileCache>.

=item ExecuteCache

Each time you execute the template all of the logic will be re-evaluated, unless you enable execution caching, which stores the output of each template for each given set of arguments; for details see L<Text::MicroMason::ExecuteCache>.

=item PostProcess

Allows you to specify one or more functions through which all template output should be passed before it is returned; for details see L<Text::MicroMason::PostProcess>.

=item Safe

By default, the code embedded in a template has accss to all of the capabilities of your Perl process, and could potentially perform dangerous activities such as accessing or modifying files and starting other programs. 

If you need to execute untrusted templates, use the Safe module, which can restrict the operations and data structures that template code can access.
To add this functionality to your Mason object, see L<Text::MicroMason::Safe>.

=item TemplateDir

The filenames passed to the compile() or execute() methods can be looked up relative to a base directory path or  the current template file. To add this functionality to your Mason object, see L<Text::MicroMason::TemplateDir>.

=back


=head1 TEMPLATE SYNTAX

Templates contain a mix of literal text to be output with some type of markup syntax which specifies more complex behaviors.

=head2 Mason Syntax

The default Text::MicroMason::Mason subclass provides lexer and assembler methods that handle most elements of HTML::Mason's template syntax.

    <%args>
      $name => 'Guest' 
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

For a definition of the template syntax, see L<Text::MicroMason::Mason>.

=head2 Syntax Mixin

The following mixin classes can be layered on to your Mason object to provide additional functionality. 

=over 4

=item Filters

HTML::Mason provides an expression filtering mechanism which is typically used for applying HTML and URL escaping functions to output. 

The Filters mixin provides this capability for Text::MicroMason templates. To select it, add its name to your Mason initialization call:

  my $mason = Text::MicroMason->new( -Filters );

Output expressions may then be followed by "|h" or "|u" escapes; for example this line would convert any ampersands in the output to the equivalent HTML entity:

  Welcome to <% $company_name |h %>

For more information see L<Text::MicroMason::Filters>

=back

=head2 Alternate Syntaxes

The following classes provide support for different template syntaxes. You can enable them using the same syntax for other mixin features.

=over 4

=item Embperl

The Embperl mixin replaces the Mason template syntax with one similar to that used by the HTML::Embperl module.

    [- my $name = $ARGS{name}; -]
    [$ if $name eq 'Dave' $]
      I'm sorry [+ $name +], I'm afraid I can't do that right now.
    [$ else $]
      [- 
	my $hour = (localtime)[2];
	my $daypart = ( $hour > 11 ) ? 'afternoon' : 'morning'; 
      -]
      Good [+ $daypart +], [+ $name +]!
    [$ endif $]

For more information see L<Text::MicroMason::Embperl>.

=item HTMLTemplate

The HTMLTemplate mixin replaces the Mason template syntax with one similar to that used by the HTML::Template module.

    <TMPL_IF NAME="user_is_dave">
      I'm sorry <TMPLVAR NAME="name">, I'm afraid I can't do that right now.
    <TMPL_ELSE>
      <TMPL_IF NAME="daytime_is_morning">
	Good morning, <TMPLVAR NAME="name">!
      <TMPL_ELSE>
	Good afternoon, <TMPLVAR NAME="name">!
      </TMPL_IF>
    </TMPL_IF>

For more information see L<Text::MicroMason::HTMLTemplate>.

=item ServerPages

The ServerPages mixin replaces the Mason template syntax with one similar to that used by the Apache::ASP module.

    <% my $name = $ARGS{name};
      if ( $name eq 'Dave' ) {  %>
      I'm sorry <%= $name %>, I'm afraid I can't do that right now.
    <% } else { 
	my $hour = (localtime)[2];
	my $daypart = ( $hour > 11 ) ? 'afternoon' : 'morning'; 
      %>
      Good <%= $daypart %>, <%= $name %>!
    <% } %>

For more information see L<Text::MicroMason::ServerPages>.

=item TextTemplate

The TextTemplate mixin replaces the Mason template syntax with one similar to that used by the Text::Template module.

    { $hour = (localtime)[2];
      $daypart = ( $hour > 11 ) ? 'afternoon' : 'morning'; 
    '' }
    Good { $daypart }, { $name }!

For more information see L<Text::MicroMason::TextTemplate>.

=back


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

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::Docs::ReadMe>.

=cut
