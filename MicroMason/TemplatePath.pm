package Text::MicroMason::TemplatePath;

use strict;
use File::Spec;
use base 'Text::MicroMason::TemplateDir';

######################################################################

sub resolve_path {
    my ($self, $src_data) = @_;

    # Absolute file path: use that filename.
    return $src_data if File::Spec->file_name_is_absolute($src_data);

    # Relative filename: use a path search

    # Our path for this file will be the current directory, if there is
    # one, followed by the configured path.
    my @path = @{$self->{template_path}};
    my $current = $self->{source_file};
    unshift @path, $current if $current;

    # Check out path for an existing template file.
    foreach my $dir (@path) {
        my $fn = File::Spec->canonpath(File::Spec->catfile($dir, $src_data));
        next unless -e $fn;
        return $fn;
    }

    # Fall through to failure: file not found!
    return;
}

# $contents = $mason->read_file( $filename );
sub read_file {
    my ( $self, $file ) = @_;

    if ( my $root = $self->{strict_root} ) {
        my $path = File::Spec->canonpath( $file );
        # warn "Checking for '$root' in '$path'\n";
        ( $path =~ /\A\Q$root\E(\/|(?<=\/))(?!\.\.)/ )
            or $self->croak_msg("Not in required base path '$root'");
    }

    return $self->NEXT('read_file', $file );
}

sub cache_key {
    my $self = shift;
    my ($src_type, $src_data, %options) = @_;

    return $self->NEXT('cache_key', @_) unless $src_type eq 'file';
    return $self->resolve_path($src_data);
}

######################################################################

1;

######################################################################

=head1 NAME

Text::MicroMason::TemplatePath - Template Path Searching


=head1 SYNOPSIS

Instead of using this class directly, pass its name to be mixed in:

    use Text::MicroMason;
    my $mason = Text::MicroMason->new( -TemplatePath, template_path => [ '/foo', '/bar' ] );

Use the standard compile and execute methods to parse and evalute templates:

  print $mason->compile( file=>$filepath )->( 'name'=>'Dave' );
  print $mason->execute( file=>$filepath, 'name'=>'Dave' );

Templates stored in files are searched for in the specified template_path:

    print $mason->execute( file=>"includes/greeting.msn", 'name'=>'Charles');

When including other files into a template you can use relative paths:

    <& ../includes/greeting.msn, name => 'Alice' &>

When a file is included in the template, the including template's
current directory is added to the beginning of the template search path.


=head1 DESCRIPTION

This module works similarly to the related TemplateDir mix-in. However,
instead of specifying a single root which must contain all templates,
TemplatePath allows you to specify an arrayref of directories which will
be searched in order whenever a template filename must be resolved.

Using a TemplatePath object, absolute filenames are used as-is. If a
relative template filenames or file paths is used, every directory in
the specified template_path is checked for the existence of the
template, and the first existing template file is used.

If a template includes another template using <& ... &>, then the
including template's location is added to the beginning of the template
search path list, for the resolution of the included template's
filename. This allows the included template to be specified relative to
the including template, but also lets the template search fall back to
the configured template search path if necessary.


=head2 Supported Attributes

=over 4

=item template_path

An array ref containing a list of directories in which to search for
relative template filenames.

=item strict_root

Optional directory beyond which not to read files. Unlike TemplateDir,
this must be a specific file path. Causes read_file to croak if any
filename outside of the root is provided. You should make sure that all
paths specified in template_path are inside the specified strict_root.
(Note that this is not a chroot jail and only affects attempts to load a
file as a template; for greater security see the chroot() builtin and
L<Text::MicroMason::Safe>.)

=back

=head2 Private Methods

=over 4

=item read_file

Intercepts file access to check for strict_root.

=back


=head1 SEE ALSO

For an overview of this templating framework, see L<Text::MicroMason>.

This is a mixin class intended for use with L<Text::MicroMason::Base>.

For distribution, installation, support, copyright and license
information, see L<Text::MicroMason::Docs::ReadMe>.

=cut

