#!/usr/bin/env perl

use common::sense;
use Test::More tests => 8;

use FFprobe;

ok( !defined FFprobe->probe_file("./invalid/path"), "non-existant file" );
ok( !defined FFprobe->probe_file("./t/test.t"), "non-multimedia file" );

my $probe = FFprobe->probe_file("t/test.ogg");

ok( defined $probe and ref $probe eq 'HASH', "multimedia file" ) ||
    BAIL_OUT("Could not probe t/test.ogg");

is( $$probe{format}{nb_streams}, 1, "number of streams" );
is( $$probe{format}{format_name}, 'ogg', "format name" );
is( scalar @{$$probe{stream}}, $$probe{format}{nb_streams}, "stream array size" );
is( $$probe{stream}[0]{codec_type}, 'audio', "stream codec type" );
is( $$probe{stream}[0]{codec_name}, 'vorbis', "stream codec name" );
