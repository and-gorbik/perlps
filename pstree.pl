use 5.016;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

sub get_stat {
	my $pid = shift;
	open my ($fd), "/proc/$pid/status" or die "Can't read /proc/$pid/status\n";
	my @lines = <$fd>;
	close $fd or die "Can't close /proc/$pid/status\n";
	my ($ppid, %stat);
	$lines[5] =~ /PPid:\t(\d+)/;
	$ppid = $1;
	for (qw(0 4 7 8)) {
		my @lst = split "\t", $lines[$_];
		$stat{$lst[0]} = $lst[1];
		chomp $stat{$lst[0]};
	}
	return $ppid, \%stat;
}

sub print_stat {
	my $stat = shift;
	my $fmt = shift;

	print "[$stat->{'Pid:'}]" if $fmt =~ /p/;
    print " $stat->{'Name:'}" if $fmt =~ /n/;
    print " uid=$stat->{'Uid:'}" if $fmt =~ /u/;
	print " gid=$stat->{'Gid:'}" if $fmt =~ /g/;
	print "\n";
}

sub traverse;
sub traverse {
	my ($pid, $depth, $relations, $stats, $fmt) = @_;
	print "\t" for 1..$depth;
	print_stat $stats->{$pid}, $fmt;
	for (@{$relations->{$pid}}) {
		traverse($_, $depth + 1, $relations, $stats, $fmt);
	}
}

opendir my($dir), "/proc" or die "Can't open /proc\n";
my @lst = readdir $dir or die "Can't read from /proc\n";
my %relations;
my %stats;
for (@lst) {
	next unless /^\d+$/;
	my ($ppid, $stat) = get_stat($_);
	$stats{$_} = $stat;
	push @{$relations{$ppid + 0}}, $_ + 0;
}
closedir $dir or die "Can't close /proc\n";

my $pid;
my $fmt;
my $all;
GetOptions(
	'all|a' => \$all,
	'pid|p=s' => \$pid,
	'format|f=s' => \$fmt,
) or die "Usage: $0 --pid PID --format nug\nor\n$0 --all\n";

$fmt .= "p";
if ($all) {
	traverse(1, 0, \%relations, \%stats, $fmt);
} elsif ($pid) {
	traverse($pid, 0, \%relations, \%stats, $fmt);
} else {
	die "Usage: $0 --pid PID --format nug\nor\n$0 --all\n";
}