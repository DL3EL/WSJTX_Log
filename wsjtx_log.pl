#!/usr/bin/perl -w
# broadcast sender script
use warnings;
use Time::Piece;

#############################################################
# globals

my $verbose = 0;
my $version = "1.01";
my $debug = 0;
my @array;
my $entry;
my $nn = 0;
my $radioid = "";
my $cloudlogApiKeyWR = "";
# my $station_profile_id = "5";
my $station_profile_id = 0;
my @station_profile_id;
my $idnn = 0;
my @station_callsign;
my $station_callsign = "";
my $opnn = 0;
my @wsjtx_config;
my $wsjtx_config = "?";
my $cloudlogApiBase = "";
my $wcnn = 0;
my @cloudlogApiBase;
my $apinn = 0;
my $cloudlogRadioId;
my $cloudlogApiUrlLog = "";
my $cloudlogApiUrlFreq = "";
my $par;
my $socketip = "";
my $socketport = "";
my $data = "";
my $magic_number = "";
my $schema_number = "";
my $type = "";
my $qrg = 0;
my $band = 0;
my $mode = "";
my $polling = 5;
my $cloudlog_updates = 0;
############################################################
# get total arg passed to this script
	# get script name
	STDOUT->autoflush(1);
	my $tm = localtime(time);
	printf("WSJT-X Cloudlog Connectoor [v$version] Start: %02d:%02d:%02d am %02d.%02d.%04d\n",$tm->hour, $tm->min, $tm->sec, $tm->mday, $tm->mon,$tm->year);
	my $scriptname = $0;
	my $file_path = ($scriptname =~ /(.*)\/([\w]+).pl/s)? $1 : "undef";
	$file_path = $file_path . "/";
	$scriptname = $2;
	
# Input from cli here:
# log={"cmd":"logResponse","qso":{"Id":3,"Mode":"FT8","SubMode":"","Callsign":"M6NNB","Date":"2023-02-09T16:56:01.3368647Z","Band":"20m","Comment":"test comment"}}
	# Use loop to print all args stored in an array called @ARGV
	my $total = $#ARGV + 1;
	my $counter = 1;
	foreach my $a(@ARGV) {
		print "Arg # $counter : $a\n" if ($verbose >= 7);
		$counter++;
		if (substr($a,0,2) eq "v=") {
			$verbose = substr($a,2,1);
			print "Debug On, Level: $verbose\n" if $verbose;
		}
	}
	print "Total args passed to $scriptname : $total \n" if $verbose;

