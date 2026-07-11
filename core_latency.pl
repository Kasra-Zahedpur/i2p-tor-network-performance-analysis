#!/usr/bin/perl
#
# core_latency.pl
#
# Measures "core latency" - the time taken to complete a single HTTP-GET
# request - for a list of target URLs, over a chosen connection type
# (direct, Tor, or I2P).
#
# Usage:
#   perl core_latency.pl --mode=tor --urls=urls.txt --out=results_core_tor.csv
#   perl core_latency.pl --mode=i2p --urls=urls.txt --out=results_core_i2p.csv
#   perl core_latency.pl --mode=direct --urls=urls.txt --out=results_core_direct.csv
#
# Requires:
#   LWP::UserAgent
#   LWP::Protocol::socks   (for Tor's SOCKS5 proxy support)
#   Time::HiRes
#
# Proxy defaults (edit to match your setup):
#   Tor:  SOCKS5 127.0.0.1:9050
#   I2P:  HTTP proxy 127.0.0.1:4444 (I2P HTTP outproxy tunnel)

use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use Time::HiRes qw(gettimeofday tv_interval);

my $mode     = 'direct';   # direct | tor | i2p
my $url_file = 'urls.txt';
my $out_file = 'core_latency_results.csv';
my $timeout  = 30;         # seconds

GetOptions(
    "mode=s" => \$mode,
    "urls=s" => \$url_file,
    "out=s"  => \$out_file,
    "timeout=i" => \$timeout,
) or die "Usage: $0 --mode=direct|tor|i2p --urls=urls.txt --out=results.csv\n";

# --- Build the user agent for the selected mode ---
my $ua = LWP::UserAgent->new(timeout => $timeout);

if ($mode eq 'tor') {
    # Tor SOCKS5 proxy (default port 9050)
    $ua->proxy(['http', 'https'], 'socks://127.0.0.1:9050');
}
elsif ($mode eq 'i2p') {
    # I2P HTTP outproxy tunnel (default port 4444)
    $ua->proxy(['http'], 'http://127.0.0.1:4444');
}
elsif ($mode eq 'direct') {
    # No proxy - direct connection
}
else {
    die "Unknown mode '$mode'. Use direct, tor, or i2p.\n";
}

# --- Load target URLs ---
open(my $urls_fh, '<', $url_file) or die "Cannot open $url_file: $!\n";
my @urls = <$urls_fh>;
chomp @urls;
close $urls_fh;
@urls = grep { $_ ne '' } @urls;

# --- Prepare output CSV ---
open(my $out_fh, '>', $out_file) or die "Cannot open $out_file: $!\n";
print $out_fh "url,mode,status,latency_seconds\n";

print "Running core latency test | mode=$mode | targets=" . scalar(@urls) . "\n";

foreach my $url (@urls) {
    my $t0 = [gettimeofday];
    my $response = $ua->get($url);
    my $elapsed = tv_interval($t0);

    my $status = $response->is_success ? 'OK' : 'FAIL(' . $response->status_line . ')';

    printf "[%s] %-40s %.3fs\n", $status, $url, $elapsed;
    print $out_fh "\"$url\",$mode,$status,$elapsed\n";
}

close $out_fh;
print "Done. Results written to $out_file\n";
