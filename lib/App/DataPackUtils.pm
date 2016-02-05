package App::DataPackUtils;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

our %SPEC;

$SPEC{dump_datapack_script} = {
    v => 1.1,
    summary => 'Show the content of datapacked script (list of included modules and their versions)',
    args => {
        script => {
            schema=>'str*',
            'x.schema.entity' => 'filename',
            pos => 0,
            completion => sub {
                require Complete::Program;

                my %args = @_;
                my $word = $args{word};

                Complete::Program::complete_program(word => $word);
            },
        },
    },
};
sub dump_datapack_script {
    require File::Slurper;
    require File::Temp;
    require File::Which;

    my %args = @_;

    my $script = $args{script};
    unless (-f $script) {
        $script = File::Which::which($script);
        return [400, "No such script '$script'"] unless $script;
    }
    open my($fh), "<", $script
        or return [500, "Can't open script '$script': $!"];

    my $found;
    while (<$fh>) {
        chomp;
        do {$found++; last} if /\A__DATA__\z/;
    }
    return [412, "No __DATA__ found in script"] unless $found;

    require Data::Section::Seekable::Reader;
    my $reader = Data::Section::Seekable::Reader->new(handle=>$fh);

    my (undef, $temp_filename) = File::Temp::tempfile();

    my @res;
    for my $part ($reader->parts) {
        my $ct = $reader->read_part($part);
        $ct =~ s/^#//gm;
        File::Slurper::write_text($temp_filename, $ct);
        my $mod = $part; $mod =~ s!/!::!g; $mod =~ s/\.pm\z//;
        my $ver = MM->parse_version($temp_filename);
        push @res, {
            module => $mod,
            version => $ver,
            filesize => (-s $temp_filename),
        };
    }

    my %resmeta;
    $resmeta{'table.fields'} = [qw/module version filesize/];
    [200, "OK", \@res, \%resmeta];
}

1;
# ABSTRACT: Collection of CLI utilities related to Module::DataPack

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
L<Module::DataPack>:

#INSERT_EXECS_LIST


=head1 SEE ALSO

L<Module::DataPack>

L<App::DataSectionSeekableUtils>

=cut
