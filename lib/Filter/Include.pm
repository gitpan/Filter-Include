{
  package Filter::Include;

  $VERSION  = 1.4;

  use strict;
  use warnings;

  use IO::File;
  use Regexp::Common;
  use Carp 'croak';
  use File::Spec::Functions 'catfile';
  use Module::Locate qw/ acts_like_fh locate /;
  
  use Filter::Simple;

  FILTER { $_ = _filter($_) };

  use vars '$MATCH_RE';
  $MATCH_RE = qr{ ^ \043 ? \s* include \s+ (.+?) ;? $ }xm;

  sub _filter {
    local $_ = shift;

    s{$MATCH_RE}(source($1))ge;

    my($i, $line) = 0;
    $line = ( caller $i++ )[2]
      while caller $i;

    return "\n#line $line\n"
         . $_
         . "\n#line " . ( $line + tr[\n][\n] ) . "\n";
  }

  sub source {
    local $_ = shift;

    return "" unless defined;

    my $f;
    if(/^[q'"]/) {
      $f = eval;
      croak("Filter::Include - invalid quoted string $f: $@")
        if $@;
      $INC{$f} = $f;
    } else {
      $f = locate($_);
    }

    my $fh = ( acts_like_fh($f) ?
      $f
    :
      do { my $tmp = IO::File->new($f)
             or croak("Filter::Include - $! [$f]"); $tmp }
    );

    my $data = do { local $/; <$fh> };
    
    $data = _filter($data)
      if $data =~ $MATCH_RE;

    return $data;
  }

}

q. The End.

__END__

=pod

=head1 NAME

Filter::Include - Emulate the behaviour of the C preprocessor's C<#include>

=head1 SYNOPSIS

  use Filter::Include;
  
  include Foo::Bar;
  include "somefile.pl";

  ## or

  #include Some::Class
  #include "little/library.pl"

=head1 DESCRIPTION

Take the C<#include> preproccesor directive from C<C>, stir in some C<perl>
semantics and we have this module. Only one keyword is used, C<include>, which
is really just a processor directive for the filter, which indicates the file to
be included. The argument supplied to C<include> will be handled like it would
by C<require> and C<use> with the traversing of C<@INC> and the populating of
C<%INC> and the like.

=head1 #include

For those not clued in on what C<C>'s C<#include> processor directive does this
section shall explain briefly its purpose, and why it's being emulated here.

=over 4

=item I<What>

When the C<C> preprocessor sees the C<#include> directive, it will include the
given file straight into the source. It is syntax-checked and dumped where
C<#include> previously stood, so becomes part of the source of the given file
when it is compiled.

=item I<Why>

Basically the 'why' of this module is that I'd seen several requests on Perl
Monks, the one which really inspired this was

L<http://www.perlmonks.org/index.pl?node_id=254283>

So I figured other people that haven't posted to Perl Monks may want it, so here
it is in all its filtering glory.

=back

=head1 Changes

=over 4

=item 1.4

=over 8

=item *

Moved out the functionality for locating modules to L<Module::Locate>.

=item *

Thanks to the tip off from an Anonymous Monk at

L<http://www.perlmonks.org/index.pl?node_id=302235|Re: Re: #include files>

the line numbering is now set accordingly.

=back

=item 1.3

=over 8

=item *

recursively processes the 'include' directive

=item *

moved over to Module::Build, hurrah!

=back

=item 1.2

=over 8

=item *

Fixed 2 bugs - forgot to C<reverse> C<@dirs> in C<find_module_file> and
C<_isfh> now checks if an object can C<getlines> (not C<can> which is silly).

=back

=item 1.1

=over 8

=item *

Upgraded to a more respectable version number

=item * 

Added a more robust check for the existence of a filehandle

=item *

Added tests for the coderef-type magic in C<@INC> when performing a bareword
include.

=item *

Added I<Changes> section in POD

=back

=item 0.1

=over 8

=item *

Initial release

=back

=back

=head1 AUTHOR

Dan Brook C<E<lt>broquaint@hotmail.comE<gt>>

=head1 SEE ALSO

C<C>, -P in L<perlrun>, L<Filter::Simple>

=cut
