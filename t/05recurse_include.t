
#!/usr/bin/perl

use Test::More tests => 4;
use vars '$pkg';

use IO::File;
use File::Spec;

use strict;
use Filter::Include;

# no. 1, 2
#include 't/sample_recurse.pl';

# no. 3, 4
ok($::sample_test    eq 'a string',      '$::sample_test is set');
ok($::sample_recurse eq 'I am a string', '$::sample_recurse is set');
