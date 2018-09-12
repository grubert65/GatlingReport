package GatlingReport;

use Moose;
use HTML::TreeBuilder 5 -weak; # Ensure weak references in use
use File::Slurp     qw( read_file );
use Log::Log4perl;
use JSON::Syck      qw( LoadFile );
use Time::ParseDate qw( parsedate );

use GatlingReport::GraphData;

=head1 NAME

GatlingReport - A simple class that parses Gatling report file adding data to it

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use GatlingReport;

    my $o = GatlingReport->new();
    $o->parse_report( $report_file );

    # Given a chaostoolkit experiment journal
    # this will add all successful actions to
    # the response times graph
    $o->add_ct_experiment( $ct_journal_file );

    $o->dump_report();

=head1 SUBROUTINES/METHODS

=cut

has 'log' => (
    is      => 'ro',
    isa     => 'Log::Log4perl::Logger',
    lazy    => 1,
    default => sub { return Log::Log4perl->get_logger( __PACKAGE__ ) }
);

has 'report_dir'  => ( is => 'rw', required => 1 );
has 'out_label'   => ( is  => 'rw', isa => 'Str', default => '_updated' );
has 'varnames'    => ( is => 'ro', isa => 'ArrayRef', writer => '_set_varnames' );
has 'report_tree' => ( 
    is => 'ro', 
    isa => 'HTML::TreeBuilder', 
    lazy => 1,
    default => sub {  HTML::TreeBuilder->new }
);



#=============================================================

=head2 parse_report

=head3 INPUT

=head3 OUTPUT

The report_tree object

=head3 DESCRIPTION

Parses the report file.

=cut

#=============================================================
sub parse_report {
    my $self = shift;

    my $filename = $self->{report_dir}."/index.html";

    $self->log->debug("Gatling report HTML file: $filename");
    die "Report file not found\n" unless -f $filename;
    $self->report_tree->parse_file( $filename );
}

#=============================================================

=head2 dump_report

=head3 INPUT

=head3 OUTPUT

=head3 DESCRIPTION

Stores the report in the same report folder, with filename index<$label>.
Then, if some javascript variable names have been defined, it opens
the file again and add after the call to allUsersData the list of variables....

=cut

#=============================================================
sub dump_report {
    my $self = shift;

    my $filename = "$self->{report_dir}/index$self->{out_label}.html";
    open ( my $fh, ">$filename" );
    print $fh $self->report_tree->as_HTML;
    close $fh;

    if ( $self->varnames ) {
        my $var_text = join(', ', @{$self->varnames} );
        my $text = read_file( $filename );
        if ( $text =~ /allUsersData,/ ) {
            my $new_text = $`.$var_text.','.$';

            # now change the "Active Users" label...
            my $p = rindex($new_text, "Active Users");
            substr($new_text, $p, length("Experiments "), "Experiments ") if ( $p );

            open ( my $fh, ">$filename" );
            print $fh $new_text;
            close $fh;
        }
    }

    $self->log->info("Report updated: $filename");
    return 1;
}


#=============================================================

=head2 add_ct_experiment

=head3 INPUT

$ct_journal : the chaostoolkit journal file

=head3 OUTPUT

the number of actions added or die in case of errors

=head3 DESCRIPTION

Workflow:
* take the CT journal file as input
* parses the CT journal:
* for each action in the run section: 
*     create a new js file that defines a new var with data for that action. 
      An action is represented with a 0 value when not active and 1 value when active.
* updates to the index.html file:
    * update title to add experiment title
    * all new js files have to be loaded
    * the “Responses per second” chart has to be updated and the AllUsersData has to be 
      replaced with the actions data, the “Active Users” yaxis has to be replaced with “Experiments”

=cut

#=============================================================
sub add_ct_experiment {
    my ( $self, $ct_journal ) = @_;

    die "ChaosToolkit journal file not exists or not readable\n"
        unless -f $ct_journal;
    
    # read the journal and create a single js file for each action and add it to the report folder.
    my $ct_journal_data = LoadFile($ct_journal);
    
# * for each action in the run section: 
    my $action_index=0;
    my $time_seq;
    my @varnames;
    foreach my $run ( @{$ct_journal_data->{run}} ) {
        if ( $run->{activity}->{type} eq 'action' && $run->{status} eq 'succeeded' ) {

# *     create a new graph js file that defines a new var with data for that action. 
#       the file has to be saved in the js folder
#       to create the action graph data I need:
#           - graph time start/end
#           - action start/end times
            my $graph = GatlingReport::GraphData->new(
                color   => '#050505',
                name    => $run->{activity}->{name},
                varname => $run->{activity}->{provider}->{func}.$action_index
            );
            $time_seq //= $graph->get_time_sequence( $self->report_dir.'/js/all_sessions.js');
            my $duration = ($run->{activity}->{pauses} && $run->{activity}->{pauses}->{after} ) ?
                $run->{duration} + $run->{activity}->{pauses}->{after} : $run->{duration};

            my $switch_on_time = parsedate( "$run->{start} GMT", SUBSECOND => 1 );
            my $data = $graph->set_on_off_time_sequence( 
                time_sequence   => $time_seq,
                switch_on_time  => $switch_on_time,
                duration        => $duration
            );
            my $out = $graph->process( $data );

            my $graph_filepath = "$self->{report_dir}/js/$graph->{varname}.js";
            open (my $fh, ">$graph_filepath") or die "Error opening file $graph_filepath:$!\n";
            print $fh $out;
            close $fh;

            # add the js file to gatling report...
            my $elem = HTML::Element->new('script', src => "js/$graph->{varname}.js", type => 'text/javascript');
            $self->report_tree->{_content}->[0]->push_content( $elem );
            push @varnames, $graph->{varname};

            $action_index++;
        }
    }

    $self->_set_varnames( \@varnames ) if ( scalar @varnames );

    return $action_index;
}


=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at sky.uk> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GatlingReport


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Marco Masetti.

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


=cut

1; # End of GatlingReport
