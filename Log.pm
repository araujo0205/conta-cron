#!/usr/bin/perl
use v5.10;
use strict;

package Log;
use Path::Tiny qw(path);

sub write {
    use Time::Piece;

    my $time = localtime->strftime('%Y-%m-%d %H:%M:%S');
    my $file = "./logs/cron.log";
    my ($uuid,$mensagem) = @_;
    path($file)->append("$time $uuid $mensagem \n");
    
    print "$time $uuid $mensagem \n";
}
    
return 1;
