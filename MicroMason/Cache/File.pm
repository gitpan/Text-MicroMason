package Text::MicroMason::Cache::File;
@ISA = 'Text::MicroMason::Cache::Simple';

use strict;

######################################################################

sub get { 
  my ( $self, $file ) = @_;
  my $entry = $self->SUPER::get( $file ) 
      or return;
  unless ( ref( $entry) eq 'ARRAY' and $#$entry == 2 ) {
    Carp::croak("MicroMason: cache '$self' data corrupted; " . 
			    "value for '$file' should not be '$entry'");
  }
  
  my $time = time();
  if ( $entry->[0] < $time ) { # don't check more than once per second
    my $mtime = -M $file;
    if ( $entry->[1] < $mtime ) {
      @$entry = ( 0, 0, undef ); # file has changed; cache invalid
      return;
    } else {
      $entry->[0] = $time;
    }
  }
  return $entry->[2];
}

sub set { 
  my ( $self, $file, $sub ) = @_;
  $self->SUPER::set( $file => [ time(), -M $file, $sub ] )
}

######################################################################

1;

__END__

######################################################################

=head1 NAME

Text::MicroMason::Cache::File - Cache with file modification checks


=head1 DESCRIPTION

This simple cache class expects the keys provided to it to be file pathnames, and considers the cached value to have expired if the corresponding file is changed.

It does not perform the following functions: cache size limiting, or deep copying of complex values.

=head2 Public Methods

=over 4

=item new()

  $cache = Text::MicroMason::Cache::File->new();

=item get()

  $value = $cache->get( $filename );

Retrieves the value associated with this key, or undef if there is no value.

=item set()

  $cache->set( $filename, $value );

Stores the provided value in association with this key. 

=item clear()

  $cache->clear();

Removes all data from the cache.

=back


=head1 SEE ALSO

For uses of this cache class, see L<Text::MicroMason::CompileCache>.

Additional cache classes are available in the Text::MicroMason::Cache:: namespace, or select other caching modules on CPAN that support the interface described in L<Cache::Cache>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut
