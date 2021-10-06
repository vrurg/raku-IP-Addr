NAME
====

IP::Addr::Const

DESCRIPTION
===========

This module contains common definitions for other modules of IP::Addr family.

Constants And Enums
-------------------

### enum SCOPE

Defines scopes of reserved IP blocks.

<table class="pod-table">
<thead><tr>
<th>Scope</th> <th>Version</th>
</tr></thead>
<tbody>
<tr> <td>undetermined</td> <td>4,6</td> </tr> <tr> <td>documentation</td> <td>4,6</td> </tr> <tr> <td>host</td> <td>4,6</td> </tr> <tr> <td>private</td> <td>4,6</td> </tr> <tr> <td>public</td> <td>4,6</td> </tr> <tr> <td>software</td> <td>4,6</td> </tr> <tr> <td>subnet</td> <td>4,6</td> </tr> <tr> <td>internet</td> <td>6</td> </tr> <tr> <td>link</td> <td>6</td> </tr> <tr> <td>routing</td> <td>6</td> </tr>
</tbody>
</table>

### enum IP-FORM

Forms of IP address objects:

  * unknown

  * ip

  * cidr

  * range

Exceptions
----------

### X::IPAddr::TypeCheck

Raised when operation is performed on two objects of incompatible versions.

### X::IPAddr::BadMappedV6

Raised when IPv6 is in IPv4 mapped format but incorrectly formed.

See also
========

IP::Addr

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

