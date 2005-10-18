# omit

use Test;
BEGIN { plan tests => 17 };
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't03';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d "$test";
opendir DATADIR, "$test" or die "can't open $test";
for (readdir DATADIR) {
  next if m/^\./;
  open FILE, "<$test/$_" or die "can't read $test/$_";
  $result{$_} = <FILE>;
  chomp $result{$_};
  close FILE;
}
close DATADIR;

# die on warnings
BEGIN { $SIG{'__WARN__'} = sub { die $_[0] } }

# omit
ok(breadcrumbs(path => '/foo/bar/bog.html', omit => '/foo') eq $result{foo});
ok(breadcrumbs(path => '/foo/bar/bog.html', omit => [ '/foo' ]) eq $result{foo});
ok(breadcrumbs(path => '/cgi-bin/test/forms/help.html', omit => [ '/cgi-bin/', '/cgi-bin/test' ]) eq $result{cgi});
ok(! defined eval { breadcrumbs(path => '/cgi-bin/test/forms/help.html', omit => 'cgi-bin/test') });
ok(breadcrumbs(path => '/foo/bar/bog.html', omit => 'foo') eq $result{foo});
ok(breadcrumbs(path => '/foo/bar/bog.html', omit => 'bar') eq $result{bar});
ok(breadcrumbs(path => '/cgi-bin/test/forms/help.html', omit => [ 'cgi-bin', 'test' ]) eq $result{cgi});

# omit_regex
ok(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => '\d+') eq $result{bar});
ok(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => '\d+$') eq $result{bar});
ok(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => '^\d+$') eq $result{n123});
ok(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ '\d+' ]) eq $result{bar});
ok(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ '\d+$' ]) eq $result{bar});
ok(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ '^\d+$' ]) eq $result{n123});
ok(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ 'oo' ]) eq $result{foon});
ok(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ '/n\d+' ]) eq $result{n123});
ok(breadcrumbs(path => '/foo/n123/bar/n678/bog.html', omit_regex => [ '/foo/n\d+' ]) eq $result{n678});
ok(breadcrumbs(path => '/foo/n123/bar/n678/bog.html', omit_regex => [ '/foo/n1' ]) eq $result{n678full});

