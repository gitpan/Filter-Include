{
  package Filter::Include;

  $VERSION  = '1.5';

  use strict;
  # XXX - this is dropped for the sake of pre-5.6 perls
  # use warnings;

  use Carp 'croak';
  use Scalar::Util 'reftype';
  use File::Spec::Functions 'catfile';
  use Module::Locate Global => 1, 'get_source';

  use vars '$MATCH_RE';
  $MATCH_RE = qr{ ^ \043 ? \s* include \s+ (.+?) ;? $ }xm;

  sub import {
    my( $called_by, %args ) = @_;

    for(grep exists $args{$_}, qw/ pre post /) {
      my $handler = $_ . '_expand';

      croak "The $handler handler must be a CODE reference, was given: " .
            ref($args{$_}) || $args{$_}
        if !ref $args{$_} or reftype $args{$_} ne 'CODE';

      no strict 'refs';
      *$handler = delete $args{$_};
    }
  }

  use vars '$LINE';
  sub _filter {
    local $_ = shift;

    s{$MATCH_RE}{
      my $include = $1;
      
      ## Only do this the first time.
      $LINE = _find_initial_lineno($_, $&)
        unless defined $LINE;
      
      _source($include);
    }ge;

    return $_
         . "\n#line " . ( $LINE += tr[\n][\n] + 1 ) . "\n";
  }

  ## work magic to find the first line number so #line declarations are correct
  sub _find_initial_lineno {
    my($src, $match) = @_;
    
    ## Find the number of lines before the $match in $src.
    my $include_at = () = substr($src, 0, index($src, $match)) =~ /^(.?)/mg;

    my($i, $called_from) = 0;
    $called_from = ( caller $i++ )[2]
      while caller $i;

    ## We need the caller's line num in addition to the number of lines before
    ## the match substring as Filter::Simple only filters after it is called.
    return $include_at + $called_from;
  }
  
  sub _source {
    local $_ = shift;

    return ''
      unless defined;

    my $include;
    my $data = do {
      local $@;
      $include = $_ =~ $Module::Locate::PkgRe ? $_ : eval $_;
      croak("Filter::Include - couldn't get a meaningful filename from: '$_'")
        if not defined $include or $@;
        
      get_source( $include );
    };

    $data = _expand_source($include, $data);

    return $data;
  }

  sub _expand_source {
    my($include, $data) = @_;

    pre_expand( $include, $data )
      if defined &pre_expand;

    $data = _filter($data)
      if $data =~ $MATCH_RE;

    post_expand( $include, $data )
      if defined &post_expand;

    return $data;
  }
  
  use Filter::Simple;
  FILTER { $_ = _filter($_) };

}

q. The End.

__END__

=pod

=head1 NAME

Filter::Include - Emulate the behaviour of the C<#include> directive

=head1 SYNOPSIS

  use Filter::Include;
  
  include Foo::Bar;
  include "somefile.pl";

  ## or the C preprocessor directive style:

  #include Some::Class
  #include "little/library.pl"

=head1 DESCRIPTION

Take the C<#include> preproccesor directive from C<C>, stir in some C<perl>
semantics and we have this module. Only one keyword is used, C<include>, which
is really just a processor directive for the filter, which indicates the file to
be included. The argument supplied to C<include> will be handled like it would
by C<require> and C<use> so C<@INC> is searched accordingly and C<%INC> is
populated.

=head1 #include

For those who have not come across C<C>'s C<#include> preprocessor directive
this section shall explain briefly what it does, and why it's being emulated here.

=over 4

=item I<What>

When the C<C> preprocessor sees the C<#include> directive, it will include the
given file straight into the source. The file is dumped directly to where
C<#include> previously stood, so becomes part of the source of the given file
when it is compiled. This is used primarily for C<C>'s header files so function
and data predeclarations can be nicely separated out.

=item I<Why>

The I<why> of this module is that I'd seen several requests on
L<Perl Monks|http:/www.perlmonks.org>, but the one inparticular that inspired
was this:

L<http://www.perlmonks.org/index.pl?node_id=254283>

=back

=head1 HANDLERS

If C<Filter::Include> is called with the C<pre> and/or C<post> arguments their
associated values can be installed as handlers e.g

  use Filter::Include pre => sub {
                        my $include = shift;
                        print "Including $inc\n";
                      };

This will install the C<pre> handler which is called before the include is
parsed for further includes. If a C<post> handler is passed in then it will be
called after the include has been parsed and updated.

Both handlers take two positional arguments - the current include e.g
C<library.pl> or C<Legacy::Code>, and the source of the include which in the
case of the C<pre> handler is the source before it is parsed and in the case of
the C<post> handler it is the source after it has been parsed and updated as
appropriate.

These handlers are going to be most handy for debugging purposes but could also
be useful for tracking module usage.

=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 SEE ALSO

C<C>, -P in L<perlrun>, L<Filter::Simple>, L<Filter::Macro>

=cut
