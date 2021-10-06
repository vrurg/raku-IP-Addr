NAME
====

IP::Addr::Handler

DESCRIPTION
===========

Base role for IP version classes.

Most of the methods provided by this role are documented in _HANDLER METHODS_ section of `IP::Addr` documentation.

Attributes
----------

### `Str $.source`

If object was initialized with a string then this attribute contains that string. Propagaded into new objects created using `IP::Addr` `dup` and `dup-handler` methods. In other words, most of the methods/operators returning a new object would propagade this attribute into it.

### `IP-FORM $.form`

Form of the current IP object. See `IP::Addr::Common` and `IP::Addr`.

### `Int $.prefix-len`

IP address prefix length. For ranges it would be 0 and for single IPs it would be equal to the result of `addr-len` method.

Required Methods
----------------

### method prefix

```raku
method prefix() returns Mu
```

Must return a string containing formatted IP address with prefix length.

### method version

```raku
method version() returns Mu
```

Must return a number representing IP object version. I.e. I<4> for IPv4 and I<6> for IPv6.

### method ip-classes

```raku
method ip-classes() returns Mu
```

Described in IP::Addr documentation

### method int2str

```raku
method int2str(
    Int $
) returns Mu
```

Formats an integer representation of IP address into string

### method addr-len

```raku
method addr-len() returns Mu
```

Returns number of bits in address

### method n-tets

```raku
method n-tets() returns Mu
```

Returns number of octets/hextets in address

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

SEE ALSO
========

IP::Addr, IP::Addr::v4, IP::Addr::v6

