package GatlingReport::GraphData;
#===============================================================================

=head1 NAME

GatlingReport::GraphData - a class to handle graph data.


=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use GatlingReport::GraphData;

    my $gd = GatlingReport::GraphData->new(
        name    => 'Test',
        color   => '#020202'    # defaults to '#000000'
    );

    # get the Graph data javascript text...
    my $out = $gd->process( $data );

=head1 EXPORT

None

=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at softeco.it> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Marco Masetti.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 SUBROUTINES/METHODS

=cut

#===============================================================================
use Moose;
use Template;
use String::CamelCase qw( camelize );
use File::Slurp       qw( read_file );
use JSON              qw( decode_json );

has 'name'  => ( is => 'rw', isa => 'Str', default => 'Test' );
has 'color' => ( is => 'rw', isa => 'Str', default => '#000000' );
has 'out_str' =>(is => 'ro', isa => 'Str', lazy => 1, builder => '_set_out_str' );

sub get_varname {
    my $name = shift;

    $name = camelize ( $name );
    $name =~ s/\s//g;
    return ( lcfirst $name );
}

#=============================================================

=head2 get_time_sequence

=head3 INPUT

$file   : graph javascript file path

=head3 OUTPUT

An hashref

=head3 DESCRIPTION

Opens the input file and extracts all time points (in secords since the epoch).

=cut

#=============================================================
sub get_time_sequence {
    my ( $self, $file ) = @_;

    die "Error, input file not found or not readable\n"
        unless -f $file;

    my $text = read_file ( $file );

    my $j;

    if ( $text =~ /\[(.+)\]/ ) {
        $j = "[[$1]]";
    }

    die "Error parsing javascript file\n" unless $j;

    my $data = decode_json( $j )
        or die "Error getting data\n";

    my @time_seq;

    foreach ( @$data ) {
        push @time_seq, $_->[0];
    }

    return @time_seq;
}

sub process {
    my ( $self, $data ) = @_;

    my $params = {
        var_name    => get_varname( $self->{name} ),
        color       => $self->{color},
        name        => $self->{name},
        data        => $data
    };

    my $t = Template->new({
            PRE_CHOMP  => 1,
        }) or die $Template::ERROR, "\n";
    my $out='';
    $t->process(\*DATA, $params, \$out)
        or die $Template::ERROR, "\n";
    return $out;
}
1; 
 
__DATA__
[% var_name %] = {
    color: '[% color %]',
    name: '[% name %]',
    data: [ [% FOREACH item IN data %]
        [ [% item.0 %], [% item.1 %] ],
    [% END %] ],
    tooltip: { yDecimals: 0, ySuffix: '', valueDecimals: 0 }, 
    zIndex: 20, 
    yAxis: 1
};
