package Text::MicroMason::CompileCache;

use strict;
use Carp;

require Text::MicroMason::Cache::Simple;
require Text::MicroMason::Cache::File;

######################################################################

use vars qw( %Defaults );

$Defaults{ compile_cache_text } = Text::MicroMason::Cache::Simple->new();
$Defaults{ compile_cache_file } = Text::MicroMason::Cache::File->new();

sub defaults {
  (shift)->NEXT('defaults'), %Defaults
}

######################################################################

# $code_ref = compile( file => $filename );
sub compile {
  my ( $self, $src_type, $src_data, %options ) = @_;
  
  my $cache_type = 'compile_cache_' . $src_type;
  my $cache = $self->{ $cache_type }
    or return $self->NEXT('compile', $src_type, $src_data, %options);
  
  $cache->get( $src_data ) or $cache->set( $src_data, 
	      $self->NEXT('compile', $src_type, $src_data, %options) );
}

######################################################################

1;

__END__

=head1 NAME

Text::MicroMason::CompileCache - Use a Cache for Template Compilation


=head1 SYNOPSIS

Instead of using this class directly, pass its name to be mixed in:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new( -CompileCache );

Use the standard compile and execute methods to parse and evalute templates:

    print $mason->execute( text=>$template, 'name'=>'Dave' );

The template does not have to be parsed the second time because it's cached:

    print $mason->execute( text=>$template, 'name'=>'Bob' );

Templates stored in files are also cached, until the file changes:

    print $mason->execute( file=>"./greeting.msn", 'name'=>'Charles');


=head1 DESCRIPTION


=head2 Public Methods

=over 4

=item compile()

Caching wrapper around normal compile() behavior.

=back

=head2 Supported Attributes

=over 4

=item compile_cache_text

Defaults to an instance of Text::MicroMason::Cache::Simple. You may pass in your own cache object.

=item compile_cache_file

Defaults to an instance of Text::MicroMason::Cache::File. You may pass in your own cache object.

=back

This module uses a simple cache interface that is widely supported: the
only methods required are C<get($key)> and C<set($key, $value)>. You can
use the simple cache classes provided in the Text::MicroMason::Cache::
namespace, or select other caching modules on CPAN that support the
interface described in L<Cache::Cache>.


=head1 SEE ALSO

For an overview of this templating framework, see L<Text::MicroMason>.

This is a mixin class intended for use with L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::Docs::ReadMe>.

=cut
