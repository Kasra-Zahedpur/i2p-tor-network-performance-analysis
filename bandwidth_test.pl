#!/usr/bin/perl
#
# bandwidth_test.pl
#
# Measures download bandwidth by fetching a set of test files of
# increasing size (e.g. 50 KB - 1 MB) over a chosen connection type
# (direct, Tor, or I2P) and computing throughput in kB/s.
#
# Target files should be hosted somewhere reachable via all three test
# modes (direct, Tor .onion or clearnet mirror, I2P eepsite or outproxy
# target) - list them in a config file with one "size,url" pair per line.
#
# Example bandwidth_targets.txt:
#   50KB,http://example.com/testfiles/50kb.bin
#   100KB,http://example.com/testfiles/100kb.bin
#   500KB,http://example.com/testfiles/500kb.bin
#   1MB,http://example.com/testfiles/1mb.bin
#
# Usage:
#   perl bandwidth_test.pl --mode=i2p --targets=bandwidth_targets.txt --out=bandwidth_i2p.csv
#
# Requires:
#   LWP::UserAgent
#   LWP::Protocol::socks   (for Tor's SOCKS5 proxy support)
#   Time::HiRes

use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use Time::HiRes qw(gettimeofday tv_interval);

my $mode        = 'direct';
my $target_file = 'bandwidth_targets.txt';
my $out_file    = 'bandwidth_results.csv';
my $timeout     = 120;
my $repeats     = 1;   # number of times to repeat each download for averaging

GetOptions(
    "mode=s"     => \$mode,
    "targets=s"  => \$target_file,
    "out=s"      => \$out_file,
    "timeout=i"  => \$timeout,
    "repeats=i"  => \$repeats,
) or die "Usage: $0 --mode=direct|tor|i2p --targets=file.txt --out=results.csv [--repeats=N]\n";

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

open(my $targets_fh, '<', $target_file) or die "Cannot open $target_file: $!\n";
my @targets;
while (my $line = <$targets_fh>) {
    chomp $line;
    next if $line eq '' || $line =~ /^#/;
    my ($label, $url) = split(/,/, $line, 2);
    push @targets, { label => $label, url => $url };
}
close $targets_fh;

open(my $out_fh, '>', $out_file) or die "Cannot open $out_file: $!\n";
print $out_fh "label,url,mode,attempt,status,bytes,seconds,kb_per_sec\n";

print "Running bandwidth test | mode=$mode | targets=" . scalar(@targets) . " | repeats=$repeats\n";

foreach my $target (@targets) {
    my ($label, $url) = ($target->{label}, $target->{url});

    for my $attempt (1 .. $repeats) {
        my $t0 = [gettimeofday];
        my $response = $ua->get($url);
        my $elapsed = tv_interval($t0);

        if ($response->is_success) {
            my $bytes = length($response->content);
            my $kbps = $elapsed > 0 ? ($bytes / 1024) / $elapsed : 0;

            printf "[OK]   %-8s attempt %d: %d bytes in %.3fs -> %.2f kB/s\n",
                $label, $attempt, $bytes, $elapsed, $kbps;
            print $out_fh "$label,\"$url\",$mode,$attempt,OK,$bytes,$elapsed,$kbps\n";
        }
        else {
            printf "[FAIL] %-8s attempt %d: %s\n", $label, $attempt, $response->status_line;
            print $out_fh "$label,\"$url\",$mode,$attempt,FAIL(" . $response->status_line . "),0,$elapsed,0\n";
        }
    }
}

close $out_fh;
print "Done. Results written to $out_file\n";
