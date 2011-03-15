#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package Method::Utils;

use strict;
use warnings;

our $VERSION = '0.01_001';

use Exporter 'import';

our @EXPORT_OK = qw(
   possibly

   inwardly
   outwardly
);

=head1 NAME

C<Method::Utils> - functional-style utilities for method calls

=cut

=head1 FUNCTIONS

All of the following functions are intended to be used as method call
modifiers. That is, they return a C<SCALAR> reference to a C<CODE> reference
which allows them to be used in the following syntax

 $ball->${possibly "bounce"}( "10 metres" );

Since the returned double-reference can be dereferenced by C<${ }> to obtain
the C<CODE> reference directly, it can be used to create new methods. For
example:

 *bounce_if_you_can = ${possibly "bounce"};

The following utilities are described from the perspective of directly
invoking the returned code, as in the first example.

=cut

=head2 possibly $method

Invokes the named method on the object or class and return what it returned,
if it exists. If the method does not exist, returns C<undef> in scalar context
or the empty list in list context.

=cut

sub possibly
{
   my $mth = shift;
   \sub {
      my $self = shift;
      return unless $self->can( $mth );
      $self->$mth( @_ );
   };
}

=head2 inwardly $method

=head2 outwardly $method

Invokes the named method on the object or class for I<every> class that
provides such a method in the C<@ISA> heirarchy, not just the first one that
is found. C<inwardly> starts its search at the topmost class; that is, the
class name (or type of the object) provided, and starts searching down towards
superclasses. C<outwardly> starts its search at the base-most superclass,
searching upward before finally ending at the topmost class.

In the case of multiple inheritance, subclasses are always searched in the
order that they appear in the C<@ISA> array.

In the case that multiple inheritance brings the same subclass in more than
once, they are arranged into a consistent order. That is, C<inwardly> ensures
that no superclass will be searched until every subclass that uses it has been
searched first; while C<outwardly> ensures that no superclass will be searched
before every subclass that it uses has been searched already.

=cut

sub inwardly
{
   my $mth = shift;
   \sub {
      my $self = shift;

      my @packages;
      my @queue = ref $self || $self;
      my %seen;
      while( @queue ) {
         my $class = shift @queue;
         push @packages, $class;
         if( defined $seen{$class} ) {
            undef $packages[$seen{$class}];
            $seen{$class} = $#packages;
            next;
         }
         else {
            $seen{$class} = $#packages;
            unshift @queue, do { no strict 'refs'; @{$class."::ISA"} };
         }
      }

      for my $class ( @packages ) {
         no strict 'refs';
         defined $class or next;
         defined &{$class."::$mth"} or next;
         &{$class."::$mth"}( $self, @_ );
      }
   }
}

sub outwardly
{
   my $mth = shift;
   \sub {
      my $self = shift;

      my @packages;
      my @queue = ref $self || $self;
      my %seen;
      while( @queue ) {
         my $class = shift @queue;
         push @packages, $class;
         if( defined $seen{$class} ) {
            undef $packages[$seen{$class}];
            $seen{$class} = $#packages;
            next;
         }
         else {
            $seen{$class} = $#packages;
            unshift @queue, reverse do { no strict 'refs'; @{$class."::ISA"} };
         }
      }

      for my $class ( reverse @packages ) {
         no strict 'refs';
         defined $class or next;
         defined &{$class."::$mth"} or next;
         &{$class."::$mth"}( $self, @_ );
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
