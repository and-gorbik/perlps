use 5.016;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

sub get_ppid {
	my $path = shift;
	open my($fd), $path or die "Can't read $path\n";
	my @lines = <$fd>;
	close $fd or die "Can't close $path\n";
	@lines = grep(/PPid:/, @lines);
	@lines = split("\t", $lines[0]);
	return $lines[1];
}

sub print_stat {
	my $pid = shift;
	my $fmt = shift;

	open my($fd), "/proc/$pid/status" or die "Can't read /proc/$pid/status\n";
	my @lines = <$fd>;
	close $fd or die "Can't close /proc/$pid/status\n";
	my %stat;
	for (qw(0 7 8)) {
		my @lst = split "\t", $lines[$_];
		$stat{$lst[0]} = $lst[1];
		chomp $stat{$lst[0]};
	}

	print "[$pid]" if $fmt =~ /p/;
    print " $stat{'Name:'}" if $fmt =~ /n/;
    print " uid=$stat{'Uid:'}" if $fmt =~ /u/;
	print " gid=$stat{'Gid:'}" if $fmt =~ /g/;
	print "\n";
}

sub traverse;
sub traverse {
	my ($pid, $depth, $map, $fmt) = @_;
	print "\t" for 1..$depth;
	print_stat $pid, $fmt;
	for (@{$map->{"$pid"}}) {
		traverse($_, $depth + 1, $map, $fmt);
	}
}

opendir my($dir), "/proc" or die "Can't open /proc\n";
my @lst = readdir $dir or die "Can't read from /proc\n";
my %map;
for (@lst) {
	next unless /^\d+$/;
	push @{$map{get_ppid("/proc/$_/status") + 0}}, $_ + 0;
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
	traverse(1, 0, \%map, $fmt);
} elsif ($pid) {
	traverse($pid, 0, \%map, $fmt);
} else {
	die "Usage: $0 --pid PID --format nug\nor\n$0 --all\n";
}