[![Build Status](https://travis-ci.org/stphnlyd/perl5-Perl-PrereqScanner-Scanner-Catalyst.svg?branch=master)](https://travis-ci.org/stphnlyd/perl5-Perl-PrereqScanner-Scanner-Catalyst)

# NAME

Perl::PrereqScanner::Scanner::Catalyst - Plugin for Perl::PrereqScanner looking for Catalyst plugin/action modules

# VERSION

version 0.002

# SYNOPSIS

    use Perl::PrereqScanner;
    my $scanner = Perl::PrereqScanner->new(
        { extra_scanners => [ qw(Catalyst) ] }
    );
    my $prereqs = $scanner->scan_file( $path );

# DESCRIPTION

This module is a scanner plugin for Perl::PrereqScanner. It looks for
use of Catalyst plugin and action modules in the code.

# SEE ALSO

[Perl::PrereqScanner](https://metacpan.org/pod/Perl::PrereqScanner)

[Catalyst](https://metacpan.org/pod/Catalyst)

# AUTHOR

Stephan Loyd <sloyd@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
