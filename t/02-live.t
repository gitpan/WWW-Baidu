use strict;
use warnings;
use Test::More;

eval {
    use LWP::UserAgent;
    my $agent = LWP::UserAgent->new;
    $agent->env_proxy();
    my $res = $agent->get('http://www.baidu.com');
    die if ! $res->is_success;
};
plan skip_all => "network seems unavailable (live tests skipped)" if $@;

plan tests => 6 * 20 + 2;

use Cache::FileCache;
use WWW::Baidu;
my $cache = Cache::FileCache->new(
    { namespace          => '02-live-t',
      default_expires_in => $Cache::Cache::EXPIRES_NOW }
);
my $baidu = WWW::Baidu->new($cache);
$baidu->limit(20);
my $count = $baidu->search('Perl', 'Iraq');
ok $count > 20, 'more than 20 results returned';
my @items;
my $i = 1;
my $has_cached_url;
while (my $item = $baidu->next) {
    if ($i > 20) {
        fail('oops! limit(20) has no effect...');
        last;
    }
    ok $item->title, "page $i - title ok";
    ok $item->summary, "page $i - summary ok";
    my $s = $item->title . $item->summary;
    like $s, qr/Perl/i, "page $i - 'perl' appears in the item";
    like $s, qr/Iraq/i, "page $i - 'Iraq' appears in the item";
    like $item->url, qr/^\S*\w+\S*$/, "page $i - url looks okay";
    like $item->size, qr/^\d+\s*[KM]$/, "page $i - size looks good";
    if (!$has_cached_url and defined $item->cached_url) {
        like $item->cached_url, qr[^http://cache\.baidu\.com/\S*\w+\S*$], 'cached url looks good';
        $has_cached_url = 1;
    }
    $i++;
}
if (!$has_cached_url) {
    fail("weird. cached url never found :(");
}
