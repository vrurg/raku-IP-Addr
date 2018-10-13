#! /usr/bin/env false

use v6.c;

unit class IP::Addr;

use IP::Addr::Handler;
use IP::Addr::v4;

has IP::Addr::Handler $.handler handles **;

proto method new (|) { * }
multi method new ( IP::Addr::Handler:D :$handler! ) {
    self.bless( :$handler )
}
multi method new ( |args ) {
    self.bless.set( |args )
}

multi submethod TWEAK ( IP::Addr::Handler:D :$!handler ) {
    #note "TWEAK WITH handler";
    $!handler.parent = self;
}
multi submethod TWEAK () { }

proto method set (|) { {*}; self }
multi method set( Str:D $source ) { samewith( :$source ) }
multi method set( Str:D :$source! ) {
    if is-ipv4( $source ) {
        #note "Creating IPv4 hander";
        $!handler = IP::Addr::v4.new( :$source, :parent( self ) );
    }
    else {
        die "Unknown address format";
    }
}

method Str { $!handler.Str }
multi method gist ( ::?CLASS:D: --> Str) { self.handler.Str }
multi method gist ( ::?CLASS:U: ) { nextsame }

multi postfix:<++> ( IP::Addr:D $ip ) is export {
    $ip.inc
}

multi infix:<+> ( IP::Addr:D $ip, Int:D $count ) is export {
    $ip.dup.add( $count )
}

multi infix:<+> ( Int:D $count, IP::Addr:D $ip ) is export {
    $ip.dup.add( $count )
}

multi infix:<-> ( IP::Addr:D $ip, Int:D $count ) is export {
    $ip.dup.add( -$count )
}

multi infix:<cmp> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $a.cmp( $b )
}

multi infix:<cmp> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.cmp( $b )
}

multi infix:<cmp> ( Str:D $a, IP::Addr:D $b ) is export {
    $b.dup.new( $a ).cmp( $b )
}

multi infix:<eqv> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $a.eq( $b )
}

multi infix:<eqv> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.eq( $b )
}

multi infix:<eqv> ( Str:D $a, IP::Addr:D $b ) is export {
    $b.dup( $a ).eq( $b )
}

multi infix:<==> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $a.eq( $b )
}

multi infix:<==> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.eq( $b )
}

multi infix:<==> ( Str:D $a, IP::Addr:D $b ) is export {
    $b.dup( $a ).eq( $b )
}

multi infix:<< < >> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $a.lt( $b )
}

multi infix:<< < >> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.lt( $b )
}

multi infix:<< < >> ( Str:D $a, IP::Addr:D $b ) is export {
    $b.dup( $a ).lt( $b )
}

multi infix:<< <= >> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $a.lt( $b ) or $a.eq( $b )
}

multi infix:<< <= >> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.lt( $b ) or $a.eq( $b )
}

multi infix:<< <= >> ( Str:D $a, IP::Addr:D $b ) is export {
    my $ip-a = $b.dup( $a );
    $ip-a.lt( $b ) or $ip-a.eq( $b )
}

multi infix:<< > >> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $a.gt( $b )
}

multi infix:<< > >> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.gt( $b )
}

multi infix:<< > >> ( Str:D $a, IP::Addr:D $b ) is export {
    $b.dup( $a ).gt( $b )
}

multi infix:<< >= >> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $a.gt( $b ) or $a.eq( $b )
}

multi infix:<< >= >> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.gt( $b ) or $a.eq( $b )
}

multi infix:<< >= >> ( Str:D $a, IP::Addr:D $b ) is export {
    my $ip-a = $b.dup( $a );
    $ip-a.gt( $b ) or $ip-a.eq( $b )
}

multi infix:<(cont)> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $a.contains( $b )
}

multi infix:<(cont)> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.contains( $b )
}

multi infix:<(cont)> ( Str:D $a, IP::Addr:D $b ) is export {
    $b.dup.new( $a ).contains( $b )
}

multi infix:<∋> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $a.contains( $b )
}

multi infix:<∋> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.contains( $b )
}

multi infix:<∋> ( Str:D $a, IP::Addr:D $b ) is export {
    $b.dup.new( $a ).contains( $b )
}

multi infix:<⊆> ( IP::Addr:D $a, IP::Addr:D $b ) is export {
    $b.contains( $a )
}

multi infix:<⊆> ( IP::Addr:D $a, Str:D $b ) is export {
    $a.dup( $b ).contains( $a )
}

multi infix:<⊆> ( Str:D $a, IP::Addr:D $b ) is export {
    $b.contains( $a )
}

multi method dup {
    self.WHAT.new( :handler( $.handler.clone ) );
}
multi method dup ( |args ) {
    self.WHAT.new( |args )
}

method dup-handler( |args ) {
    self.WHAT.new( :handler( $.handler.WHAT.new( |args ) ) )
}

# ---- Iterable ----

my class IPIterable does Iterable {
    has $.ip;

    method iterator {
        my class IPIterator does Iterator {
            has $.ip is rw;

            method pull-one {
                return IterationEnd without $.ip;
                my $current = $.ip;
                $.ip = $.ip.next;
                $current
            }
        };
        IPIterator.new( :$!ip )
    }
}

method each {
    IPIterable.new( :ip( self ) )
}

=begin pod

=NAME    IP::Addr
=AUTHOR  cpan:VRURG <vrurg@cpan.org>
=VERSION 0.0.0

=head1 Synopsis

=head1 Description

=head1 Examples

=head1 See also

=end pod

# vim: ft=perl6 et sw=4
