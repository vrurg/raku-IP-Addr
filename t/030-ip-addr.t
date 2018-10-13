#! /usr/bin/env perl6

use v6.c;

use Test;
use IP::Addr;

my $ip = IP::Addr.new( "192.168.13.1" );

is $ip.handler.WHO, "IP::Addr::v4", "handler class";

is ~$ip, "192.168.13.1", "stringification";
is "IP inline: $ip", "IP inline: 192.168.13.1";

$ip = IP::Addr.new( "192.168.13.9/26" );

is $ip.network, "192.168.13.0/26", "network";

is $ip, "192.168.13.9/26", "before increment";

$ip++;

is ~$ip, "192.168.13.10/26", "after increment";

my $ip2 = $ip.first;

is ~$ip2, "192.168.13.10/26", "first for single IP is the IP itself";

$ip2 = $ip2.next;

is ~$ip2, "192.168.13.11/26", "next IP";

$ip2 = $ip2.prev;

is ~$ip2, "192.168.13.10/26", "prev IP";

my @ips;
for $ip.first.each -> $i {
    push @ips, ~$i;
}

my @expect = (10..63).map( { "192.168.13.$_/26" } );

is-deeply @ips, @expect, "iterator";

done-testing;
# vim: ft=perl6 et sw=4
