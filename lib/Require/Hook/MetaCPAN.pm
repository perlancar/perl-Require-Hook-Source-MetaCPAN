package Require::Hook::MetaCPAN;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use HTTP::Tiny;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub INC {
    my ($self, $filename) = @_;

    (my $pkg = $filename) =~ s/\.pm$//; $pkg =~ s!/!::!g;

    my $url = "https://metacpan.org/pod/$pkg";
    my $resp = HTTP::Tiny->new->get($url);
    $resp->{success} or die "Can't load $filename: Can't retrieve $url: $resp->{status} - $resp->{reason}";

    $resp->{content} =~ m!href="(/source/[^/]+/[^/]+/[^"]*\.pm)"!
        or die "Can't load $filename: Can't find source URL in $url";

    $url = "https://metacpan.org$1";
    $resp = HTTP::Tiny->new->get($url);
    $resp->{success} or die "Can't load $filename: Can't retrieve $url: $resp->{status} - $resp->{reason}";

    eval $resp->{content};
    die if $@;
}

1;
# ABSTRACT: Load module source code from MetaCPAN

=head1 SYNOPSIS

 {
     local @INC = (Require::Hook::MetaCPAN->new, @INC);
     require Foo::Bar; # will be searched from MetaCPAN
     # ...
 }


=head1 DESCRIPTION


=head1 SEE ALSO

Other C<Require::Hook::*> modules.
