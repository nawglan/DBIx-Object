package DBIx::Object;

use warnings;
use strict;
use B;

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
     child_key => $ref->{child_key},
     parent => $ref->{parent}};

=cut

sub processRef {
  my @queue = ({ref => \$_[0],
                parent => '',
                parent_type => '',
                child_type => '',
                child_key => ''});
  my @result;
  my $seen = {};

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
      if (!$seen->{$addr}) {
        foreach my $key (sort keys %{${$ref->{ref}}}) {
          push @queue, {ref => \${$ref->{ref}}->{$key},
                        parent => $addr,
                        parent_type => 'hash',
                        child_type => 'key',
                        child_key => $key};
        }
      }
    } elsif ($type1 eq 'ARRAY') {
      if (!$seen->{$addr}) {
        my $length = scalar @{${$ref->{ref}}} - 1;
        foreach my $index (0 .. $length) {
          push @queue, {ref => \${$ref->{ref}}->[$index],
                        parent => $addr,
                        parent_type => 'array',
                        child_type => 'index',
                        child_key => $index};
        }
      }
    } elsif ($type1 eq 'REF') {
      if (!$seen->{${$ref->{ref}}}) {
        push @queue, {ref => ${$ref->{ref}},
                      parent => $addr,
                      parent_type => 'ref',
                      child_type => 'ref',
                      child_key => ''};
      }
      $value = \${$ref->{ref}} + 0;
    } elsif ($type1 eq 'SCALAR') {
      if (!$seen->{${$ref->{ref}}}) {
        push @queue, {ref => ${$ref->{ref}},
                      parent => $addr,
                      parent_type => 'scalarref',
                      child_type => 'scalarref',
                      child_key => ''};
      }
      $value = \${$ref->{ref}} + 0;
    } elsif ($type1 eq 'scalarval' || $type1 eq 'REGEXP') {
      $value = ${$ref->{ref}};
    } else {
      warn "Unhandled: type1 = $type1\n" .
           "           type2 = $type2\n" .
           "         blessed = $blessed\n" .
           "         address = $addr\n" .
           "           value => ${$ref->{ref}}\n";
      next;
    }


    # TODO: investigate why this happens
    #       it may be needed due to bug in getting $addr
    next if $addr == $ref->{parent};

    my $obj = {address => $addr,
               blessed => $blessed,
               type => $type1,
               child_type => $ref->{child_type},
               child_key => $ref->{child_key},
               parent => $ref->{parent}};

    $obj->{value} = $value if defined $value;

    push @result, $obj;

    $seen->{$addr} = 1;
  }

  return \@result;
}


=head2 function1

=cut

sub function1 {
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

