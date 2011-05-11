package FFprobe;

use common::sense;
use Carp;
use version 0.77;

our $VERSION = qv("v0.0.1");

=head1 NAME

FFprobe - probes information from multimedia files using 'ffprobe'

=head1 SYNOPSIS

    use FFprobe;

    my $probe = FFprobe->probe_file("/path/to/multimedia/file");
    print $probe->{format}->{format_name};
    print $probe->{stream}->[0]->{codec_name};

=head1 METHODS

=head2 C<probe_file($)>

 use FFprobe;
 my $probe = FFprobe->probe_file("/path/to/file");

Runs 'ffprobe -show_format -show_streams' on the filename given as
argument. Returns a hashref with a structured form parsed from
ffprobe's output. Sample output:

    $VAR1 = {
        'format' => {
            'start_time' => '0.000000',
            'filename'   => '/path/to/input/file',
        },
        'stream' => [
            {
                'index' => '0',
                'codec_tag' => '0x0000',
            },
            {
                'index' => '1',
                'codec_tag' => '0x0000',
            }
        ]
    };

The "index" entry may not exist if there is only one stream.

=cut

sub __run_ffprobe(@) {
    if(open my $child, "-|") {
	return $child;
    } else {
	close STDERR;
	open STDERR, ">&STDOUT";
	exec('ffprobe', '-show_format', '-show_streams', @_);
	exit(1);
    }
}

sub probe_file($$) {
    my ($class, $file) = @_;
    my $probe = __run_ffprobe $file;

    my ($tree, $branch, $tag, $stream);
    while(my $line = <$probe>) {
	if($line =~ m!^\[(/?)(STREAM|FORMAT)\]!) {
	    if ($1 eq "/") {
		$branch = undef;
	    } else {
		$tag = lc($2);
		$branch = ($$tree{$tag} //= {});
		$stream = $branch;
	    }
	} elsif (defined $branch and $line =~ /^(.*?)=(.*)$/) {
	    if ($1 eq "index") {
		$branch = ($$tree{$tag} = []) unless ref $branch eq 'ARRAY';
		$stream = ($$branch[$2] //= {});
	    }
	    $$stream{$1} = $2;
	    $$stream{$1} =~ s/\s+$//s;
	}
    }
    close $probe;

    return $tree;
}

=head1 AUTHOR

Kovensky, C<< <diogomfranco at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Diogo Franco.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
