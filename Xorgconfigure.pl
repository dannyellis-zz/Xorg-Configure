#!/usr/bin/perl

#use strict;
#use warnings;

print "##  Xorg.conf Creator ##\n";
## Update PCI IDS in case out of date and video card name does not show.
print "Updating PCI IDS for up to date Video Card Names\n";
system("cp pci.ids /usr/share/hwdata/pci.ids");
sleep 5;

$unique_date = get_timestamp();
system("cp /etc/X11/xorg.conf /etc/X11/xorg.conf.$unique_date");
print "Backup xorg.conf file created \"xorg.conf.$unique_date\"\n";

## Subroutine to get the current datestamp for file backup.
sub get_timestamp { 
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 

$year=$year+1900; 
$mon++;

return $year . sprintf('%02u%02u_%02u%02u', $mon, $mday, $hour, $min); 
}


## Open FileHandle for Outputting xorg.conf to current directory
open (OUTPUT, ">/etc/X11/xorg.conf");

## Making Array for output of lspci | grep VGA to parse from
my @lspciOut=`lspci | egrep 'VGA|3D'`;

## Finding the size of the array, as this is the number of GPU's in the machine.
my $numGPU = @lspciOut;


## Printing to file all the General info that is on all machines
print OUTPUT "#####################################\n";
print OUTPUT "#  GENERAL\n";
print OUTPUT "#####################################\n\n";
print OUTPUT "Section \"ServerLayout\"\n";
print OUTPUT "	Identifier	\"Default Layout\"\n";
print OUTPUT "	Screen	0	\"Screen0\" 0 0\n";
## Only output this line if there are more than one GPU's in the system
for (my $count5=1; $count5 < $numGPU; $count5++) {
my $temp = $count5-1;
print OUTPUT "	Screen  $count5	\"Screen$count5\" RightOf \"Screen$temp\"\n";
}
print OUTPUT "	InputDevice	\"Mouse0\" \"CorePointer\"\n";
print OUTPUT "	InputDevice	\"Keyboard0\" \"CoreKeyboard\"\n";
print OUTPUT "EndSection\n\n";

print OUTPUT "Section \"InputDevice\"\n";
print OUTPUT "	Identifier	\"Mouse0\"\n";
print OUTPUT "	Driver		\"mouse\"\n";
print OUTPUT "	Option		\"Protocol\" \"auto\"\n";
print OUTPUT "	Option		\"Device\" \"/dev/input/mice\"\n";
print OUTPUT "	Option		\"Emulate3Buttons\" \"no\"\n";
print OUTPUT "	Option		\"ZAxisMapping\" \"4 5\"\n";
print OUTPUT "EndSection\n\n";

print OUTPUT "Section \"InputDevice\"\n";
print OUTPUT "	Identifier	\"Keyboard0\"\n";
print OUTPUT "	Driver		\"kbd\"\n";
print OUTPUT "	Option		\"XkbModel\" \"pc105\"\n";
print OUTPUT "	Option		\"XkbLayout\" \"us\"\n";
print OUTPUT "EndSection\n\n";

print OUTPUT "Section \"Files\"\n";
print OUTPUT "	FontPath	\"/usr/share/X11/fonts/misc\"\n";
print OUTPUT "	FontPath        \"/usr/share/X11/fonts/75dpi\"\n";
print OUTPUT "	FontPath        \"/usr/share/X11/fonts/100dpi\"\n";
print OUTPUT "	FontPath        \"/usr/share/X11/fonts/Type1\"\n";
print OUTPUT "	FontPath        \"/usr/share/X11/fonts/TTF\"\n";
print OUTPUT "	FontPath        \"/usr/share/fonts/default/Type1\"\n";
print OUTPUT "	FontPath        \"/usr/share/fonts/msttcorefonts\"\n";
print OUTPUT "EndSection\n\n";


## Doing a loop for Monitors, each GPU can have a monitor.
for (my $count=0; $count < $numGPU; $count++) {
print OUTPUT "Section \"Monitor\"\n";
print OUTPUT "	Identifier	\"Monitor$count\"\n";
print OUTPUT "	HorizSync	30.0 - 110.0\n";
print OUTPUT "	VertRefresh	50.0 - 150.0\n";
print OUTPUT "	Option		\"DPMS\"\n";
print OUTPUT "EndSection\n\n";
}

## Variables for Array of BusID's.
my @BusIDs;
my $counter3=0;

## Finding the BusID of each Video card then converting to decimal and storing in array
foreach my $line (@lspciOut) {
$_=$line;
($first)=/^(\w\w).+$/;
$decval=hex($first);

$BusIDs[$counter3] = $decval;

$counter3++;

}

## Variables for names of each Video card.
my @VideoCardNames;
my $counter4=0;

## Finding out names of video cards then making all CAPS then adding to array.
foreach my $line (@lspciOut) {
$_=$line;
($first)=/\[(.*?)\]/;
$VideoCardNames[$counter4] = $first;
$VideoCardNames[$counter4] =~ tr/[a-z]/[A-Z]/;
$counter4++;
}

## Printing to file for each device (video card) with appropriate name and BusID.
for (my $count2=0; $count2 < $numGPU; $count2++) {
print OUTPUT "Section \"Device\"\n";
print OUTPUT "	Identifier	\"Device$count2\"\n";
print OUTPUT "	Driver		\"nvidia\"\n";
print OUTPUT "	VendorName	\"NVIDIA Corporation\"\n";
print OUTPUT "	BoardName	\"$VideoCardNames[$count2]\"\n";
print OUTPUT "	BusID		\"PCI:$BusIDs[$count2]:0:0\"\n";
print OUTPUT "EndSection\n\n";
}

## Printing to file each screen.
for (my $count3=0; $count3 < $numGPU; $count3++) {
print OUTPUT "Section \"Screen\"\n";
print OUTPUT "	Identifier	\"Screen$count3\"\n";
print OUTPUT "	Device		\"Device$count3\"\n";
print OUTPUT "	Monitor		\"Monitor$count3\"\n";
print OUTPUT "	DefaultDepth	24\n";
print OUTPUT "	Option		\"ConnectedMonitor\" \"DFP\"\n";
print OUTPUT "	SubSection	\"Display\"\n";
print OUTPUT "		Depth	24\n";
print OUTPUT "	EndSubSection\n";
print OUTPUT "EndSection\n\n";
}

## Closing file
close (OUTPUT);

$VidCardName=$VideoCardNames[0];
