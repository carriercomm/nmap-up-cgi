#!/usr/bin/perl -w
use WWW::Mechanize;
use HTML::Manipulator;
$now = localtime;
$alert = 0;
$action = "";
my $mech = WWW::Mechanize->new( autocheck => 1 );
my $url = 'http://neufbox/network/dns';
$mech->get($url);
$mech->submit_form(
form_id => 'form_auth_passwd',
fields => {
	login    => 'admin',
	password    => 'password',
	}
);

my $hostlist = HTML::Manipulator::extract_content( $mech->content(), 'dnshosts_config');
$hostlist =~ s/^\s*//gmx;
$hostlist =~ s/^\<.*//gmx;
$hostlist =~ s/.*=.*//gmx;
$hostlist =~ s/^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\s*//gmx;
$hostlist =~ s/^[0-9]*\s//gmx;
#$hostlist =~ s/\n/ /gmx;
#print $hostlist,qq{\n};

@cmd = `nmap -sP 192.168.1.1-254`;
#open ( HOSTLIST, "<", "/usr/local/groadmin/hostlist.txt" );
#push @hostlist, <HOSTLIST>;
#$hostlist = join( " ", @hostlist );
#print $hostlist,qq{\n};
#close( HOSTLIST );
#
foreach( @cmd ){
    for( $_ =~ m/(\d+\.\d+\.\d+\.\d+)/ ){
	( $ip = $_ );
	$ipcell = qq{<tr><td>$ip</td>};
	push @table, $ipcell;
        $name = `nslookup $ip`;
	$name =~ s/\n/ /gmx;
	@name = ( $name =~ m/name\s=\s(.*)\./ );
	( $name = $name[0] );
	#print qq{$ip },$name,qq{\n};
	if( $name ){
	    if( $hostlist =~ m/$name/m ){
		    $namecell = qq{<td>$name</td></tr>};
		    push @table, $namecell;
            }else{
		    $namecell = qq{<td><div class="unknown">$name : INCONNU</div></td></tr>};
		    $alert = 1;
		    push @table, $namecell;
		    push @unk, $namecell;
	    }
        }else{
	    $cell = qq{<td><div class="unknown">INCONNU</div></td></tr>};
            push @table, $cell;
	    push @unk, $namecell;
	    $alert = 1;
        }	    
    }
    $return = qq{\n};
    push @table, $return;
}
$unknb = \@unk;
$dispnb = @$unknb;
if($alert == 1){
    $action = qq{onload="flashTitle('***INCONNUS***($dispnb)', 60);"};
    }
print <<HTML;
<html>
<head>
<META HTTP-EQUIV="refresh" CONTENT="60">
<title>SCAN NMAP</title>
<style type="text/css">
table{background:white;-moz-box-sizing:content-box;-webkit-box-sizing: content-box;box-sizing: content-box;width: auto;-webkit-border-radius: 10px 10px 10px 10px; border-radius: 10px 10px 10px 10px; -webkit-box-shadow: 0px 0px 3px 0px #000000; box-shadow: 0px 0px 3px 0px #000000;padding: 7px;} 
tr{border:none;color: #0174DF;font-family: "Franklin Gothic Demi", Verdana, Arial, sans-serif;text-decoration: none }
.unknown{color:red;}
body{ background:#A9E2F3;}
</style>
</head>
<body $action>
<table>
HTML
foreach(@table){
    print $_;

}
print qq{</table><br>$now\n};
print <<SCRIPT;
<script>
(function () {

var original = document.title;
var timeout;

window.flashTitle = function (newMsg, howManyTimes) {
    function step() {
        document.title = (document.title == original) ? newMsg : original;

        if (--howManyTimes > 0) {
            timeout = setTimeout(step, 1000);
        };
    };

    howManyTimes = parseInt(howManyTimes);

    if (isNaN(howManyTimes)) {
        howManyTimes = 5;
    };

    clearTimeout(timeout);

    step();
};

window.cancelFlashTitle = function () {
    clearTimeout(timeout);
    document.title = original;
};

}());
</script>
SCRIPT
print qq{</body></html>\n};
