# omit

use Test;
BEGIN { plan tests => 3 };
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't3';
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

# omit
ok(breadcrumbs(path => '/foo/bar/bog.html', omit => [ '/foo' ]) eq $result{foo});
ok(breadcrumbs(path => '/foo/bar/bog.html', omit => '/foo') eq $result{foo});
ok(breadcrumbs(path => '/cgi-bin/test/forms/help.html', omit => [ '/cgi-bin/', 'cgi-bin/test' ]) eq $result{cgi});
