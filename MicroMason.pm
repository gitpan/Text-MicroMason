package Text::MicroMason;
$VERSION = 1.93_0;

require 5.0; # The tests use the new subref->() syntax, but the module doesn't
use strict;
require Carp;

require Text::MicroMason::Base;

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

sub new { 
  my $callee = shift;
  my @traits;
  while ( scalar @_ and $_[0] =~ /^\-(\w+)$/ ) {
    push @traits, $1;
    shift;
  }
  my $class = $callee->class( @traits );
  $class->new( @_ ) 
}

######################################################################

sub class {
  my $factory = shift;
  my @args = ( @_ > 1 ) ? @_ : ( ! $_[0] ) ? () : ref($_[0]) ? @{$_[0]} : $_[0];
  
  # warn "class with_traits -> " . join(', ', $factory, @args) . "\n";

  unshift @args, 'Base';

  my (@names, @packages);
  foreach my $trait ( @args ) {
    my $t_class = $trait;
    ( $t_class =~ /::/ ) or $t_class = "Text::MicroMason::$t_class";
    push @packages, $t_class;
    
    my $t_name = $trait;
    $t_name =~ s/.*:://;
    push @names, $t_name;

    my $t_file = "$t_class.pm";
    $t_file =~ s{::}{/}g;
    unless ( $INC{ $t_file } ) {
      # warn "require $t_file";
      require $t_file
    }
  }

  my $name = join('_', @names);
  
  my $new_class = $factory . "::" . $name;
  
  no strict;
  if ( $#packages and ! @{ $new_class . "::ISA" } ) {
    # warn "-> $new_class ISA ", reverse(@packages), "\n";
    @{ $new_class . "::ISA" } = reverse @packages;
  }
  
  return $new_class;
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
    my $mason = Text::MicroMason->new();

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

MicroMason converts a template from a block of source text with special embedded tags into a Perl subroutine which can accept arguments and returns an output string.

=head2 Template Syntax

Here's an example of Mason-style templating, taken from L<HTML::Mason>:

    % my $noun = 'World';
    Hello <% $noun %>!
    How are ya?

Interpreting this template with Text::MicroMason produces the same output as it would in HTML::Mason:

    Hello World!
    How are ya?

The template syntax supported by Text::MicroMason and some useful template developer techniques are described in L<Text::MicroMason::Devel>.

=head2 Function Exporter Interface

Importable functions are provided for users who prefer a procedural interface. 

The supported functions are listed in L<Text::MicroMason::Functions>. (For backwards compatibility, those functions can also be imported from the main Text::MicroMason package.) 

=head2 Object-Oriented Interface

The underlying implementation of MicroMason is object-oriented, with several mixin classes which can be dynamically combined to create subclasses with the requested combination of traits. 

=over 4

=item new()

  my $mason = Text::MicroMason->new();

  my $mason = Text::MicroMason->new( -Mixin1, -Mixin2, %attributes );

Creates a new Mason object. To obtain the functionality of one of the supported mixin classes, pass their names as arguments with leading dashes. Any other optional attributes can also be passed as key-value pairs.

This is a shortcut for calling the class() and new() methods:

  my $mason = Text::MicroMason->class( @Mixins )->new( %attributes );

=item class()

  my $subclass = Text::MicroMason->class( @Mixins );

Generates a subclass of Text::MicroMason::Base that combines the list of provided mixin classes. For a list of available mixins, see L</"Included Classes">.

=item compile()

  $code_ref = $mason->compile( $type => $source, %options );

Parses the provided template and converts it into a new Perl subroutine.

=item execute()

  $result = $mason->execute( $type => $source, \%options, @arguments );

Returns the results produced by the template, given the provided arguments.

=back

=head2 Included Classes

The following classes are included in this distribution:

=over 4

=item Base

The core functionality is provided by this superclass. See L<Text::MicroMason::Base>.

=item CatchErrors

Catches exceptions while compiling and executing templates and returns an error message instead of croaking. See L<Text::MicroMason::CatchErrors>.

=item CompileCache

Caches the compilation of templates into subroutines for repeated execution. See L<Text::MicroMason::CompileCache>.

=item ExecuteCache

Caches the output of templates for each set of arguments. See L<Text::MicroMason::ExecuteCache>.

=item Filters

Enables the filtering of expressions before they are output, using HTML::Mason's "|h" syntax. See L<Text::MicroMason::Filters>.

=item Safe

Adds support for Safe compartments, allowing you to restrict the operations that a template can perform. See L<Text::MicroMason::Safe>.

=item ServerPages

Supports an alternate template syntax similar to that used by Active Server Pages and Java Server Pages. See L<Text::MicroMason::ServerPages>.

=item TemplateDir

Finds template files relative to a base directory path or to the currently executing template. See L<Text::MicroMason::TemplateDir>.

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

For a full-featured web application system using this template syntax, see L<HTML::Mason>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut
