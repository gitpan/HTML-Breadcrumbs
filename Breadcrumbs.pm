# tag: HTML Breadcrumb class

package HTML::Breadcrumbs;

use 5.000;
use File::Basename;
use Carp;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = '0.03';
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(breadcrumbs);

# my @ARG = qw(path roots indexes omit map labels sep format format_last extra);
my @ARG = qw(path roots indexes omit labels sep format format_last extra);

#
# Initialise
#
sub init
{
    my $self = shift;
    # Argument defaults
    my %arg = (
        path => $ENV{SCRIPT_NAME},
        roots => [ '/' ],
        indexes => [ 'index.html' ],
        sep => '&nbsp;&gt;&nbsp;',
        format => '<a href="%s">%s</a>',
        format_last => '%s',
        @_,
    );

    # Check for invalid args
    my %ARG = map { $_ => 1 } @ARG;
    my @bad = grep { ! exists $ARG{$_} } keys %arg;
    croak "[Breadcrumbs::init] invalid argument(s): " . join(',',@bad) if @bad;
    croak "[Breadcrumbs::render] 'path' argument must be absolute" 
        if $self->{path} && substr($self->{path},0,1) ne '/';

    # Add arguments to $self
    @$self{ @ARG } = @arg{ @ARG };

    return $self;
}

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self->init(@_);
}

