# roots and indexes functionality

use Test;
BEGIN { plan tests => 9 };
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't2';
my %result = ();
die "missing data dir t/$test" unless -d "t/$test";
opendir DATADIR, "t/$test" or die "can't open t/$test";
for (readdir DATADIR) {
  next if m/^\./;
  open FILE, "<t/$test/$_" or die "can't read t/$test/$_";
  $result{$_} = <FILE>;
  chomp $result{$_};
  close FILE;
}
close DATADIR;

# roots
ok(breadcrumbs(path => '/foo/bar/bog.html', roots => [ '/xxx' ]) eq $result{bog});
ok(breadcrumbs(path => '/foo/bar/bog.html', roots => '/foo') eq $result{foo});
ok(breadcrumbs(path => '/foo/bar/bog.html', roots => [ '/', '/foo', '/foo/bar' ]) eq $result{bar});
ok(breadcrumbs(path => '/foo/bar/bog.html', roots => [ '/', '/foo/bar', '/foo' ]) eq $result{bar});

# indexes
ok(breadcrumbs(path => '/foo/bar/bog.html', indexes => [ 'index.html' ]) eq $result{bog});
ok(breadcrumbs(path => '/foo/bar/bog.html', indexes => [ 'bog.html' ]) eq $result{bar2});
ok(breadcrumbs(path => '/foo/bar/bog.html', indexes => [ 'index.html', 'index.php', 'bog.html' , 'home.html' ]) eq $result{bar2});
ok(breadcrumbs(path => '/foo/bar/bog.html', indexes => 'bog.html') eq $result{bar2});
ok(breadcrumbs(path => '/foo/bar/index.html') eq $result{bar2});
