package Text::MicroMason::CompileCache;

use strict;
use Carp;

######################################################################

use vars qw( %Defaults );

require Text::MicroMason::Cache::Simple;
require Text::MicroMason::Cache::File;

$Defaults{ text_compile_cache } = Text::MicroMason::Cache::Simple->new();
$Defaults{ file_compile_cache } = Text::MicroMason::Cache::File->new();

######################################################################

use vars qw( @MIXIN );

# $code_ref = compile( file => $filename );
BEGIN { push @MIXIN, "#line ".__LINE__.' "'.__FILE__.'"', "", <<'/' }
sub compile {
  my ( $self, $src_type, $src_data, %options ) = @_;
  
  my $cache = $options{ $src_type . '_code_cache' }
    or return $self->SUPER::compile($src_type, $src_data, %options);
  
  $cache->get( $src_data ) or do {
    my $sub = $self->SUPER::compile($src_type, $src_data, %options);
    $cache->set( $src_data, $sub );
    $sub;
  }
}
/

######################################################################

1;

__END__

=head1 NAME

Text::MicroMason::CompileCache - Use cache for parse/compile step


=head1 SYNOPSIS

Instead of using this class directly, pass its name to be mixed in:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new( -CompileCache );

Use the execute method to parse and evalute a template:

    print $mason->execute( text=>$template, 'name'=>'Dave' );

The template does not have to be parsed the second time because it's cached:

    print $mason->execute( text=>$template, 'name'=>'Bob' );

Templates stored in files are also cached, until the file changes:

    print $mason->execute( file=>"./greeting.msn", 'name'=>'Charles');


=head1 DESCRIPTION

This module uses a simple cache interface that is widely supported. You can use the simple cache classes provided in the Text::MicroMason::Cache:: namespace, or select other caching modules on CPAN that support the interface described in L<Cache::Cache>.


=head2 Public Methods

=over 4

=item compile()

Implemented using the @MIXINS feature provided by Text::MicroMason's class() method.

=back


=head1 SEE ALSO

For the core functionality of this package see L<Text::MicroMason> and L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut
