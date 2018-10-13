#! /usr/bin/env false

use v6.c;

use IP::Addr::Handler;
use IP::Addr::Const;

unit class IP::Addr::v4 does IP::Addr::Handler;

my %addr-class = 
    "0.0.0.0/8" => {
        scope => software,
        description => "current network",
    },
    "10.0.0.0/8" => {
        scope => private,
        description => "local communications within a private network",
    },
    "100.64.0.0/10" => {
        scope => private,
        description => "shared address space for communications between a service provider and its subscribers when using a carrier-grade NAT",
    },
    "127.0.0.0/8" => {
        scope => host,
        description => "loopback addresses to the local host",
    },
    "169.254.0.0/16" => {
        scope => subnet,
        description => "link-local addresses between two hosts on a single link when no IP address is otherwise specified",
    },
    "172.16.0.0/12" => {
        scope => private,
        description => "local communications within a private network",
    },
    "192.0.0.0/24" => {
        scope => private,
        description => "IETF Protocol Assignments",
    },
    "192.0.2.0/24" => {
        scope => documentation,
        description => "documentation and examples",
    },
    "192.88.99.0/24" => {
        scope => internet,
        description => "formerly used for IPv6 to IPv4 relay (included IPv6 address block 2002::/16).",
    },
    "192.168.0.0/16" => {
        scope => private,
        description => "local communications within a private network",
    },
    "198.18.0.0/15" => {
        scope => private,
        description => "benchmark testing of inter-network communications between two separate subnets",
    },
    "198.51.100.0/24" => {
        scope => documentation,
        description => "documentation and examples",
    },
    "203.0.113.0/24" => {
        scope => documentation,
        description => "documentation and examples",
    },
    "224.0.0.0/4" => {
        scope => internet,
        description => "IP multicast",
    },
    "240.0.0.0/4" => {
        scope => internet,
        description => "reserved for future use",
    },
    "255.255.255.255/32" => {
        scope => subnet,
        description => q<reserved for the "limited broadcast" destination address>,
    },
    ;

class v4-actions { ... }
trusts v4-actions;

method new ( :$parent, |args ) {
    self.bless( :$parent ).set( |args )
}

submethod TWEAK ( :$!parent ) { }

sub valid-dotted-subnet ( $m ) {
    my $mask = 0;
    $mask = ( $mask +< 8 ) + $_.Int for $m<ip><octet>;
    $mask.base(2) ~~ / ^ '1'* '0'* $ /
}

grammar IPv4-Grammar {

    method TOP (Bool :$validate = False) {
        my $*VALIDATE-IP = $validate;
        self.ip-variants
    }

    rule ip-variants {
        <range> | <cidr> | <ip>
    }

    token ip {
        <octet> ** 4 % '.'
    }
    
    token octet {
        \d ** 1..3 <?{ $*VALIDATE-IP ?? ( $/.Int < 256 ) !! True }>
    }

    rule range {
        <ip> '-' <ip>
    }

    token cidr {
        <ip> '/' <prefix-len>
    }

    token prefix-len {
            <ip> <?{ $*VALIDATE-IP ?? valid-dotted-subnet( $/ ) !! True }>
            | <bits>
    }

    token bits {
        \d ** 1..2 <?{ $*VALIDATE-IP ?? ( $/.Int <= 32 ) !! True }>
    }
}

class v4-actions {
    has $.ip-obj;

    method TOP ( $m ) { $m.make( $m.ast ) }
    method ip-variants ( $m ) {
        with $m<ip> { $m.make( [ ip, .ast ] ) }
        with $m<range> { $m.make( [ range,  .ast ] ) }
        with $m<cidr> { $m.make( [ cidr, .ast ] ) }
    }
    method octet ( $m ) { $m.make( $m.Int ) }
    method ip ( $m ) { 
        $m.make( IP::Addr::v4.to-int( $m<octet>.map: *.ast ) )
    }
    method range ( $m ) { $m.make( { :first( $m<ip>[0].ast ), :last( $m<ip>[1].ast ) } ) }

    method cidr ( $m ) { $m.make( { :ip( $m<ip>.ast ), :prefix-len( $m<prefix-len>.ast ) } ) }

    method bits ( $m ) { $m.make( $m.Int ) }
    multi method prefix-len ( $m where so *<ip> ) {
        #note "p-len from ip: ", $m<ip>.ast;
        #note "len from mask: ", $.ip-obj!IP::Addr::v4::mask2pfx( $m<ip>.ast );
        $m.make( $.ip-obj!IP::Addr::v4::mask2pfx( $m<ip>.ast ) );
    }
    multi method prefix-len( $m where so *<bits> ) {
        #note "p-len from bits";
        $m.make( $m<bits>.ast )
    }
}

our sub is-ipv4 ( Str $ip --> Bool ) is export {
    #note IPv4.parse( $ip, args => \(:validate) );
    so IPv4-Grammar.parse( $ip, args => \(:validate) );
}

method info {
    state @info;
    
    once {
        my @unsorted;
        for %addr-class.kv -> $net, $info {
            my $ip-net = $.parent.dup( $net );
            @info.push: { :net($ip-net), :$info };
        }
    }

    for @info -> $info {
        if self.overlaps( $info<net> ) {
            if $info<net>.contains( self ) {
                return $info<info>;
            }
            return { scope => undetermined, description => "range overlaps with but not contained by a reserved range" }
        }
    }

    return { scope => public, description => "public IP" }
}

proto method to-int (|) { * }
multi method to-int ( @octets where *.elems == 4 --> Int ) { 
    my Int $int-ip = 0;
    $int-ip = $int-ip * 256 + $_ for @octets; 
    self.bitcap( $int-ip ) 
}
multi method to-int ( *@octets where *.elems == 4 --> Int ) { samewith( @octets ) }

method to-octets ( Int:D $addr is copy --> List ) {
    my Int @octs;
    for 3...0 -> $i {
        @octs[$i] = self.bitcap( $addr +& 0xff, 8 );
        $addr +>= 8;
    }
    @octs.List
}

method !octets2str( @octs --> Str ) { @octs.join('.') }

method int2str( Int $addr ) { self!octets2str( self.to-octets( $addr ) ) }

method addr-len { 32 }

proto method set (|) {
    self!reset; 
    {*}
    self
}

multi method set ( Str:D $source ) { samewith( :$source ) }
multi method set ( Str:D :$!source! ) {
    #note "Set from Str source";
    my $m = IPv4-Grammar.parse( $!source, :actions( v4-actions.new( :ip-obj( self ) ) ), :args( :validate ) );
    # TODO Exception if parse failed
    self!recalc( $m.ast );
}

multi method set ( Int:D :$ip!, Int:D :$prefix-len! ) {
    #note "Set from Int ip / Int prefix";
    self!recalc( [ cidr, { :$ip, :$prefix-len } ] )
}

multi method set ( Int:D :$first!, Int:D :$last! ) {
    #note "Set from Int first / Int last";
    self!recalc( [ range,  { :$first, :$last } ] )
}

multi method set( Int:D :$ip! ) {
    #note "Set from Int ip";
    self!recalc( [ ip, $ip ] )
}

method prefix { self.int2str( $!addr ) ~ "/" ~ self.prefix-len }
method version ( --> 4 ) {}

=begin pod

=NAME    IP::Addr::v4
=AUTHOR  cpan:VRURG <vrurg@cpan.org>
=VERSION 0.0.0

=head1 Synopsis

=head1 Description

=head1 Examples

=head1 See also

=end pod

# vim: ft=perl6 et sw=4
