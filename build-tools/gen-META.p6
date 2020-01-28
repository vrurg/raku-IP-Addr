#!/usr/bin/env perl6

use lib <lib>;
use META6;
use IP::Addr;

my $m = META6.new(
    name           => 'IP::Addr',
    description    => 'IPv4/IPv6 manipulation',
    version        => IP::Addr.^ver,
    perl-version   => Version.new('6.*'),
    depends        => [ ],
    test-depends   => <Test Test::META Test::When>,
    build-depends  => <META6 p6doc Pod::To::Markdown>,
    tags           => <IP IPv4 IPv6>,
    authors        => ['Vadim Belman <vrurg@cpan.org>'],
    auth           => 'github:vrurg',
    source-url     => 'git://github.com/vrurg/raku-IP-Addr.git',
    support        => META6::Support.new(
        source          => 'https://github.com/vrurg/raku-IP-Addr.git',
    ),
    provides => {
        'IP::Addr'          => 'lib/IP/Addr.pm6',
        'IP::Addr::Common'  => 'lib/IP/Addr/Common.pm6',
        'IP::Addr::Handler' => 'lib/IP/Addr/Handler.pm6',
        'IP::Addr::v4'      => 'lib/IP/Addr/v4.pm6',
        'IP::Addr::v6'      => 'lib/IP/Addr/v6.pm6',
    },
    license        => 'Artistic-2.0',
    production     => True,
);

print $m.to-json;
