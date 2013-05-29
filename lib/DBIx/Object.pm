package DBIx::Object;

use warnings;
use strict;
use B;
use B::Deparse;
use DBIx::Connector;

=head1 NAME

DBIx::Object - The great new DBIx::Object!

=head1 VERSION

Version 0.01

=cut

use version; our $VERSION = version->declare('v0.01.00');

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBIx::Object;

    my $foo = DBIx::Object->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 processRef
  Takes an object and flattens it into an array

    {address => $addr,
     blessed => $blessed,
     type => $type1,
     child_type => $ref->{child_type},
     child_name => $ref->{child_name},
     parent => $ref->{parent}};

=cut

my $num_id_digits = 10;
my $fmtstr = '%0' . $num_id_digits . 'x';

sub processRef {
  my @queue = ({ref => \$_[0],
                parent => '',
                parent_type => '',
                child_type => '',
                child_name => ''});

  # tmap shamelessly procured from JSON::PP
  my %tmap = qw(
      B::NULL   SCALAR
      B::HV     HASH
      B::AV     ARRAY
      B::CV     CODE
      B::IO     IO
      B::GV     GLOB
      B::REGEXP REGEXP
  );

  my @result;
  my $seen = {};
  my $circcount = 0;
  my $deparse = B::Deparse->new();

  while (@queue) {
    my $ref = shift @queue;
    my $type1 = '';
    my $type2 = ref ${$ref->{ref}};

    if (length($type2)) {
      my $t = ref(B::svref_2object(${$ref->{ref}}));
      if (exists $tmap{$t}) {
        $type1 = $tmap{$t};
      } elsif (length(ref $${$ref->{ref}})) {
        $type1 = 'REF';
      } else {
        $type1 = 'SCALAR';
      }
    } else {
      $type1 = 'scalarval';
    }

    my $blessed = ($type1 ne $type2) ? $type2 : '';

    # TODO: Check this, not sure if it is right
    my $addr = $type2 ? 0 + ${$ref->{ref}} : 0 + \${$ref->{ref}};

    my $value;

    if ($type1 eq 'HASH') {
      # queue up children of hash, this is just the keys, values will be children of the key
      if (!exists $seen->{$addr}) {
        foreach my $key (keys %{${$ref->{ref}}}) {
          push @queue, {ref => \${$ref->{ref}}->{$key},
                        parent => $addr,
                        parent_type => 'hash',
                        child_type => 'key',
                        child_name => $key};
        }
      }
    } elsif ($type1 eq 'ARRAY') {
      # queue up children of the array, this is just the indexes, values will be children of the index
      if (!exists $seen->{$addr}) {
        my $length = scalar @{${$ref->{ref}}} - 1;
        foreach my $index (0 .. $length) {
          push @queue, {ref => \${$ref->{ref}}->[$index],
                        parent => $addr,
                        parent_type => 'array',
                        child_type => 'index',
                        child_name => $index};
        }
      }
    } elsif ($type1 eq 'REF') {
      # this is a ref to another reference
      if (!exists $seen->{$addr}) {
          push @queue, {ref => ${$ref->{ref}},
                        parent => $addr,
                        parent_type => 'ref',
                        child_type => 'ref',
                        child_name => ''};
      } else {
        $value = $seen->{${$ref->{ref}}};
      }
    } elsif ($type1 eq 'SCALAR' || $type1 eq 'GLOB') {
      # this is a ref to a scalar or glob
      if (!exists $seen->{$addr}) {
        push @queue, {ref => ${$ref->{ref}},
                      parent => $addr,
                      parent_type => 'scalarref',
                      child_type => 'scalarref',
                      child_name => ''};
      }
    } elsif ($type1 eq 'scalarval' || $type1 eq 'REGEXP') {
      # store the value
      $value = ${$ref->{ref}};
    } elsif ($type1 eq 'CODE') {
      $value = $deparse->coderef2text(${$ref->{ref}});
    } else {
      warn "Unhandled: type1 = $type1\n" .
           "           type2 = $type2\n" .
           "         blessed = $blessed\n" .
           "         address = $addr\n" .
           "           value => ${$ref->{ref}}\n";
      next;
    }

    # detect circular references
    my $circular_ref = 0;
    my $obj_id;
    if ($seen->{$addr}) {
      $circular_ref = 1;
      $obj_id = $seen->{$addr . '_' . $circcount} = getNextId();
    } else {
      $obj_id = $seen->{$addr} = getNextId();
    }

    my $parent_id = $ref->{parent} ? sprintf ($fmtstr, $seen->{$ref->{parent}}) : sprintf ($fmtstr, 0);

    my $obj = {
      #address => $addr,
      parent_id => $parent_id,
      id => $obj_id,
      circ_id => $circular_ref ? $seen->{$addr} : undef,
      blessed => $blessed,
      type => $type1,
      child_type => $ref->{child_type},
      child_name => $ref->{child_name},
      #parent_address => $ref->{parent},
    };

    $obj->{value} = $value if defined $value;

    if ($circular_ref) {
      $circcount++;
    }

    push @result, $obj;
  }

  return \@result;
}

=head2 getNextId

=cut

my $id = 0;
sub getNextId {
  return sprintf ($fmtstr, ++$id);
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Desmond Daignault, C<< <nawglan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbi-object at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx::Object>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Object


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx::Object>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx::Object>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx::Object>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx::Object>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2013 Desmond Daignault, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of DBIx::Object

