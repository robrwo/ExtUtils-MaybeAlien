package ExtUtils::MaybeAlien;

use strict;
use warnings;

use Module::Runtime qw/ require_module /;

my @mm_args;

sub mm_args {
    my ( $class, $libname, $alienmod, $alienver ) = @_;

    my @build;

    eval {

        require_module( 'Devel::CheckLib' );

        my @dirs = ( "/usr/local", "/opt/local", "/opt/${libname}" );

        my @libs = map "$_/lib",     @dirs;
        my @incs = map "$_/include", @dirs;

        Devel::CheckLib::assert_lib(
            lib     => $libname,
            header  => $libname . '.h',
            libpath => [@libs],
            incpath => [@incs],
        );

        @build = (
            INC => join( ' ', ( map "-I$_", @incs ) ),
            LIBS => join ' ',
            ( map "-L$_", @libs ), "-l${libname}",
        );

    };

    warn $@ if $@;

    unless (@build) {

        eval {
            require_module( 'Alien::Base::Wrapper');
            Alien::Base::Wrapper->import( $alienmod, '!export' );
            require_module( $alienmod );
            $alienmod->VERSION( $alienver // 0 );
            $alienmod->import();
        };

        if ($@) {
            warn $@;
            exit;
        }

        @build = (
            CONFIGURE_REQUIRES => {
                'Alien::Base::Wrapper' => '0',
                $alienmod              => $alienver // 0,
            },
        );

        push @build, Alien::Base::Wrapper->mm_args unless $@;

    }

    return @build;
}

1;
