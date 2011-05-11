use Module::Build;

my $build = Module::Build->new(
    module_name => 'FFprobe',
    license => 'bsd',
    requires => {
	perl => '5.10.0',
	Carp => 0,
	common::sense => 0,
	version => '0.77',
    }
);

$build->create_build_script;
