use 5.016;
use warnings;

$| = 1;

sub filter {
    my $path = shift;
    # return $path =~ /^\d+$/;
    return 1;
}

sub action {
    my $path = shift;
    print "$path\n";
}

sub traverse {
    my ($root, $filter, $action) = @_;
    my @q;

    push @q, $root;
    while (scalar @q > 0) {
        my $path = shift @q;
        next if -l $path;
        if (-d $path) {
            opendir my($dir), $path or warn "Can't open a directory $path: $!\n" and next;
            my @lst = readdir $dir or warn "Can't read from a directory $path: $!\n" and next;
            for (@lst) {
                push @q, "$path/$_" unless /^[\.]{1,2}$/;
            }
            closedir $dir or warn "Can't close a directory $path: $!\n" and next;
        }
        if (-f $path) {
            $action->($path) if $filter->($path);
        }
    }
}

my $log = "log.txt";
my $root = "/Users/sjacelyn";
open STDERR, ">", $log or die "Can't open a file $log: $!\n";
traverse("$root", \&filter, \&action);