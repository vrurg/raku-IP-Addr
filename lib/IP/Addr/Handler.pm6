#! /usr/bin/env false

use v6.c;

use IP::Addr::Const;

my %bitcap-mask = (0..128).map: { $_ => 2**$_ - 1 }; # Mask for each bit capacity

unit role IP::Addr::Handler;

has $.parent is required is rw; # IP::Addr object

has Str $.source;
has IP-FORM $.form;
has Int $!addr;
has Int $.prefix-len;
has Int $!first-addr;
has Int $!last-addr;
# The following two are formally not used by IPv6 but would be calculated anyway.
has Int $!mask;
has Int $!wildcard;

has Int $!addr-bits = self.addr-len; # 32 for IPv4 and 128 for IPv6

method set { ... }
method prefix { ... }
method version { ... }
method info { ... }

method int2str ( Int ) { ... }

#| Returns number of bits in address
method addr-len { ... }

method bitcap( Int $i, Int $bits = self.addr-len ) is export {
    $i +& %bitcap-mask{ $bits } 
}

method ip { $.parent.dup-handler( ip => $!addr ) }
method first-ip { $.parent.dup-handler( ip =>$!first-addr ) }
method last-ip { $.parent.dup-handler( ip => $!last-addr ) }
method network { $.parent.dup-handler( ip => $!first-addr, :$!prefix-len ) }
method mask { self.int2str( $!mask ) }
method wildcard { self.int2str( $!wildcard ) }
method size { $!last-addr - $!first-addr + 1 }

method int-ip { $!addr }
method int-first-ip { $!first-addr }
method int-last-ip { $!last-addr }
method int-mask { $!mask }
method int-wildcard { $!wildcard }

method inc {
    $!addr++ if $!addr < $!last-addr;
    self.parent
}
method dec {
    $!addr-- if $!addr > $!first-addr;
    self.parent
}
method add ( Int $count ) {
    $!addr += $count;
    $!addr = $!last-addr if $!addr > $!last-addr;
    $!addr = $!first-addr if $!addr < $!first-addr;
    self.parent
}

sub term:<IP::Addr> () { once require IP::Addr }

proto method eq (|) { * }
multi method eq ( ::?CLASS:D $ip --> Bool ) {
    if $ip.form == $!form {
        if $!form == range {
            return so ( ( $!first-addr == $ip.int-first-ip ) and ( $!last-addr == $ip.int-last-ip ) );
        }
        return so ( ( $!addr == $ip.int-ip ) and ( $!mask == $ip.int-mask ) )
    }
    False;
}
multi method eq ( Str $addr --> Bool ) {
    samewith( self.WHAT.new( $addr ) )
}
multi method eq ( $ip where { $_.defined and $_ ~~ IP::Addr } --> Bool ) {
    samewith( $ip.handler )
}

proto method lt (|) { * }
multi method lt ( ::?CLASS:D $ip --> Bool ) { $!addr < $ip.int-ip }
multi method lt ( Str $addr --> Bool ) { samewith( self.WHAT.new( $addr ) ) }
multi method lt ( $ip where { $_.defined and $_ ~~ IP::Addr } --> Bool ) { samewith( $ip.handler ) }

proto method gt (|) { * }
multi method gt ( ::?CLASS:D $ip --> Bool ) { $!addr > $ip.int-ip }
multi method gt ( Str $addr --> Bool ) { samewith( self.WHAT.new( $addr ) ) }
multi method gt ( $ip where { $_.defined and $_ ~~ IP::Addr } --> Bool ) { samewith( $ip.handler ) }

proto method cmp (|) { * }
multi method cmp ( ::?CLASS:D $ip --> Order ) {
    ( $!addr || $!first-addr ) cmp ( $ip.int-ip || $ip.int-first-ip ); 
}
multi method cmp ( Str:D $addr --> Order ) { samewith( self.WHAT.new( $addr ) ) }
multi method cmp ( $ip where { $_.defined and $_ ~~ IP::Addr } --> Bool ) { samewith( $ip.handler ) }

proto method contains (|) { * }
multi method contains ( ::?CLASS:D $ip --> Bool ) {
    return ( $ip.int-first-ip >= $!first-addr ) && ( $ip.int-last-ip <= $!last-addr );
}
multi method contains ( Str $addr --> Bool ) { samewith( self.WHAT.new( $addr ) ) }
multi method contains ( $ip where { $_.defined and $_ ~~ IP::Addr } --> Bool ) { samewith( $ip.handler ) }

