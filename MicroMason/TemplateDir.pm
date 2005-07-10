package Text::MicroMason::TemplateDir;

use strict;
use File::Spec;

######################################################################

use vars qw( %Defaults );

$Defaults{ template_root } = '';
$Defaults{ strict_root } = '';

######################################################################

sub prepare {
  my ( $self, $src_type, $src_data ) = @_;
  
  if ( $src_type ne 'file' ) {
    return $self->NEXT('prepare', $src_type, $src_data );
  }
  
  my $current = $self->{source_file};
  my $rootdir = $self->{template_root} || '.';
  
  my $base = File::Spec->file_name_is_absolute($src_data) || ! $current 
			      ? $rootdir 
			      : ( File::Spec->splitpath( $current ) )[1];
  
  my $path = File::Spec->catfile( $base, $src_data );
  
  if ( $self->{ strict_root } ) {
    $path = File::Spec->canonpath( $path );
    $path =~ /^\Q$self->{ strict_root }\E/ 
      or $self->croak_msg("Not in required base path '$self->{ strict_root }'");
  }
  
  return $self->NEXT('prepare', 'file' => $path, source_file => $path );
}

######################################################################

1;

######################################################################

=head1 NAME

Text::MicroMason::TemplateDir - Use Base Directory and Relative Paths


=head1 SYNOPSIS

Instead of using this class directly, pass its name to be mixed in:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new( -TemplateDir );

Templates stored in files can be run directly or included in others:

    print $mason->execute( file=>"./greeting.msn", 'name'=>'Charles');


=head1 DESCRIPTION

This module changes the resolution of files passed to compile() and execute() to be relative to a base directory path or to the currently executing template.

=head2 Supported Attributes

=over 4

=item template_root

Base directory from which to find templates.

=back

=head2 Private Methods

=over 4

=item prepare

Intercepts uses of file templates and applies the base-path adjustment.

=back


=head1 SEE ALSO

For an overview of this templating framework, see L<Text::MicroMason>.

This is a mixin class intended for use with L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::Docs::ReadMe>.

=cut

