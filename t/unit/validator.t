#!perl
use strict;
use warnings;
use Dancer qw/:tests/;
use Test::More;
use Test::Exception;
use aliased 'Dancer::Plugin::DataTransposeValidator::Validator';

my $v;

throws_ok { $v = Validator->new } qr/missing required arg/i, "new with no args";

done_testing;
