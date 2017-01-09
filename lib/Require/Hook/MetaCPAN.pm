package Require::Hook::MetaCPAN;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use HTTP::Tiny;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub Require::Hook::MetaCPAN::INC {
    my ($self, $filename) = @_;

    (my $pkg = $filename) =~ s/\.pm$//; $pkg =~ s!/!::!g;

    my $url = "https://metacpan.org/pod/$pkg";
    my $resp = HTTP::Tiny->new->get($url);
    $resp->{success} or do {
        die "Can't load $filename: Can't retrieve $url: $resp->{status} - $resp->{reason}" if $self->{die};
        return undef;
    };

    $resp->{content} =~ m!href="(/source/[^/]+/[^/]+/[^"]*\.pm)"! or do {
        die "Can't load $filename: Can't find source URL in $url" if $self->{die};
        return undef;
    };

    $url = "https://fastapi.metacpan.org$1";
    $resp = HTTP::Tiny->new->get($url);
    $resp->{success} or do {
        die "Can't load $filename: Can't retrieve $url: $resp->{status} - $resp->{reason}" if $self->{die};
        return undef;
    };

    \($resp->{content});
}

1;
# ABSTRACT: Load module source code from MetaCPAN

=for Pod::Coverage .+

=head1 SYNOPSIS

 {
     local @INC = (@INC, Require::Hook::MetaCPAN->new);
     require Foo::Bar; # will be searched from MetaCPAN
     # ...
 }


=head1 DESCRIPTION


=head1 METHODS

=head2 new([ %args ]) => obj

Constructor. Known arguments:

=over

=item * die => bool (default: 1)

If set to 1 (the default) will die if module source code can't be fetched (e.g.
the module does not exist on CPAN, or there is network error). If set to 0, will
simply decline so C<require()> will try the next entry in C<@INC>.

=back


=head1 SEE ALSO

Other C<Require::Hook::*> modules.
