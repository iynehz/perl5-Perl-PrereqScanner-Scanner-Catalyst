package Perl::PrereqScanner::Scanner::Catalyst;

# ABSTRACT: Plugin for Perl::PrereqScanner looking for Catalyst plugins

use strict;
use warnings;

use Moose;
with 'Perl::PrereqScanner::Scanner';

use String::RewritePrefix;

# see Catalyst::Util::resolve_namespace
sub _full_plugin_name {
    my ( $self, $catalyst_app_class, @plugin_classes ) = @_;

    my $appnamespace =
      $catalyst_app_class ? "${catalyst_app_class}::Plugin" : undef;
    my $namespace = 'Catalyst::Plugin';

    return String::RewritePrefix->rewrite(
        {
            q[]  => qq[${namespace}::],
            q[+] => q[],
            (
                defined $appnamespace
                ? ( q[~] => qq[${appnamespace}::] )
                : ()
            ),
        },
        @plugin_classes
    );
}

sub scan_for_prereqs {
    my ( $self, $ppi_doc, $req ) = @_;

    # we store the Catalyst app namespace only if it's file scoped
    my $catalyst_app_class;
    my $packages = $ppi_doc->find('PPI::Statement::Package') || [];
    if ( @$packages == 1 ) {
        $catalyst_app_class = $packages->[0]->namespace;
    }

    # use Catalyst ...
    my $includes = $ppi_doc->find('Statement::Include') || [];
    for my $node (@$includes) {

        # inheritance
        if ( $node->module eq 'Catalyst' ) {
            my @meat = grep {
                     $_->isa('PPI::Token::QuoteLike::Words')
                  || $_->isa('PPI::Token::Quote')
            } $node->arguments;

            my @args = map { $self->_q_contents($_) } @meat;

            while (@args) {
                my $arg = shift @args;

                if ( $arg !~ /^\-/ ) {
                    my $module =
                      $self->_full_plugin_name( $catalyst_app_class, $arg );
                    $req->add_minimum( $module => 0 );
                }
            }
        }
    }

    # It's also possible to specify plugins via Catalyat::setup(_plugins)?
    # To cover this case, we would firstly make sure the package extends
    # Catalyst, and we look for calls like __PACKAGE__->setup(_plugins)?

    # for "extends 'Catalyst';"

    my $inherits_catalyst = 0;
    {
        # from Perl::PrereqScanner::Moose
        my @chunks =

          # PPI::Statement
          #   PPI::Token::Word
          #   PPI::Structure::List
          #     PPI::Statement::Expression
          #       PPI::Token::Quote::Single
          #   PPI::Token::Structure

          map  { [ $_->schildren ] }
          grep { $_->child(0)->literal =~ m{\Aextends\z} }
          grep { $_->child(0)->isa('PPI::Token::Word') }
          @{ $ppi_doc->find('PPI::Statement') || [] };

        foreach my $hunk (@chunks) {
            my @classes =
              grep { Params::Util::_CLASS($_) }
              map  { $self->_q_contents($_) }
              grep {
                     $_->isa('PPI::Token::Quote')
                  || $_->isa('PPI::Token::QuoteLike::Words')
              } @$hunk;

            if ( grep { $_ eq 'Catalyst' } @classes ) {
                $inherits_catalyst = 1;
                last;
            }
        }
    }

    # for __PACKAGE__->setup or __PACKAGE__->setup_plugins
    if ($inherits_catalyst) {
        my @meat =
          grep {
                 $_->isa('PPI::Token::Quote')
              || $_->isa('PPI::Token::QuoteLike::Words')
          }
          map { $_->schildren }    # $_ isa PPI::Statement::Expression
          grep { $_->isa('PPI::Statement::Expression') }
          map { $_->schild(3)->schildren }    # $_ isa PPI::Structure::List
          grep {
            # make sure it's calling Catalyst::setup or setup_plugins
            (
                     $_->schild(0)->literal eq '__PACKAGE__'
                  or $_->schild(0)->literal eq "$catalyst_app_class"
              )
              and $_->schild(2)->literal =~ /^(?:setup|setup_plugins)$/
          }
          grep {
            # make sure it's a method call
                  $_->schild(0)->isa('PPI::Token::Word')
              and $_->schild(1)->isa('PPI::Token::Operator')
              and $_->schild(1)->content eq '->'
              and $_->schild(2)->isa('PPI::Token::Word')
              and $_->schild(3)->isa('PPI::Structure::List')
          }
          grep { $_->schildren > 3 }
          @{ $ppi_doc->find('PPI::Statement') || [] };

        my @args = map { $self->_q_contents($_) } @meat;
        while (@args) {
            my $arg = shift @args;

            if ( $arg !~ /^\-/ ) {
                my $module =
                  $self->_full_plugin_name( $catalyst_app_class, $arg );
                $req->add_minimum( $module => 0 );
            }
        }
    }
}

1;

__END__

=head1 SYNOPSIS

    use Perl::PrereqScanner;
    my $scanner = Perl::PrereqScanner->new(
        { extra_scanners => [ qw(Catalyst) ] }
    );
    my $prereqs = $scanner->scan_file( $path );

=head1 DESCRIPTION

This module is a scanner plugin for Perl::PrereqScanner. It looks for
Catalyst plugins in the code.

=head1 SEE ALSO

L<Perl::PrereqScanner>

L<Catalyst>