#
# Split the path into elements (stored in $self->{elt} arrayref)
#
sub split
{
    my $self = shift;

    # Identify the root
    $self->{elt} = [];
    $self->{roots} = [ $self->{roots} ] if $self->{roots} && ! ref $self->{roots};
    my $root = '/';
    for my $r (sort { length($b) <=> length($a) } @{$self->{roots}}) {
        if ($self->{path} =~ m/^$r\b/) {
            $root = $r;
            $root .= '/' if substr($root,-1) ne '/';
            last;
        }
    }
    push @{$self->{elt}}, $root;

    # Add elements
    $self->{omit} = [ $self->{omit} ] 
        if $self->{omit} && ! ref $self->{omit};
    # Create a hash from omit elements
    my %omit = ();
    if ($self->{omit} && ref $self->{omit} eq 'ARRAY') {
        for (@{$self->{omit}}) {
            # Omit strings should begin and end with '/'
            $_ = '/' . $_ unless substr($_,0,1) eq '/';
            $_ .= '/' unless substr($_,-1) eq '/';
            $omit{$_} = 1;
        }
    }
    my $current = $root;
    while ($self->{path} =~ m|^$current.*?([^/]+/?)|) {
        $current .= $1;
        push @{$self->{elt}}, $current unless $omit{$current};
    }

    # Check the final element for indexes
    $self->{indexes} = [ $self->{indexes} ] 
        if $self->{indexes} && ! ref $self->{indexes};
    if (ref $self->{indexes} eq 'ARRAY') {
        # Convert indexes to hash
        my %indexes = map { $_ => 1 } @{$self->{indexes}};
        # Check final element
        my $final = basename($self->{elt}->[ $#{$self->{elt}} ]);
        if ($indexes{$final}) {
            pop @{$self->{elt}};
        }
    }
}

#
# Generate a default label for $elt
#
sub label_default
{
    my $self = shift;
    my ($elt, $last, $extra) = @_;
    my $label = '';

    if ($elt eq '/' || $elt eq '') {
        $label = 'Home';
    }
    else {
        $elt = substr($elt,0,-1) if substr($elt,-1) eq '/';
        $label = basename($elt);
        $label =~ s/\.[^.]*$// if $last;
        $label = ucfirst($label) if lc($label) eq $label && $label =~ m/^\w+$/;
    }

    return $label;
}

#
# Return a label for the given element
#
sub label
{
    my $self = shift;
    my ($elt, $last, $extra) = @_;
    my $label = '';

    # Check $self->{labels}
    if (ref $self->{labels} eq 'CODE') {
        $elt = substr($elt,0,-1) if substr($elt,-1) eq '/' && $elt ne '/';
        $label = $self->{labels}->($elt, basename($elt), $last, $extra);
    }
    elsif (ref $self->{labels} eq 'HASH') {
        $elt = substr($elt,0,-1) if substr($elt,-1) eq '/' && $elt ne '/';
        $label ||= $self->{labels}->{$elt};
        $label ||= $self->{labels}->{$elt . '/'} unless $elt eq '/' || $last;
        $label ||= $self->{labels}->{basename($elt)};
    }

    # Else use defaults
    $label ||= $self->label_default($elt, $last, $extra);

    return $label;
}

#
# May use full URI::Escape version in future
#
sub uri_escape
{
    local $_ = shift;
    s/ /%20/g;
    return $_;
}

# 
# HTML-format the breadcrumbs
#
sub format 
{
    my $self = shift;

    my $out;
    for (my $i = 0; $i <= $#{$self->{elt}}; $i++) {

        # Format breadcrumb links
        if ($i != $#{$self->{elt}}) {
            # Generate label
            my $label = $self->label($self->{elt}->[$i], undef, $self->{extra});

            # $self->{format} coderef
            if (ref $self->{format} eq 'CODE') {
                $out .= $self->{format}->(uri_escape($self->{elt}->[$i]), 
                    $label, $self->{extra});
            }
            # $self->{format} sprintf pattern
            elsif ($self->{format} && ! ref $self->{format}) {
                $out .= sprintf $self->{format}, uri_escape($self->{elt}->[$i]), 
                    $label;
            }
            # Else croak
            else {
                croak "[Breadcrumbs::format] invalid format $self->{format}";
            }

            # Separator
            $out .= $self->{sep};
        }

        # Format final element breadcrumb label
        else {
            # Generate label
            my $label = $self->label($self->{elt}->[$i], 'last', $self->{extra});

            # $self->{format_last} coderef
            if (ref $self->{format_last} eq 'CODE') {
                $out .= $self->{format_last}->($label, $self->{extra});
            }
            # $self->{format_last} sprintf pattern
            elsif ($self->{format_last} && ! ref $self->{format_last}) {
                $out .= sprintf $self->{format_last}, $label;
            }
            # Else croak
            else {
                croak "[Breadcrumbs::format] invalid format_last $self->{format_last}";
            }
        }
    }

    return $out;
}

#
# The real work - process and render the given path
#
sub render
{
    my $self = shift;
    my %arg = @_;

    # Check for invalid args
    my %ARG = map { $_ => 1 } @ARG;
    my @bad = grep { ! exists $ARG{$_} } keys %arg;
    croak "[Breadcrumbs::render] invalid argument(s): " . join(',',@bad) if @bad;

    # Add args to $self
    for (@ARG) {
        $self->{$_} = $arg{$_} if defined $arg{$_};
    }

    # Croak if no path
    croak "[Breadcrumbs::render] no valid 'path' found" if ! $self->{path};
    croak "[Breadcrumbs::render] 'path' argument must be absolute" 
        if substr($self->{path},0,1) ne '/';

    # Split the path into elements
    $self->split();

    # Format
    return $self->format();
}

# 
# Alias for render
#
sub to_string
{
    my $self = shift;
    $self->render(@_);
}

#
# Procedural interface
#
sub breadcrumbs
{
    my $bc = HTML::Breadcrumbs->new(@_);
    croak "[breadcrumbs] object creation failed!" if ! ref $bc;
    return $bc->render();
}

1;

__END__

=head1 NAME

HTML::Breadcrumbs - module to produce HTML 'breadcrumb trails'.


=head1 SYNOPSIS

    # Procedural interace
    use HTML::Breadcrumbs qw(breadcrumbs);
    print breadcrumbs(path => '/foo/bar/bog.html');
    # prints: Home > Foo > Bar > Bog (the first three as links)

    # More complex version - some explicit element labels + extras
    print breadcrumbs(
        path => '/foo/bar/biff/bog.html', 
        labels => {
            'bog.html' => 'Various Magical Stuff',
            '/foo' => 'Foo Foo',
            bar => 'Bar Bar',
            '/' => 'Start', 
        },
        sep => ' :: ',
        format => '<a target="_blank" href="%s">%s</a>',
    );
    # prints: Start :: Foo Foo :: Bar Bar :: Biff :: Various Magical Stuff

    # Object interface
    use HTML::Breadcrumbs;

    # Create
    $bc = HTML::Breadcrumbs->new(
        path => $path, 
        labels => {
            'download.html' => 'Download',
            foo => 'Bar',
            'x.html' => 'The X Files',
        },
    );

    # Render
    print $bc->render(sep => '&nbsp;::&nbsp;');


=head1 DESCRIPTION

HTML::Breadcrumbs is a module used to create HTML 'breadcrumb trails'
i.e. an ordered set of html links locating the current page within
a hierarchy. 

HTML::Breadcrumbs splits the given path up into a list of elements, 
derives labels to use for each of these elements, and then renders this 
list as N-1 links using the derived label, with the final element
being just a label.

Both procedural and object-oriented interfaces are provided. The OO 
interface is useful if you want to separate object creation and
initialisation from rendering or display, or for subclassing.

Both interfaces allow you to munge the path in various ways (see the 
I<roots> and I<indexes> arguments); set labels either explicitly
via a hashref or via a callback subroutine (see I<labels>); and
control the formatting of elements via sprintf patterns or a callback
subroutine (see I<format> and I<format_last>).

=head2 PROCEDURAL INTERFACE

The procedural interface is the breadcrumbs() subroutine (not
exported by default), which uses a named parameter style. Example 
usage:

    # Procedural interace
    use HTML::Breadcrumbs qw(breadcrumbs);
    print breadcrumbs(
        path => $path, 
        labels => {
            'download.html' => 'Download',
            foo => 'Bar',
            'x.html' => 'The X Files',
        },
        sep => '&nbsp;::&nbsp;',
        format => '<a class="breadcrumbs" href="%s">%s</a>',
        format_last => '<span class="bclast">%s</span>,
    );

=head2 OBJECT INTERFACE

The object interface consists of two public methods: the traditional new() for
object creation, and render() to return the formatted breadcrumb trail as a
string (to_string() is an alias for render).  Arguments are passed in the same
named parameter style used in the procedural interface. All arguments can be
passed to either method (using new() is preferred, although using render() for
formatting arguments can be a useful convention). 

Example usage:

    # OO interface
    use HTML::Breadcrumbs;
    $bc = HTML::Breadcrumbs->new(path => $path);
    
    # Later
    print $bc->render(sep => '&nbsp;::&nbsp;');

    # OR
    $bc = HTML::Breadcrumbs->new(
        path => $path,
        labels => {
            'download.html' => 'Download',
            foo => 'Bar',
            'x.html' => 'The X Files',
        },
        sep => '&nbsp;::&nbsp;',
        format => '<a class="breadcrumbs" href="%s">%s</a>',
        format_last => '<span class="bclast">%s</span>,
    );
    print $bc->render();    # Same as bc->to_string()


=head2 ARGUMENTS

breadcrumbs() takes the following parameters:

PATH PROCESSING

=over 4

=item *

L<path|path> - the uri-relative path of the item this breadcrumb trail 
is for, as found, for example, in $ENV{SCRIPT_NAME}. This should 
probably be the I<real> uri-based path to the object, so that the 
elements derived from it produce valid links - if you want to munge 
the path and the elements from it see the L<roots>, L<omit>, and L<map> 
parameters. Default: $ENV{SCRIPT_NAME}.

=item *

L<roots|roots> - an arrayref of uri-relative paths used to identify
the root (the first element) of the breadcrumb trail as something other 
than '/'. For example, if the roots arrayref contains '/foo', a path of 
/foo/test.html will be split into two elements: /foo and /foo/test.html,
and rendered as "Foo > Test". The default behaviour would be to split 
/foo/test.html into three elements: /, /foo, and /foo/test.html, rendered
as "Home > Foo > Test". Default: [ '/' ].

=item *

L<indexes|indexes> - an arrayref of filenames (basenames) to treat 
as index pages. Index pages are omitted where they occur as the 
last element in the element list, essentially identifying the index 
page with its directory e.g. /foo/bar/index.html is treated as 
/foo/bar, rendered as "Home > Foo > Bar" with the first two links. 
Anything you would add to an apache DirectoryIndex directive should 
probably also be included here. Default: [ 'index.html' ].

=item *

L<omit|omit> - an arrayref of fully-qualified elements (paths) 
indicating individual elements to be omitted or skipped when 
producing breadcrumbs. For example, if the omit arrayref contains 
'/cgi-bin' then a path of '/cgi-bin/forms/help.html' would be 
rendered as "Home > Forms > Help" instead of the default 
"Home > cgi-bin > Forms > Help". Default: none.

=item *

L<map|map> - not yet implemented.

=back

LABELS

=over 4

=item *

L<labels|labels> - a hashref or a subroutine reference used to derive 
the labels of the breadcrumb trail elements. Default: none.

If a hashref, first the fully-qualified element name (e.g. /foo/bar or 
/foo/bar/, or /foo/bar/bog.html) and then the element basename 
(e.g. 'bar' or 'bog.html') are looked up in the hashref. If found, 
the corresponding value is used for the element label.

If this parameter is a subroutine reference, the subroutine is invoked 
for each element as:

  C<$sub->($elt, $base, $last)>

where $elt is the fully-qualified element (e.g. /foo/bar or 
/foo/bar/bog.html), $base is the element basename (e.g. 'bar' or 
'bog.html'), and $last is a boolean true iff this is the last element.
The subroutine should return the label to use (return undef or '' to
accept the default).

If no label is found for an element, the default behaviour is to use
the element basename as its label (without any suffix, if the final 
element). If the label is lowercase and only \w characters, it will be
ucfirst()-ed.

=back

RENDERING

=over 4

=item *

L<sep|sep> - the separator (scalar) used between breadcrumb elements. 
Default: '&nbsp;&gt;&nbsp;'.

=item *

L<format|format> - a subroutine reference or a (scalar) sprintf pattern
used to format each breadcrumb element except the last (for which, see 
L<format_last>). 

If a subroutine reference, the subroutine is invoked for each element as:

  C<$sub->($elt, $label)>.

where $elt is fully-qualified element (e.g. /foo/bar or /foo/bar/bog.html) 
and $label is the label for the element.

If a scalar, it is used as a sprintf format with the fully-qualified 
element and the label as arguments i.e. C<sprintf $format, $element, 
$label>.

Default: '<a href="%s">%s</a>' i.e. a vanilla HTML link.

=item *

L<format_last|format_last> - a subroutine reference or a (scalar) 
sprintf pattern used to format the last breadcrumb element (not a 
link).

If a subroutine reference, the subroutine is invoked for the element
the label as only parameter i.e. C<$sub->($label)>.

If a scalar, it is used as a sprintf format with the label as 
argument i.e. C<sprintf $format_last, $label>.

Default: '%s' i.e. the label itself.

=back


=head1 AUTHOR

Gavin Carr <gavin@openfusion.com.au>


=head1 COPYRIGHT

Copyright 2002-2003, Gavin Carr. All Rights Reserved.

This program is free software. You may copy or redistribute it under the 
same terms as perl itself.

=cut
