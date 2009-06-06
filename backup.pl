#!/usr/bin/env perl

=head1 NAME

fireagle-tools/backup.pl - backup your current FireEagle location to local file

=head1 SYNOPSIS

 fireeagle-tools/backup.pl -c /path/to/configfile.cfg

=head1 DESCRIPTION

Backup your current FireEagle location to local file, using the FireEagle API. Files
are written to a nested YYYY/MM/DD directory tree.

For example:

  /home/youarehere/fireeagle/2009/06/06:
  used 8 available 1436916
  drwx------  2 youarehere  users   512 Jun  6 09:35 .
  drwx------  3 youarehere  users   512 Jun  6 09:33 ..
  -rw-------  1 youarehere  users  3903 Jun  6 09:35 200906060931330700.xml

It's the sort of thing you'd run out of cron, or something. That's your business.

=cut
 
use strict;

use Getopt::Std;
use Config::Simple;
use Net::FireEagle;
use XML::XPath;

use File::Spec;
use File::Path;
use FileHandle;

{
        &main();
        exit;
}

sub main {

        my %opts = ();
        getopts('c:', \%opts);

        my $cfg = Config::Simple->new($opts{'c'});

        my $key = $cfg->param("fireeagle.consumer_key");
        my $secret = $cfg->param("fireeagle.consumer_secret");
        my $auth_token = $cfg->param("fireeagle.access_token");
        my $auth_secret = $cfg->param("fireeagle.access_token_secret");

        my $fe = Net::FireEagle->new(consumer_key        => $key, 
                                     consumer_secret     => $secret, 
                                     access_token        => $auth_token, 
                                     access_token_secret => $auth_secret );

        my $loc = $fe->location();
        # print $loc;

        my $xp = XML::XPath->new('xml' => $loc);

        my $user = ($xp->findnodes("/rsp/user"))[0];
        my $ts = $user->getAttribute("located-at");
        $ts =~ s/[:\-T]//g;
        
        $ts =~ /^(\d{4})(\d{2})(\d{2})/;

        my $yyyy = $1;
        my $mm = $2;
        my $dd = $3;

        # 

        my $backup = $cfg->param("fireeagle_backup.directory");

        my $root = File::Spec->catdir($backup, $yyyy, $mm, $dd);
        my $dump = File::Spec->catfile($root, "$ts.xml");

        if (-f $dump){
                return 1;
        }

        if (! -d $root){
                if (! mkpath([$root], 1, 0700)){
                        warn "failed to create $root, $!";
                        return 0;
                }
        }

        my $fh = FileHandle->new();

        if (! $fh->open(">$dump")){
                warn "failed to open $dump for writing, $!";
                return 0;
        }

        binmode $fh, ":utf8";

        $fh->print($loc);
        $fh->close();

        chmod 0600, $dump;
        return 1;
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2009/06/06 16:45:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 EXAMPLE CONFIG FILE

 [fireeagle]
 consumer_key=CONSUMER_KEY
 consumer_secret=CONSUMER_SECRET
 access_token=ACCESS_TOKEN
 access_token_secret=ACCESS_TOKEN_SECRET

 [fireeagle_backup]
 directory=/home/youarehere/fireeagle

=head1 REQUIREMENTS

L<Net::FireEagle>

L<XML::XPath>

L<Config::Simple>

=head1 LICENSE

Copyright (c) 2009 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut
