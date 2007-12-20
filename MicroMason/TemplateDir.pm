package Text::MicroMason::TemplateDir;

use strict;
use File::Spec;

######################################################################

sub prepare {
  my ( $self, $src_type, $src_data ) = @_;

  return $self->NEXT('prepare', $src_type, $src_data ) 
    unless $src_type eq 'file';

  my $path = $self->resolve_path($src_data);
  return $self->NEXT('prepare', 'file' => $path, source_file => $path );
}

sub resolve_path {
  my ($self, $src_data) = @_;

  my $current = $self->{source_file};
  my $rootdir = $self->template_root();

  my $base = File::Spec->file_name_is_absolute($src_data) || ! $current 
			      ? $rootdir 
			      : ( File::Spec->splitpath( $current ) )[1];

  return File::Spec->catfile( $base, $src_data );
}

sub template_root {
    my $self = shift;
    return $self->{template_root} || '.' unless @_;
    
    $self->{template_root} = shift;
}

sub cache_key {
    my $self = shift;
    my ($src_type, $src_data, %options) = @_;
    return $self->NEXT('cache_key', @_) unless $src_type eq 'file';
    return  $self->resolve_path($src_data);
}


# $contents = $mason->read_file( $filename );
sub read_file {
  my ( $self, $file ) = @_;
  
  if ( my $root = $self->{strict_root} ) {

    $root = $self->template_root if $root eq '1';
    my $path = File::Spec->canonpath( $file );
    # warn "Checking for '$root' in '$path'\n";
    ( $path =~ /\A\Q$root\E(\/|(?<=\/))(?!\.\.)/ )
      or $self->croak_msg("Not in required base path '$root'");
  }
  
  return $self->NEXT('read_file', $file );
}

######################################################################

1;

######################################################################

=head1 NAME

Text::MicroMason::TemplateDir - Use Base Directory and Relative Paths


=head1 SYNOPSIS

Instead of using this class directly, pass its name to be mixed in:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new( -TemplateDir, template_root=>'/foo' );

Use the standard compile and execute methods to parse and evalute templates:

  print $mason->compile( file=>$filepath )->( 'name'=>'Dave' );
  print $mason->execute( file=>$filepath, 'name'=>'Dave' );

Templates stored in files are looked up relative to the template root:

    print $mason->execute( file=>"includes/greeting.msn", 'name'=>'Charles');

When including other files into a template you can use relative paths:

    <& ../includes/greeting.msn, name => 'Alice' &>


=head1 DESCRIPTION

This module changes the resolution of files passed to compile() and execute() to be relative to a base directory path or to the currently executing template.


=head2 Supported Attributes

=over 4

=item template_root

Base directory from which to find templates.

=item strict_root

Optional directory beyond which not to read files. If set to 1, uses template_root, Causes read_file to croak if any filename outside of the root is provided. (Note that this is not a chroot jail and only affects attempts to load a file as a template; for greater security see the chroot() builtin and L<Text::MicroMason::Safe>.)

=back

=head2 Private Methods

=over 4

=item prepare

Intercepts uses of file templates and applies the base-path adjustment.

=item read_file 

Intercepts file access to check for strict_root.

=back


=head1 SEE ALSO

For an overview of this templating framework, see L<Text::MicroMason>.

This is a mixin class intended for use with L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license 
information, see L<Text::MicroMason::Docs::ReadMe>.

=cut

