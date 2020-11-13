package Require::Hook::Source::MetaCPAN;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

# preload to avoid deep recursion in our INC
use HTTP::Tiny;
use IO::Socket::SSL;
use URI::URL;
# to trigger lazy loading
{ my $url = URI::URL->new("/foo", "https://example.com")->abs }

sub new {
    my ($class, %args) = @_;
    $args{die} = 1 unless defined $args{die};
    bless \%args, $class;
}

sub Require::Hook::Source::MetaCPAN::INC {
    my ($self, $filename) = @_;

    (my $pkg = $filename) =~ s/\.pm$//; $pkg =~ s!/!::!g;

    my $url = "https://metacpan.org/pod/$pkg";
    my $resp = HTTP::Tiny->new->get($url);
    $resp->{success} or do {
        die "Can't load $filename: Can't retrieve $url: $resp->{status} - $resp->{reason}" if $self->{die};
        return undef;
    };

    $resp->{content} =~ m!href="(.+?\?raw=1)"! or do {
        die "Can't load $filename: Can't find source URL in $url" if $self->{die};
        return undef;
    };

    $url = URI::URL->new($1, $url)->abs . "";
    log_trace "[RH:Source::MetaCPAN] Retrieving module source for $filename from $url ...";
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
     local @INC = (@INC, Require::Hook::Source::MetaCPAN->new);
     require Foo::Bar; # will be searched from MetaCPAN
     # ...
 }


=head1 DESCRIPTION

Warning: this is most probably not suitable for use in production or real-world
code.


=head1 METHODS

=head2 new([ %args ]) => obj

Constructor. Known arguments:

=over

=item * die

Bool. Default is true.

If set to 1 (the default) will die if module source code can't be fetched (e.g.
the module does not exist on CPAN, or there is network error). If set to 0, will
simply decline so C<require()> will try the next entry in C<@INC>.

=back


=head1 SEE ALSO

Other C<Require::Hook::*> modules.

L<Require::HookChain::source::metacpan> uses us.
