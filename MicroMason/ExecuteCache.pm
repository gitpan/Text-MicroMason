package Text::MicroMason::ExecuteCache;

use strict;
use Carp;

######################################################################

use vars qw( %Defaults );

require Text::MicroMason::Cache::Storable;

$Defaults{ execute_cache } = Text::MicroMason::Cache::Storable->new();

######################################################################

use vars qw( @MIXIN );

# $code_ref = execute( file => $filename );
BEGIN { push @MIXIN, "#line ".__LINE__.' "'.__FILE__.'"', "", <<'/' }
sub execute {
  my $self = shift;
  
  my $cache = $options{ 'execute_cache' }
    or return $self->SUPER::execute(@_);
  
  $cache->get( \@_ ) or do {
    my $result = $self->SUPER::execute(@_);
    $cache->set( $src_data, $result );
    $result;
  }
}
/

######################################################################

1;

__END__

=head1 NAME

Text::MicroMason::ExecuteCache - Use cache for execute step


=head1 SYNOPSIS

Instead of using this class directly, pass its name to be mixed in:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new( -ExecuteCache );

Use the execute method to parse and evalute a template:

    print $mason->execute( text=>$template, 'name'=>'Dave' );

The template does not have to be interpreted the second time because the results are cached:

    print $mason->execute( text=>$template, 'name'=>'Dave' ); # fast

When run with different arguments, the template is re-interpreted and the results stored:

    print $mason->execute( text=>$template, 'name'=>'Bob' ); # first time

    print $mason->execute( text=>$template, 'name'=>'Bob' ); # fast


=head1 TO DO

This module is not finished.


=head1 DESCRIPTION

This module uses a simple cache interface that is widely supported. You can use the simple cache classes provided in the Text::MicroMason::Cache:: namespace, or select other caching modules on CPAN that support the interface described in L<Cache::Cache>.


=head2 Public Methods

=over 4

=item execute()

Implemented using the @MIXINS feature provided by Text::MicroMason's class() method.

=back


=head1 SEE ALSO

For the core functionality of this package see L<Text::MicroMason> and L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut
