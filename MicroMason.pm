package Text::MicroMason;
$VERSION = 1.000_003;

@EXPORT_OK = qw( parse compile execute safe_compile safe_execute );
sub import { require Exporter and goto &Exporter::import } # lazy Exporter

require 5.0; # The tests use the new subref->() syntax, but the module doesn't
use strict;
require Carp;

######################################################################

# Template code will be compiled in the below package; strict it.
{ package Text::MicroMason::Commands;  use strict; }

# Constant pre/postfix used for subroutine generation
$Text::MicroMason::Prefix ||= 'package Text::MicroMason::Commands; sub {
  local $SIG{__DIE__} = sub { die "MicroMason execution failed: ", @_ };
  my $OUT = ""; my $_out = sub { $OUT .= join "", @_ }; my %ARGS = @_; ';

$Text::MicroMason::Postfix ||= '  return $OUT;' . "\n}";

######################################################################

# $perl_code = parse( $mason_text );
sub parse {
  my $template = join("\n", @_);
  
  my @tokens = ( $template =~ /(?:\A|\G)(
      # Lines begining with %
      (?: \A|(?<=\n) ) \% [^\n\r]+ (?:\r\n|\r|\n|\Z) |
      # Blocks enclosed in <%perl> ... <%perl> tags.
      \<\%perl\>(?: [^\<]+ | \<[^\/] | \<\/[^\%] | \<\/\%[^p] )+?\<\/\%perl\> |
      # Blocks enclosed in <% ... %> tags.
      \<\% (?: [^\%]+ | \%[^\>] )+ \%\> |
      # Things that don't match the above.
      (?: [^\<\n]+ | \<(?!\%) | \n(?:[^\n\%\<] | (?=\n) | \<[^\%] ) )+ 
			(?:\n(?:\Z|(?=\%|\<\%)) )?
    )/gxs );
  # warn "MicroMason tokens: " . join(', ', map "'$_'", @tokens ) . "\n";
  
  if ( ( (my $count = length(join '', @tokens)) < length( $template ) ) ) {
    Carp::croak("MicroMason parsing halted at '".substr($template, $count)."'");
  }
  
  my $code = join "\n", $Text::MicroMason::Prefix, map( {
    if ( s/\A\n?\%\s?// ) {
      # Lines begining with %
      $_
    } elsif ( s/\A\<\%perl\>// ) {
      # Blocks enclosed in <%perl> ... <%perl> tags.
      s/\<\/\%perl\>\Z// and $_
    } elsif ( /\A\<\%(.*)\%\>/ ) {
      # Blocks enclosed in <% ... %> tags.
      "  &\$_out(\n    $1\n  );"
    } else {
      # Things that don't match the above.
      s/([\\\'])/\\$1/g; "  &\$_out('$_');"
    }
  } @tokens ), $Text::MicroMason::Postfix;
  # warn "MicroMason subroutine: $code\n";

  return $code;
} 

# $code_ref = compile( $mason_text );
sub compile {
  my $code = parse( @_ );
  eval($code) or Carp::croak("MicroMason compilation failed: $@\n" . 
	"Error in template subroutine: $code");
} 

# $result = execute( $mason_text, %args );
sub execute {
  my $sub_ref = (ref($_[0]) eq 'CODE') ? (shift) : compile( shift ); 
  &$sub_ref( @_ )
}

######################################################################

sub safe_compile {
  require Safe;
  my $safe = ( ref $_[0] ? shift :  Safe->new );
  my $code = parse( @_ ); 
  $safe->reval($code) or Carp::croak("MicroMason compilation failed: $@\n" . 
	"Error in template subroutine: $code");
}

# $result = safe_execute( $mason_text, %args );
# $result = safe_execute( $safe_ref, $mason_text, %args );
sub safe_execute {
  my $sub_ref = (ref($_[0]) eq 'CODE') ? (shift) : 
		safe_compile(splice @_, 0, ref($_[0]) ? 2 : 1  ); 
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


=head1 NAME

Text::MicroMason - Simplified HTML::Mason Templating


=head1 SYNOPSIS

    # Mason templates provide several ways to mix Perl and text
    $template = <<'END_TEMPLATE';
    % if ( $ARGS{name} eq 'Dave' );
      I'm sorry <% $ARGS{name} %>, I'm afraid I can't do that right now.
    % } else {
      <%perl>
	my $hour = (localtime)[2];
	my $greeting = ( $hour > 11 ) ? 'afternoon' : 'morning'; 
      </%perl>
      Good <% $greeting %>, <% $ARGS{name} %>!
    % }
    END_TEMPLATE
    
    # Use the execute function to parse and evalute a template 
    use Text::MicroMason qw( execute );
    print execute($template, 'name'=>'Dave');
    
    # Or compile it into a subroutine, and evalute repeatedly
    use Text::MicroMason qw( compile );
    $coderef = compile($template);
    print $coderef->('name'=>'Dave');
    print $coderef->('name'=>'Bob');


=head1 MOTIVATION

The HTML::Mason module provides a useful syntax for dynamic template
interpretation (sometimes called embedded scripting):  plain text
(or HTML) containing occasional chunks of Perl code whose results
are interpolated into the text when the template is "executed."

However, HTML::Mason also provides a full-featured web application
framework, and sometimes I'd like to use this capability without
configuring a full Mason installation. 

Thus, the Text::MicroMason module was born: it supports the core aspects
of the HTML::Mason syntax ("<%perl>...</%perl>", "<%...%>", "%...\n",
"%ARGS" and "$_out->()" ), and omits the features that either require
file access (like autohandlers and "<& file &>" includes) or are less
widely used (like "<%method>" blocks).


=head1 DESCRIPTION

Text::MicroMason interpolates blocks of Perl code embedded into text
strings, using the simplest features of HTML::Mason.

=head2 Embedding Syntax

Here's an example of Mason templating, taken from L<HTML::Mason>:

    % my $noun = 'World';
    Hello <% $noun %>!
    How are ya?

Interpreting this template with Text::MicroMason produces the string:

    Hello World!
    How are ya?

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

The Perl code can include flow-control statements whose scope
stretches across multiple blocks. For example, when the below template
text is evaluated it will return a digit sequence similar to the
above:

    Here are some numbers: 
    <%perl> 
      foreach my $digit ( 1 .. 9 ) { 
    </%perl>
	<% $digit %>... 
    <%perl> 
      } 
    </%perl>

Note that the above example includes extra whitespace for readability,
which will also show up in the output, but these blocks are not
whitespace sensitive, so the template could be combined into a
single line if desired.

=item *

% I<perl_code>

Lines which begin with the % character may contain arbitrary Perl code.

This is equivalent to a single-line %perl block, but may be more
readable in some contexts. For example, the following template text
will return one of two different messages each time it's interpreted:

    % if ( int rand 2 ) {
      Hello World!
    % } else {
      Goodbye Cruel World!
    % }

This also allows you to quickly comment out sections of a template by prefacing each line with C<% #>.

=back

=head2 Invocation

To evaluate a Mason-like template, pass it to execute():

  $result = Text::MicroMason::execute( $mason_text );

Alternately, you can call compile() to generate a subroutine for your template, and then run the subroutine:

  $result = Text::MicroMason::compile( $mason_text )->();

If you will be interpreting the same template repeatedly, you can save the compiled version for faster execution:

  my $tmpl_func = Text::MicroMason::compile( $mason_text );
  ...
  $result = $tmpl_func->();

(The $tmpl_func->() syntax is unavailable in older Perl versions; use the original &$tmpl_func() syntax instead.)

=head2 Argument Passing

You can also pass a list of key-value pairs as arguments to execute, or to the compiled subroutine:

  $result = Text::MicroMason::execute( $mason_text, %args );

  $result = Text::MicroMason::compile( $mason_text )->( %args );

Within the scope of your template, any arguments that were provided will be accessible in C<%ARGS>, as well as in @_.

For example, the below call will return '<b>Foo</b>':

  Text::MicroMason::execute('<b><% $ARGS{label} %></b>', label=>'Foo');

=head2 Returning Text from Perl Blocks

To append to the result from within Perl code, call $_out->(I<text>). 
(The $_out->() syntax is unavailable in older Perl versions; use the
original &$_out() syntax instead.)

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

=head2 Implementation Mechanism

When your template is compiled, all of the literal (non-Perl) pieces
are converted to C<$_out-E<gt>('text');> statements, and the
interpolated expressions are converted to C<$_out-E<gt>( expr );>
statements. Code from %perl blocks and % lines are included exactly
as-is. 

Your code is eval'd in the C<Text::MicroMason::Commands> package,
and C<use strict;> is on by default.

You can create sub-templates within your template text by defining
them as anonymous subroutines and then calling them repeatedly.
For example, the following template will run the draw_item sub-template
for each of three items:

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

=head2 Error Checking

Both compilation and run-time errors in your template are handled
as fatal exceptions. MicroMason will croak() if you attempt to
compile or execute a template which contains a incorrect fragment
of Perl syntax. Similarly, if the Perl code in your template causes
die() or croak() to be called, this will interupt your program
unless caught with eval{ }.

For convenience, you may also use the provided try_execute() and
try_compile() functions, which wrap an eval { } block around the call
to the basic execute() or compile() functions. In a scalar context
they return the result of the call, or undef if it failed; in a
list context they return the results of the call (undef if it
failed) followed by the error message (undef if it succeeded). For
example:

  ($result, $error) = Text::MicroMason::try_execute( $mason_text );
  if ( ! $error ) {
    print $result;
  } else {
    print "Unable to execute template: $error";
  }

=head2 Safe Compartments

If you wish to restrict the operations that a template can perform, use the safe_compile() and safe_execute() functions, or their try_*() wrappers.

By default, these calls prevent the code in a template from performing any system activity or accessing any of your other Perl code. Violations may result in either compile-time or run-time errors, so make sure you are using the try_* wrappers or your own eval block.

  my ($result, $error) = try_safe_execute( $mason_text );

To enable some operations or share variables or functions with the template code, create a Safe compartment and configure it, then pass it in as the first argument to safe_compile() or safe_execute():

  my $safe = Safe->new();
  $safe->permit('time');
  $safe->share($foo);
  my ($result, $error) = try_safe_execute( $safe, $mason_text );

=head2 Unsupported Features

The following sets of HTML::Mason features are B<not> supported:

=over 4

=item -

No %attr, %shared, %method, %def, %init, or %args blocks.

=item -

No |h or |u options to escape the result of interpolated expressions.

=item -

No $m Mason interpreter context.

=item -

No $r request object

=item -

No E<lt>& I<file> &E<gt> includes.

=item -

No shared files like autohandler and dhandler.

=back


=head1 DIAGNOSTICS

The following diagnostic messages are produced for the indicated error conditions (where %s indicates variable message text):

=over 4

=item *

MicroMason parsing halted at %s

Indicates that the parser was unable to finish tokenising the source text. 

=item *

MicroMason compilation failed: %s

The template was parsed succesfully, but the Perl subroutine declaration it was converted to failed to compile. This is generally a result of a syntax error in one of the Perl expressions used within the template. 

=item * 

Error in template subroutine: %s

Additional diagnostic for compilation errors, showing the text of the subroutine which failed to compile.

=item * 

MicroMason execution failed: %s

After parsing and compiling the template succesfully, the subroutine was run and caused a fatal exception, generally because that some Perl code used within the template caused die() to be called (or an equivalent function like croak or confess).

=back


=head1 SEE ALSO

See L<HTML::Mason> for a much more full-featured version of the
capabilities provided by this module.

If you've already got HTML::Mason installed, configured, and loaded
into your process, you're probably better off using it. The
C<$interp-E<gt>make_component()> method allows you to parse a text string
without saving it to disk first.

=head2 Related Modules

You may well be thinking "yet another dynamic templating module?
Sheesh!" And you'd have a good point. There certainly are a variety
of templating toolkits on CPAN already; even restricting ourselves
to those which use Perl syntax for both interpolated expressions
and flow control (as opposed to "little languages") leaves a fairly
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
calls, and containing just 70-ish lines of Perl.


=head1 INSTALLATION

This module should work with any recent version of Perl 5; there are no
prerequisite modules beyond the standard distribution.

Retrieve the current distribution from here:

  http://work.evolution.com/dist/

Download and unpack the distribution, and execute the standard "perl Makefile.PL", "make test", "make install" sequence. 


=head1 VERSION

This is version 1.0.3 of Text::MicroMason.

This module should work with any version of Perl 5, without platform
dependencies or additional modules beyond the core distribution.

=head2 Module Naming Issues

Although originally derived from HTML::Mason, I have moved this
module from the HTML namespace to Text, as it doesn't specifically
address HTML or web technologies

This module should be categorized under group 11, Text Processing,
although there's also an argument for placing it 15 Web/HTML, where
HTML::Mason appears.

=head2 Distribution Summary

The proposed CPAN DSLI entry should read:

  Name            DSLI  Description
  --------------  ----  ---------------------------------------------
  Text::
  ::MicroMason    bdpr  Simple text templates with HTML::Mason syntax

=head2 Discussion and Support

Bug reports or general feedback would be welcomed by the author at simonm@evolution.com.


=head1 CHANGES

2001-07-01 Simon: Documentation tweaks. Renamed from HTML to Text.

2001-04-10 Simon: Munged interface for clarity. Added Safe support. 
Adjusted docs to reflect feedback from mason-users.

2001-03-28 Simon: Parser tweakage; additional documentation.
Added Exporter support.
  
2001-03-26 Simon: Added try_interpret; documented error messages.
  
2001-03-23 Simon: Extended documentation; added makefile, test script. 
Renamed accumulator to $OUT to match Text::Template.

2001-03-22 Simon: Created.


=head1 TO DO

=over 4 

=item *

Submit updated distribution to c.l.p.modules and modules@perl.org for feedback, and upload to CPAN.

=item *

Test compatibility against older and odder versions of Perl.

=item ? 

Perhaps support E<lt>%initE<gt> ... E<lt>/%initE<gt>, by treating it as a %perl block at the begining of the string.

=item ? 

Perhaps support E<lt>%argsE<gt> $foo => default E<lt>/%argsE<gt>.

Perhaps warn if %args block exists but template called with odd number of arguments.

=back


=head1 AUTHORS

Developed by:

  M. Simon Cavalletto, simonm@evolution.com
  Evolution Online Systems, http://www.evolution.com

Inspired by Jonathan Swartz's HTML::Mason.


=head1 LICENSE

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl.

Copyright 2001 Evolution Online Systems.

=cut
