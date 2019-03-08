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

    # given a javascript file for a highgraph object
    # extracts the time sequence
    my $time_seq = $o->get_time_sequence('./data/exp1/gatling-report/js/all_sessions.js');

    # prepares the data array for an on/off graph
    my $data = $o->set_on_off_time_sequence(
        time_sequence    => $time_seq, 
        switch_on_time   => 1536318951,
        duration         => 01379
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
under the terms of Perl itself.

=head1 SUBROUTINES/METHODS

=cut

#===============================================================================
use Moose;
use Template;
use String::CamelCase qw( camelize );
use File::Slurp       qw( read_file );
use JSON              qw( decode_json );

has 'name'  => ( is => 'rw', isa => 'Str', default => 'Test' );
has 'varname'=>( is => 'rw', isa => 'Str', lazy => 1, default => 'Test', trigger => \&_set_varname);
has 'color' => ( is => 'rw', isa => 'Str', default => '#000000' );
has 'template'=>(
    is  => 'ro',
    isa => 'Str',
    lazy    => 1,
    default => sub {
        return <<EOT;

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

EOT
    });

sub _set_varname {
    my ( $self, $name ) = @_;

    $name = camelize ( $name );
    $name =~ s/\s//g;
    $self->{varname} =  lcfirst $name;
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

    return \@time_seq;
}


#=============================================================

=head2 set_on_off_time_sequence

=head3 INPUT

An hash or hashref with the following keys:

time_sequence   : an array of times in seconds since the epoch
switch_on_time  : switch on time in seconds since the epoch
duration        : duration of the "on" phase

=head3 OUTPUT

An arrayref

=head3 DESCRIPTION

Returns an array of (time, value) pair. Times are as in the 
passed time sequence, values are 1 in the interval 
   switch_on_time < time < switch_off_time
0 anywhere else.

=cut

#=============================================================
sub set_on_off_time_sequence {
    my $self = shift;
    my $params = _get_as_hash( @_ );

    my @time_seq = @{$params->{time_sequence}};
    $params->{switch_off_time} = $params->{switch_on_time} + $params->{duration};

    $params->{switch_on_time}  = int ( $params->{switch_on_time}  * 1000 );
    $params->{switch_off_time} = int ( $params->{switch_off_time} * 1000 );
    push @time_seq, $params->{switch_on_time}-1;
    push @time_seq, $params->{switch_on_time};
    push @time_seq, $params->{switch_off_time}-1;
    push @time_seq, $params->{switch_off_time};

    @time_seq = sort { $a <=> $b } @time_seq;

     my @out;
     foreach ( @time_seq ) {
         if ( $_ < $params->{switch_on_time} ) {
             push @out, [ $_, 0 ];
         } elsif ( $_ >= $params->{switch_on_time} && $_ < $params->{switch_off_time} ) {
             push @out, [ $_, 1 ];
         } else {
             push @out, [ $_, 0 ];
         }
     }
     return \@out;
}

sub _get_as_hash {
    my $h={};
    if ( ref $_[0] eq 'HASH' ) {
        $h = shift;
    } else {
        %$h = @_;
    }
    return $h;
}

sub process {
    my ( $self, $data ) = @_;

    my $params = {
        var_name    => $self->{varname},
        color       => $self->{color},
        name        => $self->{name},
        data        => $data
    };

    my $t = Template->new({
            PRE_CHOMP  => 1,
        }) or die $Template::ERROR, "\n";
    my $out='';
    my $template = $self->template;
    $t->process(\$template, $params, \$out)
        or die $Template::ERROR, "\n";
    return $out;
}
1; 
