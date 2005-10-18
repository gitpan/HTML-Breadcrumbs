# labels

use Test;
BEGIN { plan tests => 13 };
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't04';
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

# Hashref labels
$labels = {};
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{bog});
$labels = { '/foo' => 'Foo Foo' };
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{foo});
$labels = { '/foo/' => 'Foo Foo' };
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{foo});
$labels = { 'foo' => 'Foo Foo' };
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{foo});
$labels = { '/bar' => 'Bar Bar' };
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{bog});
$labels = { '/foo/bar' => 'Bar Bar' };
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{bar});
$labels = { '/foo/bar/' => 'Bar Bar' };
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{bar});
$labels = { 'bar' => 'Bar Bar' };
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{bar});
$labels = { '/foo/bar/bog.html' => 'All Things Bog' };
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{bog2});
$labels = { 'bog.html' => 'All Things Bog' };
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels) eq $result{bog2});

# Subref labels
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => sub { } ) eq $result{bog});
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => sub { uc($_[1]) } ) eq $result{uc});
sub label1 {
  my ($fq_elt, $elt, $last) = @_;
  $elt =~ s/\.[^.]+// if $last;
  return $fq_elt eq '/' ? 'TOP' : uc($elt);
}
ok(breadcrumbs(path => '/foo/bar/bog.html', labels => \&label1 ) eq $result{uc2});
