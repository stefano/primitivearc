package Parrot::Test::Arc;

use strict;
use warnings;

use File::Basename;

=head1 NAME

This is largely a copy of Parrot::Test::Punie.

=cut

# Generate output_is(), output_isnt() and output_like() in current package.
Parrot::Test::generate_languages_functions();

sub new {
    return bless {};
}


sub get_lang_fn {
    my $self = shift;
    my ( $count, $options ) = @_;

    return File::Spec->rel2abs(Parrot::Test::per_test( '.arc',  $count ));
}

sub get_out_fn {
    my $self = shift;
    my ( $count, $options ) = @_;

    return File::Spec->rel2abs(Parrot::Test::per_test( '.out', $count ));
}

sub get_cd {
    my $self = shift;
    my ( $options ) = @_;

    return "$self->{relpath}/languages/primitivearc";
}

# never skip
sub skip_why {
    my $self = shift;
    my ($options) = @_;

    return;
}

sub get_test_prog {
    my $self = shift;
    my ( $count, $options ) = @_;

    my $lang_fn = Parrot::Test::per_test( '.arc', $count );
    ( undef, undef, my $current_dir ) = File::Spec->splitpath( Cwd::getcwd() );
    if ( $current_dir eq 'languages' ) {
        $lang_fn = File::Spec->catdir( '..', $lang_fn );
    }

    my $test_prog_args = $ENV{TEST_PROG_ARGS} || q{};

    return
        join( ' ',
              "LD_LIBRARY_PATH=src/pmc:src/ops ./primitivearc",
#							'./test.sh',
#              'primitivearc.pbc',
              $test_prog_args,
              $lang_fn );
}

1;
