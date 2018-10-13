#! /usr/bin/env false

use v6.c;

unit module IP::Addr::Const;

# routing and link are IPv6 specific
# internet, documentation, software, host, private valid for both v4 and v6
# public is a custom class for anything not been reserved
enum SCOPE is export «:undetermined(-1) :public(0) software private host subnet documentation internet routing link»;

enum IP-FORM is export «:unknown(0) ip cidr range»;

=begin pod

=NAME    IP::Addr::Const
=AUTHOR  cpan:VRURG <vrurg@cpan.org>
=VERSION 0.0.0

=head1 Synopsis

=head1 Description

=head1 Examples

=head1 See also

=end pod

# vim: ft=perl6 et sw=4
