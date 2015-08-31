use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Dancer::Plugin::DataTransposeValidator',
    AUTHOR        => 'Peter Mottram <peter@sysnix.com>',
    VERSION_FROM  => 'lib/Dancer/Plugin/DataTransposeValidator.pm',
    ABSTRACT_FROM => 'lib/Dancer/Plugin/DataTransposeValidator.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.47
        ? ( 'LICENSE' => 'perl' )
        : () ),
    MIN_PERL_VERSION => '5.010000',
    BUILD_REQUIRES   => {
        'aliased'               => 0,
        'Email::Valid'          => 0,
        'File::Spec'            => 0,
        'HTTP::Request::Common' => 0,
        'Plack::Builder'        => 0,
        'Plack::Test'           => 0,
        'Test::Deep'            => 0,
        'Test::Exception'       => 0,
        'Test::More'            => 0,
    },
    PREREQ_PM => {
        'Data::Transpose'  => '0.0020',
        'Moo'              => 0,
        'namespace::clean' => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-DataTransposeValidator-*' },
    test  => { TESTS => join( ' ', ( glob('t/*.t'), glob('t/*/*.t') ) ) },
    META_MERGE => {
        resources => {
            repository =>
'https://github.com/interchange/Dancer-Plugin-DataTransposeValidator.git',
            bugtracker =>
'https://github.com/interchange/Dancer-Plugin-DataTransposeValidator/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