proto method overlaps (|) { * }
multi method overlaps ( ::?CLASS:D $ip --> Bool ) {
    return 
        ( $!first-addr ≥ $ip.int-first-ip and $!first-addr ≤ $ip.int-last-ip ) ||
        ( $!last-addr ≥ $ip.int-first-ip and $!last-addr ≤ $ip.int-last-ip ) ||
        ( $ip.int-first-ip ≥ $!first-addr and $ip.int-first-ip ≤ $!last-addr ) ||
        ( $ip.int-last-ip ≥ $!first-addr and $ip.int-last-ip ≤ $!last-addr ) 
}
multi method overlaps ( Str $addr --> Bool ) { samewith( self.WHAT.new( $addr ) ) }
multi method overlaps ( $ip where { $_.defined and $_ ~~ IP::Addr } --> Bool ) { samewith( $ip.handler ) }

method first {
    my $dup;
    #note "Setting first";
    given $!form {
        when range {
            return $.parent.dup-handler( :first( $!first-addr ), :last( $!last-addr ) );
        }
        when cidr {
            return $.parent.dup-handler( :ip( $!first-addr ), :$!prefix-len );
        }
        when ip {
            return $.parent.dup-handler( :ip( $!first-addr ) );
        }
    }
    die "Unknown IP form '$!form'";
}

method next {
    return Nil if $!addr >= $!last-addr;
    #note "> NEXT";
    $.parent.dup.inc
}

method prev {
    return Nil if $!addr <= $!first-addr;
    $.parent.dup.dec
}

method Str { 
    #note ".Str";
    given $!form {
        when ip { return self.int2str( $!addr ); }
        when cidr { return self.prefix }
        when range {
            return self.int2str( $!first-addr ) ~ "-" ~ self.int2str( $!last-addr );
        }
    }
    die "Unknown IP form '$!form'";
}

method !bits2mask ( Int $bits ) {
    %bitcap-mask{ $!addr-bits } +& +^ (2**($!addr-bits - $bits) - 1) 
}

method !pfx2mask( Int $len ) { # Subject for is cached trait
    state %pfx2mask; # Prefix length into network mask

    unless %pfx2mask{ $!addr-bits } {
        %pfx2mask{ $!addr-bits } = %( 
            (0..$!addr-bits).map: {
                $_ => self!bits2mask( $_ )
            } 
        );
    }

    %pfx2mask{ $!addr-bits }{ $len }
}

method !mask2pfx ( Int $mask ) {
    state %mask2pfx;

    unless %mask2pfx{ $!addr-bits } {
        %mask2pfx{ $!addr-bits } = %(
            (0..$!addr-bits).map: {
                self!bits2mask( $_ ) => $_
            } 
        );
    }

    %mask2pfx{ $!addr-bits }{ $mask }
}

method !reset {
    $!addr = $!mask = $!prefix-len = $!wildcard = $!first-addr = $!last-addr = 0;
    $!form = unknown;
}

method !recalc( @src ) {
    given @src[0] {

        self!reset;
        $!form = $_;

        when ip {
            #note "SRC VALUE:", $src.value;
            $!addr = @src[1];
            $!prefix-len = $!addr-bits;
            self!recalc-mask;
            self!recalc-wildcard;
            self!recalc-range;
        }

        when range {
            $!addr = $!first-addr = self.bitcap( @src[1]<first> );
            $!last-addr = self.bitcap( @src[1]<last> );
        }

        when cidr {
            #note "SRC:", $src;
            $!addr = @src[1]<ip>;
            $!prefix-len = self.bitcap( @src[1]<prefix-len> );
            self!recalc-mask;
            self!recalc-wildcard;
            self!recalc-range;
        }

        default {
            die "Possible internal failure: unknown IP form $_";
        }
    }
}

method !recalc-mask {
    $!mask = self!pfx2mask( $!prefix-len );
}

method !recalc-wildcard {
    $!wildcard = +^ self.bitcap( $!mask );
}

method !recalc-prefix-len { 
    $!prefix-len = self!mask2pfx( $!mask );
}

method !recalc-range {
    $!first-addr = self.bitcap( $!addr +& $!mask );
    $!last-addr = self.bitcap( $!first-addr + $!wildcard );
}

=begin pod

=NAME    IP::Addr::Handler
=AUTHOR  cpan:VRURG <vrurg@cpan.org>
=VERSION 0.0.0

=head1 Synopsis

=head1 Description

=head1 Examples

=head1 See also

=end pod

# vim: ft=perl6 et sw=4
