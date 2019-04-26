use 5.016;
use warnings;

sub get_ppid {
	my $path = shift;
	$path .= "/status";
	open my($fd), $path or die "Can't read $path\n";
	my @lines = <$fd>;
	close $fd or die "Can't close $path\n";
	@lines = grep(/PPid:/, @lines);
	@lines = split("\t", $lines[0]);
	return $lines[1];
}

opendir my($dir), "/proc" or die "Can't open /proc\n";
my @lst = readdir $dir or die "Can't read from /proc\n";
my %map;
for (@lst) {
	next unless /^\d+$/;
	push @{$map{get_ppid("/proc/$_") + 0}}, $_ + 0;
}
closedir $dir or die "Can't close /proc\n";

sub traverse;
sub traverse {
	my $ppid = shift;
	my $depth = shift;
	print "\t" for 1..$depth;
	print "$ppid\n";
	if (defined $map{"$ppid"}) {
		for (@{$map{"$ppid"}}) {
			traverse($_, $depth + 1);
		}
	}
}

# my %args;
# while (shift @ARGV) {
# 	$args{$arg} if 
# }
traverse(0, 0);

