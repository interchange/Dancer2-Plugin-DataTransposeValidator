#!perl
use strict;
use warnings;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't';
}

use Test::More import => ['!pass'];
use Test::Deep;
use Test::Exception;

use File::Spec;
use HTTP::Request::Common;
use JSON::MaybeXS;
use Plack::Builder;
use Plack::Test;

{

    package TestAppNoConfig;

    use Dancer2;
    use Dancer2::Plugin::DataTransposeValidator;

    get '/' => sub {
        return "home";
    };

    post '/default' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };

    post '/coderef1' => sub {
        my $params = params;
        my $data = validator( $params, 'coderef1', 'String' );
        content_type('application/json');
        return to_json($data);
    };

    post '/coderef2' => sub {
        my $params = params;
        my $data = validator( $params, 'coderef1', 'EmailValid' );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppNoErrorsJoined;

    use Dancer2;
    use Dancer2::Plugin::DataTransposeValidator;

    set plugins => {
        DataTransposeValidator => {
            errors_hash => "joined"
        }
    };

    post '/joined' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppNoErrorsArrayRef;

    use Dancer2;
    use Dancer2::Plugin::DataTransposeValidator;

    set plugins => {
        DataTransposeValidator => {
            errors_hash => "arrayref"
        }
    };

    post '/arrayref' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppCssErrorClass;

    use Dancer2;
    use Dancer2::Plugin::DataTransposeValidator;

    set plugins => {
        DataTransposeValidator => {
            css_error_class => "foo"
        }
    };

    post '/css-foo' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppBadRulesDir;

    use Dancer2;
    use Dancer2::Plugin::DataTransposeValidator;

    set plugins => {
        DataTransposeValidator => {
            rules_dir => "foo"
        }
    };

    post '/bad_rules_dir' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppGoodRulesDir;

    use Dancer2;
    use Dancer2::Plugin::DataTransposeValidator;

    set plugins => {
        DataTransposeValidator => {
            rules_dir => "validation"
        }
    };

    post '/good_rules_dir' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

my ( $data, $expected, $req, $res );
my $uri = "http://localhost";

my $test = Plack::Test->create( TestAppNoConfig->to_app );

subtest 'TestAppNoConfig /' => sub {

    # simple test to make sure nothing scary is happening
    $req = GET "$uri/";
    $res = $test->request($req);
    ok( $res->is_success, "get / OK" );
    like( $res->content, qr/home/, "Content contains home" );
};

subtest 'TestAppNoConfig /default missing email & password' => sub {

    # errors_hash is false
    $req = POST "$uri/default", [ foo => "bar" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo" ) or diag $res->content;

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => "Missing required field email",
            password => "Missing required field password"
        },
        valid  => 0,
        values => {
            foo => "bar",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

subtest 'TestAppNoConfig /default missing email' => sub {

    # errors_hash is false
    $req = POST "$uri/default", [ foo => " bar ", password => "bad  pwd" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo and bad password" );

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => "Missing required field email",
            password => re(qr/\w/),
        },
        valid  => 0,
        values => {
            foo      => "bar",
            password => "bad pwd",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

subtest 'TestAppNoConfig /default all valid' => sub {

    $req = POST "$uri/default",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo" );

    $expected = {
        valid  => 1,
        values => {
            foo      => "bar",
            email    => 'user@example.com',
            password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

subtest 'TestAppNoConfig /coderef1' => sub {

    # coderef with foo validated as String
    $req = POST "$uri/coderef1",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success, "coderef rules foo String" );

    $expected = {
        valid  => 1,
        values => {
            foo      => "bar",
            email    => 'user@example.com',
            password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

subtest 'TestAppNoConfig /coderef2' => sub {

    # coderef with foo validated as String
    $req = POST "$uri/coderef2",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success, "coderef rules foo EmailValid" );

    $expected = {
        css => {
            foo => "has-error"
        },
        errors => {
            foo => "rfc822"
        },
        valid  => 0,
        values => {
            email    => "user\@example.com",
            foo      => "bar",
            password => "cA\$(!n6K)Y.zoKoqayL}\$O6EY}Q+g"
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

$test = Plack::Test->create( TestAppNoErrorsJoined->to_app );

subtest 'TestAppNoErrorsJoined /joined' => sub {

    # errors_hash is joined
    $req = POST "$uri/joined", [ foo => " bar ", password => "bad  pwd" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo and bad password" );

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => "Missing required field email",
            password => re(qr/.+\..+\..+/),
        },
        valid  => 0,
        values => {
            foo      => "bar",
            password => "bad pwd",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

$test = Plack::Test->create( TestAppNoErrorsArrayRef->to_app );

subtest 'TestAppNoErrorsArrayRef /arrayref' => sub {

    # errors_hash is arrayref
    $req = POST "$uri/arrayref", [ foo => " bar ", password => "bad  pwd" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo and bad password" );

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => bag("Missing required field email"),
            password => supersetof( re(qr/\w/), re(qr/\w/) ),
        },
        valid  => 0,
        values => {
            foo      => "bar",
            password => "bad pwd",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
    $data = $data->{errors}->{password};
    cmp_ok( ref($data), 'eq', 'ARRAY', "error value is an array reference" );
};

$test = Plack::Test->create( TestAppCssErrorClass->to_app );

subtest 'TestAppCssErrorClass /css-foo' => sub {

    # css_error_class is 'foo'
    $req = POST "$uri/css-foo", [ foo => " bar ", password => "bad  pwd" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo and bad password" );

    $expected = {
        css => {
            email    => "foo",
            password => "foo"
        },
        errors => {
            email    => "Missing required field email",
            password => re(qr/\w/),
        },
        valid  => 0,
        values => {
            foo      => "bar",
            password => "bad pwd",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

$test = Plack::Test->create( TestAppBadRulesDir->to_app );

subtest 'TestAppBadRulesDir /bad_rules_dir' => sub {

    # rules_dir is foo
    $req = POST "$uri/bad_rules_dir", [ foo => "bar" ];
    $res = $test->request($req);
    cmp_ok( $res->code, 'eq', '500', "testing rules_dir => foo" );
};

$test = Plack::Test->create( TestAppGoodRulesDir->to_app );

subtest 'TestAppGoodRulesDir /good_rules_dir' => sub {

    # rules_dir is validation
    $req = POST "$uri/good_rules_dir", [ foo => "bar" ];
    $res = $test->request($req);
    ok( $res->is_success, "rules_dir is good" );

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => "Missing required field email",
            password => "Missing required field password"
        },
        valid  => 0,
        values => {
            foo => "bar",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

done_testing;
