package Text::MicroMason::TemplateDir;

use strict;
use File::Spec;

######################################################################

use vars qw( %Defaults );

$Defaults{ template_root } = '';
$Defaults{ strict_root } = '';

######################################################################

use vars qw( @MIXIN );

BEGIN { push @MIXIN, "#line ".__LINE__.' "'.__FILE__.'"', "", <<'/' }
sub resolve {
  my ( $self, $src_type, $src_data ) = @_;

  if ( $src_type ne 'file' ) {
    return $self->SUPER::resolve( $src_type, $src_data );
  }
  
  my $current = $self->{source_file};
  my $rootdir = $self->{template_root} || '.';
  
  my $base = File::Spec->file_name_is_absolute($src_data) || ! $current 
			      ? $rootdir 
			      : ( File::Spec->splitpath( $current ) )[1];
  
  my $path = File::Spec->catfile( $base, $src_data );
  
  $self->{debug} and $self->debug_msg( "MicroMason resolved '$src_data': $path" );

  if ( $self->{ strict_root } ) {
    $path = File::Spec->canonpath( $path );
    $path =~ /^\Q$self->{ strict_root }\E/ 
      or $self->croak_msg("Not in required base path '$self->{ strict_root }'");
  }
  
  return ( 'file' => $path, source_file => $path );
}
/

######################################################################

1;

######################################################################

=head1 NAME

Text::MicroMason::TemplateDir - Interpret file path relative to base dir


=head1 SYNOPSIS

Instead of using this class directly, pass its name to be mixed in:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new( -TemplateDir );

Templates stored in files can be run directly or included in others:

    print $mason->execute( file=>"./greeting.msn", 'name'=>'Charles');


=head1 TO DO

This module is not finished.


=head1 DESCRIPTION

This module changes the resolution of files passed to compile() and execute() to be relative to a base directory path or to the currently executing template.

=head2 Supported Attributes

=over 4

=item template_root

Base directory from which to find templates.

=back

=head2 Private Methods

=over 4

=item resolve

Intercepts uses of file templates and applies the base-path adjustment.

=back


=head1 SEE ALSO

For the core functionality of this package see L<Text::MicroMason> and L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::ReadMe>.

=cut

