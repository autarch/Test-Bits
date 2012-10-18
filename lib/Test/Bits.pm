package Test::Bits;

use strict;
use warnings;

use List::AllUtils qw( all min );
use Scalar::Util qw( blessed reftype );

use parent qw( Test::Builder::Module );

our @EXPORT = qw( bits_is );

our $Builder;

my $UsageErrorBase
    = 'bits_is() should be passed a scalar of binary data and an array reference of numbers.';

sub bits_is ($$;$) {
    my $got    = shift;
    my $expect = shift;
    my $name   = shift;

    local $Builder = __PACKAGE__->builder();

    _check_got($got);
    _check_expect($expect);

    $got = do {
        use bytes;
        [ map { ord($_) } split //, $got ];
    };

    my $got_length    = @{$got};
    my $expect_length = @{$expect};

    my @errors;
    push @errors,
        'The two pieces of binary data are not the same length'
        . " (got $got_length, expected $expect_length)."
        unless $got_length eq $expect_length;

    my $length = min( $got_length, $expect_length );

    for my $i ( 0 .. $length - 1 ) {
        next if $got->[$i] == $expect->[$i];

        push @errors,
            sprintf(
            "Binary data begins differing at byte $i\n"
                . "  Got:    %08b\n"
                . "  Expect: %08b",
            $got->[$i],
            $expect->[$i],
            );

        last;
    }

    if (@errors) {
        $Builder->ok( 0, $name );
        $Builder->diag( join "\n", @errors );
    }
    else {
        $Builder->ok( 1, $name );
    }

    return;
}

sub _check_got {
    my $got = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $error;
    if ( !defined $got ) {
        $error
            = $UsageErrorBase . ' You passed an undef as the first argument';
    }
    elsif ( ref $got ) {
        $error
            = $UsageErrorBase
            . ' You passed a '
            . reftype($got)
            . ' reference as the first argument';
    }

    $Builder->croak($error)
        if $error;
}

sub _check_expect {
    my $expect = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $error;
    if ( !defined $expect ) {
        $error
            = $UsageErrorBase . ' You passed an undef as the second argument';
    }
    elsif ( !ref $expect ) {
        $error = $UsageErrorBase
            . ' You passed a plain scalar as the second argument';
    }
    elsif ( reftype($expect) eq 'ARRAY' ) {
        unless (
            all {
                defined $_
                    && !ref $_
                    && $_ =~ /^\d+$/
                    && $_ >= 0
                    && $_ <= 255;
            }
            @{$expect}
            ) {

            $error = $UsageErrorBase
                . q{ The second argument contains a value which isn't a number from 0-255};
        }
    }
    else {
        $error
            = $UsageErrorBase
            . ' You passed a '
            . reftype($expect)
            . ' reference as the second argument';
    }

    $Builder->croak($error)
        if $error;
}

1;
