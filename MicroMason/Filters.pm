package Text::MicroMason::Filters;

use strict;
use Carp;

use Safe;

use vars qw( @MIXIN );

######################################################################

use vars qw( %Defaults %Filters );

# Output filtering
$Defaults{default_filters} = '';
$Defaults{filters} = \%Filters;
$Filters{h} = \&HTML::Entities::encode if eval { require HTML::Entities};
$Filters{u} = \&URI::Escape::uri_escape if eval { require URI::Escape };

BEGIN { push @MIXIN, "#line ".__LINE__.' "'.__FILE__.'"', "", <<'/' }
sub defaults {
  (shift)->SUPER::defaults(), %Text::MicroMason::Filters::Defaults
}
/

######################################################################

# $perl_code = $mason->assemble( @tokens );
BEGIN { push @MIXIN, "#line ".__LINE__.' "'.__FILE__.'"', "", <<'/' }
sub assemble {
  my $self = shift;
  my @tokens = @_;
  # warn "Filter assemble";
  foreach my $position ( 0 .. int( $#tokens / 2 ) ) {
    if ( $tokens[$position * 2] eq 'output' ) {
      my $token = $tokens[$position * 2 + 1];
      my $filt_flags = ($token =~ s/\|\s*(\w+(?:[\s\,]+\w+)*)\s*\z//) ? $1 : '';
      my @filters = $self->parse_filters($self->{default_filters}, $filt_flags);
      if ( @filters ) {
	$token = '$m->filter( ' . join(', ', map "'$_'", @filters ) . ', ' . 
				  'join "", do { ' . $token . '} )';
      }
      $tokens[$position * 2 + 1] = $token;
    }
  }
  
  $self->SUPER::assemble( @tokens );
}
/

# @flags = $mason->parse_filters( @filter_strings );
sub parse_filters {
  my $self = shift;
  
  my $no_ns;
  reverse grep { not $no_ns ||= /^n$/ } reverse
    map { /^[hun]{2,5}$/ ? split('') : split(/[\s\,]+/) } 
	@_;
}

######################################################################

# %functions = $mason->filter_functions();
# $function  = $mason->filter_functions( $flag );
# @functions = $mason->filter_functions( \@flags );
# $mason->filter_functions( $flag => $function, ... );
sub filter_functions {
  my $self = shift;
  my $filters = ( ref $self ) ? $self->{filters} : \%Filters;
  if ( scalar @_ == 0 ) {
    %$filters
  } elsif ( scalar @_ == 1 ) {
    my $key = shift;
    if ( ! ref $key ) {
      $filters->{ $key } || 
	  $self->croak_msg("No definition for a filter named '$key'" )
    } else {
      @{ $filters }{ @$key }
    }
  } else {
    %$filters = ( %$filters, @_ );
  }
}

# $result = $mason->filter( @filters, $content );
sub filter {
  my $self = shift;
  my $content = pop;
  
  foreach my $filter ( @_ ) {
    my $function = ( ref $filter eq 'CODE' ) ? $filter : 
	$self->{filters}{ $filter } || 
	  $self->croak_msg("No definition for a filter named '$filter'" );
    $content = &$function($content)
  }
  $content
}

######################################################################

1;

__END__

######################################################################

=head1 NAME

Text::MicroMason::Filters - Filter output with "|h" and "|u"


=head1 SYNOPSIS

Instead of using this class directly, pass its name to be mixed in:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new( -Filters );

Enables filtering of template expressions using HTML::Mason's conventions:

    <%args> $name </%args>
    Welcome, <% $name |h %>! 
    <a href="more.masn?name=<% $name |u %>">Click for More</a>

You can set a default filter and override it with the "n" flag:

    my $mason = Text::MicroMason->new( -Filters, default_filters => 'h' );

    <%args> $name </%args>
    Welcome, <% $name %>! 
    <a href="more.masn?name=<% $name |nu %>">Click for More</a>

You can define additional filters and stack them:

    my $mason = Text::MicroMason->new( -Filters );
    $mason->filter_functions( myfilter => \&function );
    $mason->filter_functions( uc => sub { return uc( shift ) } );

    <%args> $name </%args>
    Welcome, <% $name |uc,myfilter %>! 


=head1 DESCRIPTION

This module enables the filtering of expressions before they are output, using HTML::Mason's "|hun" syntax.

If you have HTML::Entities and URI::Escape available they are loaded to provide the default "h" and "u" filters. If those modules can not be loaded, no error message is produced but any subsequent use of them will fail with a message stating "No definition for a filter named 'h'".

=head2 Public Methods

=over 4 

=item filter_functions

Gets and sets values from the hash mapping filter flags to functions.

If called with no arguments, returns a hash of all available filter flags and functions:

  %functions = $mason->filter_functions();

If called with a filter flag returns the associated function, or if provided with a reference to an array of flag names returns a list of the functions:

  $function  = $mason->filter_functions( $flag );
  @functions = $mason->filter_functions( \@flags );

If called with one or more pairs of filter flags and associated functions, adds them to the hash. (Any filter that might have existed with the same flag name is overwritten.)

  $mason->filter_functions( $flag => $function, ... );

=item parse_filters

Parses one or more strings containing any number of filter flags and returns a list of flags to be used. 

  @flags = $mason->parse_filters( @filter_strings );

Flags should be separated by commas, except that the commas may be omitted when using only the built-in "h", "u" and "n" flags. Flags are applied from left to right. Any use of the "n" flag wipes out all flags defined to the left of it. 

=item filter

Applies one or more filters to the provided content string.

  $result = $mason->filter( @filters, $content );

=back

=head2 Supported Attributes

=over 4

=item default_filters

Optional comma-separated string of filter flags to be applied to all output expressions unless overridden by the "n" flag.

=back

=head2 Private Methods

=over 4

=item assemble()

This method goes through the lexed template tokens looking for uses of filter flags, which it then rewrites as appropriate method calls before passing the tokens on to the superclass.

=back


=head1 SEE ALSO

For the core functionality of this package see L<Text::MicroMason> and L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut

