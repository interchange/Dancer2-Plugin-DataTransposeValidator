# NAME

Dancer::Plugin::DataTransposeValidator - Data::Transpose::Validator plugin for Dancer

# VERSION

Version 0.003

# SYNOPSIS

```perl
use Dancer::Plugin::DataTransposeValidator;

post '/' => sub {
    my $params = params;
    my $data = validator($params, 'rules-file');
    if ( $data->{valid} ) { ... }
}
```

# DESCRIPTION

Dancer plugin for for [Data::Transpose::Validator](https://metacpan.org/pod/Data::Transpose::Validator)

# FUNCTIONS

This module exports the single function `validator`.

## validator( $params, $rules\_file, @additional\_args )

Arguments should be a hash reference of parameters to be validated and the
name of the rules file to use. Any `@additional_args` are passed as arguments
to the rules file **only** if it is a code reference. See ["RULES FILE"](#rules-file).

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

## RULES FILE

The rules file format allows the ["validator"](#validator) to be configured using
all options available in [Data::Transpose::Validator](https://metacpan.org/pod/Data::Transpose::Validator). The rules file
must contain a valid hash reference, e.g.: 

```perl
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
```

Note that the value of the `prepare` key must be a hash reference since the
array reference form of ["prepare" in Data::Transpose::Validator](https://metacpan.org/pod/Data::Transpose::Validator#prepare) is not supported.

As an alternative the rules file can contain a code reference, e.g.:

```perl
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
```

The code reference receives the `@additional_args` passed to ["validator"](#validator).
The code reference must return a valid hash reference.

# CONFIGURATION

The following configuration settings are available (defaults are
shown here):

```
plugins:
  DataTransposeValidator:
    css_error_class: has-error
    errors_hash: 0
    rules_dir: validation
```

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

## rules\_dir

Subdirectory of ["appdir" in Dancer::Config](https://metacpan.org/pod/Dancer::Config#appdir) in which rules files are stored.

# ACKNOWLEDGEMENTS

Alexey Kolganov for [Dancer::Plugin::ValidateTiny](https://metacpan.org/pod/Dancer::Plugin::ValidateTiny) which inspired a number
of aspects of this plugin.

# SEE ALSO

[Dancer::Plugin::ValidateTiny](https://metacpan.org/pod/Dancer::Plugin::ValidateTiny) [Dancer::Plugin::FormValidator](https://metacpan.org/pod/Dancer::Plugin::FormValidator)
[Dancer::Plugin::DataFu](https://metacpan.org/pod/Dancer::Plugin::DataFu)

# AUTHOR

Peter Mottram (SysPete), `<peter@sysnix.com>`

# COPYRIGHT AND LICENSE

Copyright 2015 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.
