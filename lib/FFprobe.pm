package FFprobe;

use common::sense;
use Carp;
use version 0.77;

our $VERSION = qv("v0.0.1");

=head1 NAME

FFprobe - probes information from multimedia files using 'ffprobe'

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

sub __run_child(&@) {
    my $prepare = shift;
    my $mode = shift;
    croak "Invalid mode $mode, must be '-|' or '|-'" unless $mode eq '-|' || $mode eq '|-';
    if(open my $child, $mode) {
	return $child;
    } else {
	$prepare->();
	exec(@_);
	exit(1);
    }
}

sub run_child(@) {
    __run_child {} @_;
}

sub run_child2(@) {
    __run_child { close STDERR; open STDERR, ">&STDOUT"; } @_;
}

sub probe_file($$) {
    my ($class, $file) = @_;
    my $probe = run_child2 "-|", "ffprobe", "-show_format", "-show_streams", $file;

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