## Bei Änderungen des Pfades bitte auch /etc/logrotate.d/rsyslog anpassen
	my $confdatei = $file_path . $scriptname . ".conf";
	open(INPUT, $confdatei) or die "Fehler bei Eingabedatei: $confdatei\n";
		undef $/;#	
		$data = <INPUT>;
	close INPUT;
	print "Datei $confdatei erfolgreich geöffnet\n" if $verbose;
	@array = split (/\n/, $data);
	$nn=0;
	$idnn = 1;
	$opnn = 1;
	$apinn = 1;
	$wcnn = 1;
	foreach $entry (@array) {
		if ((substr($entry,0,1) ne "#") && (substr($entry,0,1) ne "")) {
			printf "%d [%s]\n",$nn,$entry if ($verbose >= 4);
			$par = ($entry =~ /([\w]+).*\=.*\"(.*)\"/s)? $2 : "undef";
			$station_profile_id = $par if ($1 eq "station_profile_id");
			$cloudlogApiKeyWR = $par if ($1 eq "cloudlogApiKeyWR");
			$cloudlogApiUrlLog = $par if ($1 eq "cloudlogApiUrlLog");
			$cloudlogApiUrlFreq = $par if ($1 eq "cloudlogApiUrlFreq");
			$cloudlogRadioId = $par if ($1 eq "cloudlogRadioId");			
			$socketport =  $par if ($1 eq "socketport");
			$socketip =  $par if ($1 eq "socketip");
			$debug = $par if ($1 eq "debug");
			$station_profile_id[$idnn] = $par if ($1 eq "station_profile_id");
			++$idnn if ($station_profile_id[$idnn]);
			$station_callsign[$opnn] = $par if ($1 eq "station_callsign");
			++$opnn if ($station_callsign[$opnn]);
			$cloudlogApiBase[$apinn] = $par if ($1 eq "cloudlogApiBase");
			++$apinn if ($cloudlogApiBase[$apinn]);
			$wsjtx_config[$wcnn] = $par if ($1 eq "wsjtx_config");
			++$wcnn if ($wsjtx_config[$wcnn]);
		}
		++$nn;
	}
	$station_callsign[$opnn] = "";
	$station_profile_id[$idnn] = 0;
	$cloudlogApiBase[$apinn] = "";
	$wsjtx_config[$wcnn] = "";
	$verbose = $debug if (!$verbose);
	printf "Parameter Key: %s ID: %s URL: %s ws: %s Debug: %s\n",$cloudlogApiKeyWR,$station_profile_id,$cloudlogApiUrlLog,$socketip,$verbose if $verbose;	
	printf "%s %s %s// %s %s %s\n",$station_profile_id[1],$station_callsign[1],$wsjtx_config[1],$station_profile_id[2],$station_callsign[2],$wsjtx_config[1] if $verbose;	


#############################################################
#!/usr/bin/perl -w
# broadcast receiver script
use strict;
use diagnostics;
use Socket;

my $sock;

socket($sock, PF_INET, SOCK_DGRAM, getprotobyname('udp'))   || die "socket: $!";
setsockopt($sock, SOL_SOCKET, SO_REUSEADDR, pack("l", 1))   || die "setsockopt: $!";
#bind($sock, sockaddr_in(2237, inet_aton('224.0.0.1')))  || die "bind: $!"; 
bind($sock, sockaddr_in($socketport, inet_aton($socketip)))  || die "bind: $!"; 

# just loop forever listening for packets
# WSJT-X1 <adif_ver:5>3.1.0 <programid:6>WSJT-X <EOH>
# <call:6>EA4APX <gridsquare:4>IM89 <mode:3>FT8 <rst_sent:3>+05 <rst_rcvd:3>-16 <qso_date:8>20230216 <time_on:6>152030 <qso_date_off:8>20230216 <time_off:6>152130 <band:3>20m <freq:9>14.075599 <station_callsign:5>DL3EL <my_gridsquare:6>JO40HD <tx_pwr:3>100 <EOR>
my $testlogentry = "WSJT-X1 <adif_ver:5>3.1.0 \n<programid:6>WSJT-X <EOH> \n <call:6>EA4APX <gridsquare:4>IM89 <mode:3>FT8 <rst_sent:3>+05 <rst_rcvd:3>-16 <qso_date:8>20230216 <time_on:6>152030 <qso_date_off:8>20230216 <time_off:6>152130 <band:3>20m <freq:9>14.075599 <station_callsign:5>DL3EL <my_gridsquare:6>JO40HD <tx_pwr:3>100 <EOR>";
#	process_logentry($testlogentry);
	

    print "config read, wating for WSJT-X\n";
while (1) {
    my $datastring = '';
    my $hispaddr = recv($sock, $datastring, 512, 0); # blocking recv
    if (!defined($hispaddr)) {
        print("recv failed: $!\n");
        next;
    }
    printf "%s Länge: %d\n",$datastring,length($datastring) if ($verbose >=3);
   	($magic_number, $schema_number, $type) = unpack("H8H8H8", $datastring);
	if (($magic_number eq "adbccbda") && ($schema_number eq "00000002")) {
		$datastring = substr($datastring,12,length($datastring)-12);
		keepalive($datastring) if ($type eq "00000000");
		closewsjtx($datastring) if ($type eq "00000006");
		frequency_update($datastring) if ($type eq "00000001");
		process_logentry($datastring) if ($type eq "0000000c");
#######################################################
# evaluate new types
#		if (($type ne "00000001") && ($type ne "00000000") && ($type ne "00000002") && ($type ne "0000000c")) {
#			print "Type: $type\n";
#			print "[0x$_]" for (unpack ("(H2)*", $datastring)); #  if ($verbose > 1);	
#		}	
#######################################################
	} else {
		printf "magicnumber (should be \"adbccbda\", is %s) or schema_numer (should be \"00000002\", is %s), no further actions\n",$magic_number,$schema_number;
	}	
#### debug Log
	if ($cloudlog_updates) {
	#	DL3EL:
	#	$datastring = "<adif_ver:5>3.1.0<programid:6>WSJT-X<EOH><call:5>G0NGA <gridsquare:4>JO01 <mode:3>FT8 <rst_sent:3>-20 <rst_rcvd:3>-14 <qso_date:8>20230227 <time_on:6>110215 <qso_date_off:8>20230227 <time_off:6>110415 <band:3>20m <freq:9>14.075245 <station_callsign:5>DL3EL <my_gridsquare:6>JO40HD <tx_pwr:3>100 "; 
	#	DL0F:
#		$datastring = "<adif_ver:5>3.1.0<programid:6>WSJT-X<EOH><call:6>MW0UPH <gridsquare:4>IO82 <mode:3>FT8 <rst_sent:3>-06 <rst_rcvd:3>-10 <qso_date:8>20230227 <time_on:6>114530 <qso_date_off:8>20230227 <time_off:6>114630 <band:3>20m <freq:9>14.075159 <station_callsign:4>DL0F <my_gridsquare:6>JO40HD <tx_pwr:3>100 <operator:4>DL0F   "; 
	#####
#		process_logentry($datastring);
#		exit;
	}	
}


sub process_logentry {
my $data = $_[0];
my $nn = 0;
my $ii = 0;
my $entry;
my $item;
my $tag;
my $tags;
my $content;
my @array;
my @qso_array;
my %QSOtab;
my $station_profile_id = 0;
my $station_callsign = "";

#	print "[0x$_]" for (unpack ("(H2)*", $data));
#	print "\n[$data]\n";
	@array = split (/<EOH>|<EOR|<eor>/, $data);
	$entry = shift(@array);
	print "1.: $entry \n" if ($verbose >=1);
	$entry = shift(@array);
	print "2.: $entry \n" if ($verbose >=1);
	@qso_array = split (/\</, $entry);
	$ii = 0;
	%QSOtab = ();
	foreach $item (@qso_array) {
		$tag = ($item =~ /([\w]+):(\d+)>(.*)/s)? $1 : "undef";
		if (($tag ne "undef") && ($tag ne "")) {
			push @{$QSOtab{$tag}}, $2;
			push @{$QSOtab{$tag}}, substr($3,0,$2);
			push @{$QSOtab{$tag}}, 1;
			printf "Nr: %s, Tag: %s, Länge: %s, Inhalt: %s\n",$ii,$tag,$2,$3 if ($verbose);
			++$ii;
		}
	}	
	last if (!$ii);

	$nn = 1;
	if (exists($QSOtab{'station_callsign'})) {
		while ($station_profile_id[$nn]) {
			if ($station_callsign[$nn] eq $QSOtab{'station_callsign'}[1]) {
				$station_profile_id = $station_profile_id[$nn];
				$station_callsign = $station_callsign[$nn];
				$wsjtx_config = $wsjtx_config[$nn];
				$cloudlogApiBase = $cloudlogApiBase[$nn];
				last;
			}
			else {
				++$nn;
			}
		}			
	}
#	if (exists($QSOtab{'operator'})) {
#		if ($station_callsign ne $QSOtab{'operator'}[1]) {
#			$QSOtab{'operator'}[1] = $station_callsign;
#			$QSOtab{'operator'}[0] = length($station_callsign);
#		}
#	}		

### API/QSO
#API/QSO/
#{
#    "key":"YOUR_API_KEY",
#    "station_profile_id":"Station Profile ID Number",
#    "type":"adif",
#    "string":"<call:5>N9EAT<band:4>70cm<mode:3>SSB<freq:10>432.166976<qso_date:8>20190616<time_on:6>170600<time_off:6>170600<rst_rcvd:2>59<rst_sent:2>55<qsl_rcvd:1>N<qsl_sent:1>N<country:24>United States Of America<gridsquare:4>EN42<sat_mode:3>U/V<sat_name:4>AO-7<prop_mode:3>SAT<name:5>Marty<eor>"
#}
#

#    curl --silent --insecure \
#        --header "Content-Type: application/json" \
#         --request POST \
#         --data "{ 
#           \"key\":\"$cloudlogApiKey\",
#           \"radio\":\"$cloudlogRadioId\",
#           \"frequency\":\"$rigFreq\",
#           \"mode\":\"$rigMode\",
#           \"timestamp\":\"$(date +"%Y/%m/%d %H:%M")\"
#         }" $cloudlogApiUrl >/dev/null 2>&1
#	$apicall = `curl -s https://pskreporter.info/cgi-bin/psk-freq.pl?grid=JO&mode=FT8`; 
# curl --silent --insecure --header "Content-Type: application/json" --request POST --data

my $apistring_fix = sprintf("{\\\"key\\\":\\\"%s\\\",\\\"station_profile_id\\\":\\\"%s\\\",\\\"type\\\":\\\"adif\\\",\\\"string\\\":\\\"",$cloudlogApiKeyWR,$station_profile_id);
my $apistring_var = "";
my $apicall = "";

	$nn=0;
	for my $tag (sort keys %QSOtab) {
		if ($QSOtab{$tag}[2]) {
			$tags = $tag;
			++$nn;
			$apistring_var = $apistring_var . sprintf("<$tags:$QSOtab{$tag}[0]>$QSOtab{$tag}[1]");
		}	
	}
	if ($ii != $nn) {
		print "$QSOtab{'CALL'}[1] CHECK ITEMS! ($ii/$nn) \n" if $verbose;
	}	

	$apistring_fix = $apistring_fix . $apistring_var . "<EOR>\\\"}";
	$apicall = sprintf("curl --silent --insecure --header \"Content-Type: application/json\" --request POST --data \"%s\" %s%s >/dev/null 2>&1\n",$apistring_fix,$cloudlogApiBase,$cloudlogApiUrlLog);
	if (($station_profile_id) && ($cloudlog_updates)) {
		print "$apicall sent to Cloudlog\n";
		`$apicall`;
	}
	else {
		print "Error $apicall not sent to Cloudlog (Check Station_ID or WSJT-X Config)\n";
	}		

########### Logentry should be sent to a second server, eg backup, place the code here
#	if ($QSOtab{'station_callsign'}[1] eq "DL3EL") {
#		my $apistring_fix_DL3EL = sprintf("{\\\"key\\\":\\\"cl6374d0438d61f\\\",\\\"station_profile_id\\\":\\\"1\\\",\\\"type\\\":\\\"adif\\\",\\\"string\\\":\\\"%s<EOR>\\\"}",$apistring_var);
#		$apicall = sprintf("curl --silent --insecure --header \"Content-Type: application/json\" --request POST --data \"%s\" http://192.168.241.99/index.php/api/qso >/dev/null 2>&1\n",$apistring_fix_DL3EL);
#		print "sent to DL3EL Cloudlog:\n $apicall\n";
#		my $dl3el = `$apicall`;
#		print "Returnvalue ($dl3el)\n" if ($dl3el ne "");
#	}	
###########

}	

sub frequency_update {
# example what to to with the data other than log entry: switch Antenna
	my $data = $_[0];
	my $datal = 0;
	my $nn = 0;
	my $newqrg = "";
	my $newmode = "";
	my $newband = "";
	my $band_length = 0;
	my $call;
	my $config;

	$datal = length($data);
#	print "[0x$_]" for (unpack ("(H2)*", $data));	
	print "\n Länge: $datal\n" if ($verbose >= 2);

	if (!$band_length) {
		$newband = $band;
		$newqrg = $qrg;
		$newmode = $mode;
	}	
	if (parse_wsjtx_data($data,$datal,$newqrg,$newmode,$call,$config)) {
		printf "got valid data: %s %s %s %s\n",$newqrg,$newmode,$call,$config if ($verbose >= 2);
		if ($newqrg) {
			$band_length = (length($newqrg) > 7)? 2 : 1;
			$newband = substr($qrg,0,$band_length);
			cloudlog_updates(1);
		} else {
			$newband = $band;
			cloudlog_updates(0);
		}	
	} else {
		$tm = localtime(time);
		printf("WSJT-X Cloudlog Connector @ %02d:%02d:%02d am %02d.%02d.%04d\n",$tm->hour, $tm->min, $tm->sec, $tm->mday, $tm->mon,$tm->year) if $cloudlog_updates;
		printf "got invalid data: %s %s %s %s\n",$newqrg,$newmode,$call,$config; #  if ($verbose >= 2);
		cloudlog_updates(0);
	}	
	

	$nn = 1;
#	if (($wsjtx_config eq "?") || ($wsjtx_config ne $config)){
	if ($wsjtx_config ne $config) {
		$wsjtx_config = "?";
		while ($station_profile_id[$nn]) {
			if ($wsjtx_config[$nn] eq $config) {
				$station_profile_id = $station_profile_id[$nn];
				$station_callsign = $station_callsign[$nn];
				$wsjtx_config = $wsjtx_config[$nn];
				$cloudlogApiBase = $cloudlogApiBase[$nn];
				cloudlog_updates(1);
				$tm = localtime(time);
				printf("WSJT-X Cloudlog Connector @ %02d:%02d:%02d am %02d.%02d.%04d\n",$tm->hour, $tm->min, $tm->sec, $tm->mday, $tm->mon,$tm->year);
				printf "WSJT-X Config (%s) in use, now updating Cloudlog with call $station_callsign \nin Logbook $station_profile_id at $cloudlogApiBase\n",$config;
				last;
			}
			else {
				++$nn;
			}
		}			
		if ($wsjtx_config eq "?") {
			printf "WSJT-X Config in use (%s) is not configured, no updates from Coudlog are possible\n",$config;
			cloudlog_updates(0);
		}	
	}
	printf "Check Call: %s, Config: %s, Freq: %s, Mode: %s Station_profile_id: %s, station_callsign: %s (Cloudlog Updates: %s)\n",$call, $config, $newqrg, $newmode,$station_profile_id,$station_callsign,$cloudlog_updates if ($verbose >= 3);
	

	if ($newband ne $band) {
		printf "new qrg:%s(%s) Oldqrg:%s OldMhz:%s NewMHz:%s\n",$newqrg,length($newqrg),$qrg,$band,$newband if $verbose; 
		$band = $newband;
		printf "switch_antenna to %sMHz\n",$band;
		###########################
		# place code fro switching antennas here
		###########################
	}
	
	if (((!$polling) || ($newqrg ne $qrg) || ($newmode ne $mode)) && $cloudlog_updates) {
		$polling = 5;
		$qrg = $newqrg;
		$mode = $newmode;

		my $apistring_fix = sprintf("{\\\"key\\\":\\\"%s\\\",\\\"radio\\\":\\\"%s\\\",\\\"frequency\\\":\\\"%s\\\",\\\"mode\\\":\\\"%s\\\"}",$cloudlogApiKeyWR,$cloudlogRadioId,$qrg,$mode);
		my $apicall = sprintf("curl --silent --insecure --header \"Content-Type: application/json\" --request POST --data \"%s\" %s%s >/dev/null 2>&1\n",$apistring_fix,$cloudlogApiBase,$cloudlogApiUrlFreq);
		print $apicall if $verbose;
		`$apicall`;
	} else {
		--$polling;
	}	
}	

sub keepalive {
	my $data = $_[0];
	my $datal = 0;
	my $pos = 0;
	my $length;
	my $value;

#	print "[0x$_]" for (unpack ("(H2)*", $data));	
	$datal = length($data);
	print "\nKeepalive Länge: $datal\n" if ($verbose >= 1);

	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "Keepalive from ID: %s \n",$value if ($verbose >= 1);
}

sub closewsjtx {
	my $data = $_[0];
	my $datal = 0;
	my $pos = 0;
	my $length;
	my $value;

#	print "[0x$_]" for (unpack ("(H2)*", $data));	
	$datal = length($data);
	print "\n close wsjtx Länge: $datal\n" if ($verbose >= 1);

	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "ID: %s closed\n",$value if ($verbose >= 1);
	cloudlog_updates(0);
}	

sub	parse_wsjtx_data {
	my $data = $_[0];
	my $datal = $_[1];
	my $newqrg = $_[2];
#	my $newmode = $_[3];
#	my $station_callsign = $_[4];
#	my $config = $_[5];
	my $pos = 0;
	my $data_exam;
	my $length;
	my $value;
	
# currently needed:
# qrg, mode, station_call, config	
	if ($datal < 30) {
		print "data to short, min 30 (real: $datal)\n";
		return (0);
	}	
	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "Unique ID: %s Pos:%d\n",$value,$pos if ($verbose >= 3);

	$data_exam = substr($data,$pos,8);
	($newqrg) = unpack("H*", $data_exam);
	$newqrg =  hex($newqrg);
	$pos += 8;
	printf "QRG: %s\n",$newqrg if ($verbose >= 2);
	$_[2] = $newqrg;
	
	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "Mode: %s\n",$value if ($verbose >= 2);
	$_[3] = $value;

	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "DxCall : %s\n",$value if ($verbose >= 3);

	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "RST : %s\n",$value if ($verbose >= 3);

	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "TXMode : %s\n",$value if ($verbose >= 3);

	$pos = $pos + 11;
	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "Call : %s\n",$value if ($verbose >= 2);
	$_[4] = $value;

	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "GRID : %s\n",$value if ($verbose >= 3);

	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "dxGRID : %s\n",$value if ($verbose >= 3);

	$pos = $pos + 1;
	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "SubMode : %s\n",$value if ($verbose >= 3);

	$pos = $pos + 10;
	get_wsjtx_utf8($data,$pos,$length,$value);
	printf "Config : %s\n",$value if ($verbose >= 2);
	$_[5] = $value;
	return (1);
}

sub get_wsjtx_utf8 {
	my $data = $_[0];
	my $pos = $_[1];
	my $length = $_[2];
	my $value = $_[3];
	my $data_exam = "";
	$length = 0;
	$value = "";

	$data_exam = substr($data,$pos,4);
# print "[0x$_]" for (unpack ("(H2)*", $data_exam));	
	($length) = unpack("H8", $data_exam);
	$length =~ s/(..)/hex($1)/eg;
	$pos = $pos + 4;
	if (($length) && ($length != 255255255255)) {
		printf "Length : %d\n",$length if ($verbose >= 3);
		$data_exam = substr($data,$pos,$length);
		($value) = unpack("H*", $data_exam);
		$value =~ s/(..)/chr(hex($1))/eg;
		printf "Value: %s\n",$value if ($verbose >= 3);
		$pos = $pos + $length;
	}
	$_[0] = $data;
	$_[1] = $pos;
	$_[2] = $length;
	$_[3] = $value;
	
}	

sub cloudlog_updates {
	if ($cloudlog_updates != $_[0]) {
		my $status = ($_[0])? "acivte" : "inactive";
		$tm = localtime(time);
		printf("Cloudlog updates are $status @ %02d:%02d:%02d am %02d.%02d.%04d\n",$tm->hour, $tm->min, $tm->sec, $tm->mday, $tm->mon,$tm->year) if $cloudlog_updates;
	}	
	$cloudlog_updates = $_[0];
}	
	
#a)[0x00][0x00][0x00][0x04][0x45][0x43][0x33][0x41]				EC3A DXc
#b)[0x00][0x00][0x00][0x00]												dx call
#c)[0xff][0xff][0xff][0xff]											dx call


####################### WSJT-X UDP Message Protocoll
# 	print "[0x$_]" for (unpack ("(H2)*", $data));
# ($kanal, $freq, $shift, $trailing) = unpack("A6 x2 A8 A7 A*", $_);

#[0xad][0xbc][0xcb][0xda] 				32-bit unsigned integer magic number 0xadbccbda      4 byte
#[0x00][0x00][0x00][0x02] 				32-bit unsigned integer schema number
#[0x00][0x00][0x00][0x01]				1                      quint32
#[0x00][0x00][0x00][0x06]							length
#[0x57][0x53][0x4a][0x54][0x2d][0x58]	WSJT-X
#[0x00][0x00][0x00][0x00][0x01][0x41][0x82][0x5e]				QRG (30)
#[0x00][0x00][0x00][0x03][0x46][0x54][0x38]						FT8
#[0x00][0x00][0x00][0x04][0x45][0x43][0x33][0x41]				EC3A DXc
#[0x00][0x00][0x00][0x03][0x2d][0x31][0x35]					-15 rst
#[0x00][0x00][0x00][0x03][0x46][0x54][0x38]					FT8 tx mode
#[0x00][0x00][0x00]											3x Bool
#[0x00][0x00][0x06][0x69]									rx df
#[0x00][0x00][0x04][0xc5]									tx df
#[0x00][0x00][0x00][0x05][0x44][0x4c][0x33][0x45][0x4c]				DL3EL
#[0x00][0x00][0x00][0x06][0x4a][0x4f][0x34][0x30][0x48][0x44]			JO40HD de grid
#[0xff][0xff][0xff][0xff]												dx grid leer
#[0x00]															bool
#[0xff][0xff][0xff][0xff]													sub mode
#[0x00]																fast mode bool
#[0x00]																spec ops
#[0xff][0xff][0xff][0xff]											freq tol
#[0xff][0xff][0xff][0xff]											T/R period
#[0x00][0x00][0x00][0x0b][0x46][0x54][0x31][0x30][0x30][0x30][0x20][0x44][0x4b][0x49][0x49] FT1000DKII
#[0xff][0xff][0xff][0xff]
##############################FT1000 DK2
# unpack("H8H8H8x14H8x3H2H8x28H4H16x28H4H32", $data);
#[0xad][0xbc][0xcb][0xda]
#[0x00][0x00][0x00][0x02]
#[0x00][0x00][0x00][0x01]												12 3xH8
#[0x00][0x00][0x00][0x06][0x57][0x53][0x4a][0x54][0x2d][0x58]				idetn wsjt-x
#[0x00][0x00][0x00][0x00][0x00][0x6b][0xf0][0xee]																								04 H814qrg (30)
#[0x00][0x00][0x00][0x03][0x46][0x54][0x38]										ft8 mode
#[0xff][0xff][0xff][0xff]											dx call
#[0x00][0x00][0x00][0x03][0x2d][0x31][0x35]							rst
#[0x00][0x00][0x00][0x03][0x46][0x54][0x38]
#[0x00][0x00][0x00]
#[0x00][0x00][0x05][0xdc]
#[0x00][0x00][0x05][0xdc]
#[0x00][0x00][0x00][0x05][0x44][0x4c][0x33][0x45][0x4c]
#[0x00][0x00][0x00][0x06]#[0x4a][0x4f][0x34][0x30][0x48][0x44]				JO40HD
#[0xff][0xff][0xff][0xff]		
#[0x00]
#[0xff][0xff][0xff][0xff]
#[0x00]
#[0x00]
#[0xff][0xff][0xff][0xff]
#[0xff][0xff][0xff][0xff]
#[0x00][0x00][0x00][0x0b][0x46][0x54][0x31][0x30][0x30][0x30][0x20][0x44][0x4b][0x49][0x49] FT1000DKII			
#[0xff][0xff][0xff][0xff] 
#############																														123
#[0xad][0xbc][0xcb][0xda]
#[0x00][0x00][0x00][0x02]
#[0x00][0x00][0x00][0x01]
#[0x00][0x00][0x00][0x06][0x57][0x53][0x4a][0x54][0x2d][0x58]			10
#[0x00][0x00][0x00][0x00][0x00][0xd6][0xbe][0x9c]		qrg				8
#[0x00][0x00][0x00][0x03][0x46][0x54][0x38]						ft8 mode  -> bishier gleich
#[0x00][0x00][0x00][0x00]												dx call
#[0x00][0x00][0x00][0x02][0x2d][0x39]						rst
#[0x00][0x00][0x00][0x03][0x46][0x54][0x38]					tx mode
#[0x00][0x00][0x01]
#[0x00][0x00][0x09][0x7e]
#[0x00][0x00][0x06][0xa8]
#[0x00][0x00][0x00][0x05][0x44][0x4c][0x33][0x45][0x4c]			call
#[0x00][0x00][0x00][0x06][0x4a][0x4f][0x34][0x30][0x48][0x44]	de grid
#[0x00][0x00][0x00][0x00]											dx grid
#[0x00]							bool
#[0xff][0xff][0xff][0xff]
#[0x00]						fast mode
#[0x00]								spec ops
#[0xff][0xff][0xff][0xff]
#[0xff]#[0xff][0xff][0xff]
#[0x00]#[0x00][0x00][0x0b][0x46][0x54][0x31][0x30][0x30][0x30][0x20][0x44][0x4b][0x49][0x49]
#[0x00][0x00][0x00][0x25][0x43][0x4e][0x38][0x5a][0x47][0x20][0x44][0x4c][0x33][0x45][0x4c][0x20][0x52][0x2d][0x30][0x39][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20][0x20]
