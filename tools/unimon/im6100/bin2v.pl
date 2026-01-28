#!/usr/bin/perl

# bin2v.pl
# bin to mem_cp.v converter
# by Ryo Mukai

use strict;
use warnings;

my $file = $ARGV[0];
open my $fh, "<", $file or die $!;
binmode($fh);

my $start = 0;
my $MAXROMSIZE = 010000;
my $buf;
my $data;

print
    "// mem_cp.v\n".
    "// to be included from the top module at the compile\n\n".
    "initial\n".
    "begin\n";

for(my $addr = $start; $addr < $MAXROMSIZE; $addr++){
    last if(! sysread($fh, $buf, 2));
    $data = unpack('n', $buf) & 07777;
	
    printf("mem_cp['o%04o]='o%04o;\n", $addr, $data);
#    printf("mem['o%04o]='o%04o;\n", $addr, $data);
}
print  "end\n";

close $fh;
    
