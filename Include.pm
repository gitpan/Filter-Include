{
  package Filter::Include;

  $VERSION = 1.1;

  use strict;
  use warnings;

  use IO::File;
  use Regexp::Common;
  use Carp 'croak';
  use File::Spec::Functions 'catfile';
  
  use Filter::Simple;

  FILTER {
    s{ ^ \043 ? \s* include \s+ (.+?) ;? $ }
     ( get_source($1) )gemx;
  };

  sub get_source {
    local $_ = shift;

    return "" unless defined;

    my $f;
    if(/^[q'"]/) {
      $f = eval;
      croak("Filter::Include - invalid quoted string $f: $@")
        if $@;
      $INC{$f} = $f;
    } else {
      $f = find_module_file($_);
    }

    my $fh = ( _isfh($f) ?
      $f
    :
      do { my $tmp = IO::File->new($f)
             or croak("Filter::Include - $! [$f]"); $tmp }
    );

    local $/;
    return join '', $fh->getlines;
  }

  use vars '%INC';
  sub find_module_file {
    my $pkg = $_[0];
  
    my($file, @dirs) = reverse split '::' => $pkg;
    my $path = catfile @dirs, "$file.pm";
  
    return $INC{$path}
      if exists $INC{$path} and defined $INC{$path};

    my $lib;

    for(@INC) {
      ## do references in @INC magic here ...
      if(ref $_) {
        my $ret = ( ref($_) eq 'CODE' ?
          $_->( $_, $path )
        :
          ref($_) eq 'ARRAY' ?
            $_->[0]->( $_, $path )
          :
            UNIVERSAL::can($_, 'INC') ?
              $_->INC( $path )
            :
              croak("Filter::Include - invalid reference $_")
        ) ;
          
        next
          unless defined $ret;
        
        croak("Filter::Handle - invalid \@INC subroutine return $ret")
          unless _isfh($ret);

        return $ret;
      }

      $lib = $_ and last
        if -f catfile($_, $path);
      
    }
    
    croak("Filter::Include - Can't locate $path in \@INC"
          . "(\@INC contains: @INC")
      unless defined $lib;
    
    $INC{$path} = catfile $lib, $path;
  }

  sub _isfh {
    no strict 'refs';
    return !!( ref $_[0] and (
         ( ref $_[0] eq 'GLOB' and defined *{$_[0]}{IO} )
      or ( UNIVERSAL::isa($_[0] => 'IO::Handle')        )
      or ( UNIVERSAL::can($_[0] => 'can')               )
    ) );
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

=item 1.1

Upgraded to a more respectable version number and added a more robust check for
the existence of a filehandle. Added tests for the coderef-type magic in C<@INC>
when performing a bareword include. Added I<Changes> section in POD.

=item 0.1

Initial release.

=back

=head1 AUTHOR

Dan Brook C<E<lt>broquaint@hotmail.comE<gt>>

=head1 SEE ALSO

C<C>, -P in L<perlrun>, L<Filter::Simple>

=cut
