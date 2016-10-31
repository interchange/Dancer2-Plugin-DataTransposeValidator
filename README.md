# NAME

Dancer2::Plugin::DataTransposeValidator - Data::Transpose::Validator plugin for Dancer2

# VERSION

Version 0.100

# SYNOPSIS

    use Dancer2::Plugin::DataTransposeValidator;

    post '/' => sub {
        my $params = params;
        my $data = validator($params, 'rules-file');
        if ( $data->{valid} ) { ... }
    }

# DESCRIPTION

Dancer2 plugin for for [Data::Transpose::Validator](https://metacpan.org/pod/Data::Transpose::Validator)

# FUNCTIONS

This module exports the single function `validator`.

## validator( $params, $rules, @additional\_args? )

Where:

`$params` is a hash reference of parameters to be validated.

`$rules` is one of:

- the name of a rule sub if you are using ["rules\_class"](#rules_class)
- the name of a rule file if you are using ["rules\_dir"](#rules_dir)
- a hash reference of rules
- a code reference that will return a hashref of rules

Any optional `@additional_args` are passed as arguments to code
references/subs.

A hash reference with the following keys is returned:

- valid

    A boolean 1/0 showing whether the parameters validated correctly or not.

- values

    The transposed values as a hash reference.

- errors

    A hash reference containing one key for each parameter which failed validation.
    See ["errors\_hash"](#errors_hash) in ["CONFIGURATION"](#configuration) for an explanation of what the value
    of each parameter key will be.

- css

    A hash reference containing one key for each parameter which failed validation.
    The value for each parameter is a css class. See ["css\_error\_class"](#css_error_class) in
    ["CONFIGURATION"](#configuration).

# CONFIGURATION

The following configuration settings are available (defaults are
shown here):

    plugins:
      DataTransposeValidator:
        css_error_class: has-error
        errors_hash: 0
        rules_class: MyApp::ValidationRules
        # OR:
        rules_dir: validation

## css\_error\_class

The class returned as a value for parameters in the css key of the hash
reference returned by ["validator"](#validator).

## errors\_hash

This can has a number of different values:

- A false value (the default) means that only a single scalar error string will
be returned for each parameter error. This will be the first error returned
for the parameter by ["errors\_hash" in Data::Transpose::Validator](https://metacpan.org/pod/Data::Transpose::Validator#errors_hash).
- joined

    All errors for a parameter will be returned joined by a full stop and a space.

- arrayref

    All errors for a parameter will be returned as an array reference.

## rules\_class

This is much preferred over ["rules\_dir"](#rules_dir) since it does not eval external files.

This is a class (package) name such as `MyApp::Validator::Rules`. There should
be one sub for each rule name inside that class which returns a hash reference.
See ["RULES CLASS"](#rules-class) for examples.

## rules\_dir

Subdirectory of ["appdir" in Dancer2::Config](https://metacpan.org/pod/Dancer2::Config#appdir) in which rules files are stored.
**NOTE:** We recommend you do not use this approach since the rules files
are eval'ed with all the security risks that entails. Please use ["rules\_class"](#rules_class)
instead. **You have been warned**. See ["RULES DIR"](#rules-dir) for examples.

## RULES CLASS

The rules class allows the ["validator"](#validator) to be configured using
all options available in [Data::Transpose::Validator](https://metacpan.org/pod/Data::Transpose::Validator). The rules class must
contain one sub for each rule name which will be passed any `@optional_args`.

    package MyApp::ValidationRules;

    sub register {
        # simple hashref
        +{
            options => {
                stripwhite => 1,
                collapse_whitespace => 1,
                requireall => 1,
            },
            prepare => {
                email => {
                    validator => "EmailValid",
                },
                email2 => {
                    validator => "EmailValid",
                },
                emails => {
                    validator => 'Group',
                    fields => [ "email", "email2" ],
                },
            },
        };
    }

    sub change_password {
        # args and hashref
        my %args = @_;
        +{
            options => {
                requireall => 1,
            },
            prepare => {
                old_password => {
                    required  => 1,
                    validator => sub {
                        if ( $args{logged_in_user}->check_password( $_[0] ) ) {
                            return 1;
                        }
                        else {
                            return ( undef, "Password incorrect" );
                        }
                    },
                },
                password => {
                    required  => 1,
                    validator => {
                        class   => 'PasswordPolicy',
                        options => {
                            username      => $args{logged_in_user}->username,
                            minlength     => 8,
                            maxlength     => 70,
                            patternlength => 4,
                            mindiffchars  => 5,
                            disabled      => {
                                digits   => 1,
                                mixed    => 1,
                                specials => 1,
                            }
                        }
                    }
                },
                confirm_password => { required => 1 },
                passwords        => {
                    validator => 'Group',
                    fields    => [ "password", "confirm_password" ],
                },
            },
        };
    }

    1;

## RULES DIR

The rules file format allows the ["validator"](#validator) to be configured using
all options available in [Data::Transpose::Validator](https://metacpan.org/pod/Data::Transpose::Validator). The rules file
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

Note that the value of the `prepare` key must be a hash reference since the
array reference form of ["prepare" in Data::Transpose::Validator](https://metacpan.org/pod/Data::Transpose::Validator#prepare) is not supported.

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

The code reference receives the `@additional_args` passed to ["validator"](#validator).
The code reference must return a valid hash reference.

# SEE ALSO

[Dancer2](https://metacpan.org/pod/Dancer2), [Data::Transpose](https://metacpan.org/pod/Data::Transpose)

# ACKNOWLEDGEMENTS

Alexey Kolganov for [Dancer::Plugin::ValidateTiny](https://metacpan.org/pod/Dancer::Plugin::ValidateTiny) which inspired a number
of aspects of the original version of this plugin.

Stefan Hornburg (Racke) for his valuable feedback.

# AUTHOR

Peter Mottram (SysPete), `<peter@sysnix.com>`

# COPYRIGHT AND LICENSE

Copyright 2015-2016 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.
