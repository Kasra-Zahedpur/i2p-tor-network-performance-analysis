#!/usr/bin/perl
#
# page_load_latency.pl
#
# Measures "average latency" - the time taken to load a full webpage,
# including embedded resources (images, CSS, JS), for a list of target
# URLs, over a chosen connection type (direct, Tor, or I2P).
#
# This approximates real-world browsing by fetching the HTML document
# and then fetching every same-page resource referenced by <img>, <script>,
# and <link> tags.
#
# Usage:
#   perl page_load_latency.pl --mode=tor --urls=urls.txt --out=results_page_tor.csv
#
# Requires:
#   LWP::UserAgent
#   LWP::Protocol::socks   (for Tor's SOCKS5 proxy support)
#   HTML::LinkExtor
#   Time::HiRes

use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use HTML::LinkExtor;
use Time::HiRes qw(gettimeofday tv_interval);
use URI;

my $mode     = 'direct';
my $url_file = 'urls.txt';
my $out_file = 'page_load_results.csv';
my $timeout  = 60;

GetOptions(
    "mode=s" => \$mode,
    "urls=s" => \$url_file,
    "out=s"  => \$out_file,
    "timeout=i" => \$timeout,
) or die "Usage: $0 --mode=direct|tor|i2p --urls=urls.txt --out=results.csv\n";

my $ua = LWP::UserAgent->new(timeout => $timeout);

if ($mode eq 'tor') {
    $ua->proxy(['http', 'https'], 'socks://127.0.0.1:9050');
}
elsif ($mode eq 'i2p') {
    $ua->proxy(['http'], 'http://127.0.0.1:4444');
}
elsif ($mode eq 'direct') {
    # no proxy
}
else {
    die "Unknown mode '$mode'. Use direct, tor, or i2p.\n";
}

open(my $urls_fh, '<', $url_file) or die "Cannot open $url_file: $!\n";
my @urls = <$urls_fh>;
chomp @urls;
close $urls_fh;
@urls = grep { $_ ne '' } @urls;

open(my $out_fh, '>', $out_file) or die "Cannot open $out_file: $!\n";
print $out_fh "url,mode,status,resource_count,total_bytes,latency_seconds\n";

print "Running full page-load latency test | mode=$mode | targets=" . scalar(@urls) . "\n";

foreach my $base_url (@urls) {
    my $t0 = [gettimeofday];
    my $total_bytes = 0;
    my $resource_count = 0;
    my $status = 'OK';

    my $response = $ua->get($base_url);

    if (!$response->is_success) {
        my $elapsed = tv_interval($t0);
        print $out_fh "\"$base_url\",$mode,FAIL(" . $response->status_line . "),0,0,$elapsed\n";
        printf "[FAIL] %-40s %.3fs\n", $base_url, $elapsed;
        next;
    }

    $total_bytes += length($response->decoded_content // '');

    # Extract linked resources (images, scripts, stylesheets) from the HTML
    my @links;
    my $extor = HTML::LinkExtor->new(sub {
        my ($tag, %attrs) = @_;
        push @links, $attrs{src} if $attrs{src};
        push @links, $attrs{href} if $attrs{href} && $tag eq 'link';
    });
    $extor->parse($response->decoded_content // '');

    my $base_uri = URI->new($base_url);

    foreach my $link (@links) {
        my $resource_uri = URI->new_abs($link, $base_uri);
        my $res = $ua->get($resource_uri->as_string);
        $resource_count++;
        $total_bytes += length($res->content // '') if $res->is_success;
    }

    my $elapsed = tv_interval($t0);
    printf "[%s] %-40s %d resources, %d bytes, %.3fs\n",
        $status, $base_url, $resource_count, $total_bytes, $elapsed;
    print $out_fh "\"$base_url\",$mode,$status,$resource_count,$total_bytes,$elapsed\n";
}

close $out_fh;
print "Done. Results written to $out_file\n";
