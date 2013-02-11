#!/bin/sh

egrep '^\s+(Create|Read|Update|Delete)' "$@" | \
	awk '{print $1}' | \
	perl -ne 'chomp; print "=item \$server->$_(...)\n\n...desc...\n\n=cut\n\nsub $_ {\n    my (\$self, \$cb, \$q) = \@_;\n\n    \$self->Error(\$cb, \"Not Implemented\");\n}\n\n";'

