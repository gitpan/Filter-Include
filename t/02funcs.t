#!/usr/bin/perl

use Test::More tests => 19;
use vars '$pkg';

use IO::File;
use File::Spec;

BEGIN { 
	$pkg = 'Filter::Include';
	# no. 1
	use_ok($pkg);
}

use strict;
eval q(use warnings) or local $^W = 1;

my $testfile = File::Spec->catfile(t => 'sample.pl');

# no. 2
ok( my $code = Filter::Include::get_source(qq["$testfile"]),
    "got source ok" );

# no. 3
eval $code;

# no. 4
ok( 'a string' eq $::sample_test, 'the $::sample_test variable was set');

unshift @INC => '.';
my $file = Filter::Include::find_module_file("t::sample_test");

# no. 5
ok( -f $file, "found the file ok");

# no. 6
eval Filter::Include::get_source('t::sample_test');

# no. 7
ok(t::sample_test->VERSION > 0, "version defined in test module");

use vars '$currtest';
my $module = 't::sample_coderefs';
{
  unshift @INC => \&coderef_test::get_fh;
  my $coderef_file = Filter::Include::find_module_file($module);

  # no. 8
  isa_ok($coderef_file, 'IO::File');

  $currtest = 'coderef test';
  # no. 9, 10, 11
  eval Filter::Include::get_source($module);
  ok($@ eq '', 'nothing went wrong in the eval');
  ok($sample_coderefs::incr == 1, '$samle_coderefs::incr was incremented');
}

{
  my @inc_array = shift @INC;
  unshift @INC => \@inc_array;

  my $coderef_file = Filter::Include::find_module_file($module);

  # no. 12
  isa_ok($coderef_file, 'IO::File');

  $currtest = 'array with coderef test';
  # no. 13, 14, 15
  eval Filter::Include::get_source($module);
  ok($@ eq '', 'nothing went wrong in the eval');
  ok($sample_coderefs::incr == 2, '$samle_coderefs::incr was incremented');
}

{
  my $scr_obj = bless shift @INC, 'sample_coderefs';
  unshift @INC => $scr_obj;

  my $coderef_file = Filter::Include::find_module_file($module);

  # no. 16
  isa_ok($coderef_file, 'IO::File');

  $currtest = 'object with INC method test';
  # no. 17, 18, 19
  eval Filter::Include::get_source($module);
  ok($@ eq '', 'nothing went wrong in the eval');
  ok($sample_coderefs::incr == 3, '$::samle_coderefs was incremented');
}

sub coderef_test::get_fh {
  my $file = pop;
  my $fh   = IO::File->new($file) or die("coderef_test(): $! [$file]");
  return $fh
}
