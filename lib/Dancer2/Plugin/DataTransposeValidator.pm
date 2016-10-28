package Dancer2::Plugin::DataTransposeValidator;

use strict;
use warnings;

use Carp 'croak';
use Path::Tiny;
use Dancer2::Core::Types;
use Data::Transpose::Validator;

use Dancer2::Plugin;

=head1 NAME

Dancer2::Plugin::DataTransposeValidator - Data::Transpose::Validator plugin for Dancer2

=head1 VERSION

Version 0.100

=cut

our $VERSION = '0.100';

has css_error_class => (
    is          => 'ro',
    isa         => Str,
    from_config => sub { 'has-error' },
);

has errors_hash => (
    is          => 'ro',
    isa         => Maybe [Str],
    from_config => sub { undef },
);

has rules_dir => (
    is  => 'ro',
    isa => sub {
        eval { path( $_[0] )->is_dir; 1 }
          or do { croak "rules directory does not exist" };
    },
    default => sub {
        my $plugin = shift;
        my $dir =
            $plugin->config->{rules_dir}
          ? $plugin->config->{rules_dir}
          : 'validation';
        path($plugin->app->setting('appdir'))->child($dir)->stringify;
    },
);

plugin_keywords 'validator';

sub validator {
    my ( $plugin, $params, $rules_file, @additional_args ) = @_;

    croak "params must be a hash reference" unless ref($params) eq 'HASH';

    my $path = path( $plugin->rules_dir )->child($rules_file);
    croak "rules_file does not exist" unless $path->is_file;

    my $rules = do $path or croak "bad rules file: $path - $! $@";
    if ( ref($rules) eq 'CODE' ) {
        $rules = $rules->(@additional_args);
    }

    my $options = $rules->{options} || {};
    my $prepare = $rules->{prepare} || {};

    my $dtv = Data::Transpose::Validator->new(%$options);
    $dtv->prepare(%$prepare);

    my $clean = $dtv->transpose($params);
    my $ret;

    if ($clean) {
        $ret->{valid}  = 1;
        $ret->{values} = $clean;
    }
    else {
        $ret->{valid}  = 0;
        $ret->{values} = $dtv->transposed_data;

        my $v_hash = $dtv->errors_hash;
        while ( my ( $key, $value ) = each %$v_hash ) {

            $ret->{css}->{$key} = $plugin->css_error_class;

            my @errors = map { $_->{value} } @{$value};

            if ( $plugin->errors_hash && $plugin->errors_hash eq 'joined' ) {
                $ret->{errors}->{$key} = join( ". ", @errors );
            }
            elsif ( $plugin->errors_hash && $plugin->errors_hash eq 'arrayref' )
            {
                $ret->{errors}->{$key} = \@errors;
            }
            else {
                $ret->{errors}->{$key} = $errors[0];
            }
        }
    }
    return $ret;

}

1;
__END__

=head1 SYNOPSIS

    use Dancer2::Plugin::DataTransposeValidator;

    post '/' => sub {
        my $params = params;
        my $data = validator($params, 'rules-file');
        if ( $data->{valid} ) { ... }
    }


=head1 DESCRIPTION

Dancer2 plugin for for L<Data::Transpose::Validator>

=head1 FUNCTIONS

This module exports the single function C<validator>.

=head2 validator( $params, $rules_file, @additional_args )

Arguments should be a hash reference of parameters to be validated and the
name of the rules file to use. Any C<@additional_args> are passed as arguments
to the rules file B<only> if it is a code reference. See L</RULES FILE>.

A hash reference with the following keys is returned:

=over 4

=item * valid

A boolean 1/0 showing whether the parameters validated correctly or not.

=item * values

The transposed values as a hash reference.

=item * errors

A hash reference containing one key for each parameter which failed validation.
See L</errors_hash> in L</CONFIGURATION> for an explanation of what the value
of each parameter key will be.

=item * css

A hash reference containing one key for each parameter which failed validation.
The value for each parameter is a css class. See L</css_error_class> in
L</CONFIGURATION>.

=back

=head2 RULES FILE

The rules file format allows the L</validator> to be configured using
all options available in L<Data::Transpose::Validator>. The rules file
must contain a valid hash reference, e.g.: 

    {
        options => {
            stripwhite => 1,
            collapse_whitespace => 1,
            requireall => 0,
            unknown => "fail",
            missing => "undefine",
        },
        prepare => {
            email => {
                validator => "EmailValid",
                required => 1,
            },
            email2 => {
                validator => {
                    class => "MyValidator::EmailValid",
                    absolute => 1,
                }
            },
            field4 => {
                validator => {
                    sub {
                        my $field = shift;
                        if ( $field =~ /^\d+/ && $field > 0 ) {
                            return 1;
                        }
                        else {
                            return ( undef, "Not a positive integer" );
                        }
                    }
                }
            }
        }
    }

Note that the value of the C<prepare> key must be a hash reference since the
array reference form of L<Data::Transpose::Validator/prepare> is not supported.

As an alternative the rules file can contain a code reference, e.g.:

    sub {
        my $username = shift;
        return {
            options => {
                stripwhite => 1,
            },
            prepare => {
                password => {
                    validator => {
                        class => 'PasswordPolicy',
                        options => {
                            username  => $username,
                            minlength => 8,
                        }
                    }
                }
            }
        };
    }

The code reference receives the C<@additional_args> passed to L</validator>.
The code reference must return a valid hash reference.

=head1 CONFIGURATION

The following configuration settings are available (defaults are
shown here):

    plugins:
      DataTransposeValidator:
        css_error_class: has-error
        errors_hash: 0
        rules_dir: validation

=head2 css_error_class

The class returned as a value for parameters in the css key of the hash
reference returned by L</validator>.

=head2 errors_hash

This can has a number of different values:

=over 4

=item * 0

A false value (the default) means that only a single scalar error string will
be returned for each parameter error. This will be the first error returned
for the parameter by L<Data::Transpose::Validator/errors_hash>.

=item * joined

All errors for a parameter will be returned joined by a full stop and a space.

=item * arrayref

All errors for a parameter will be returned as an array reference.

=back

=head2 rules_dir

Subdirectory of L<Dancer2::Config/appdir> in which rules files are stored.


=head1 ACKNOWLEDGEMENTS

Alexey Kolganov for L<Dancer::Plugin::ValidateTiny> which inspired a number
of aspects of this plugin.

=head1 AUTHOR

Peter Mottram (SysPete), C<< <peter@sysnix.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
