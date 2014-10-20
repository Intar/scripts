<?php
function getDownloadSpeed($serverAddress)
{
    $tempfile = '/tmp/1mb.test-'.time();
    exec('wget http://'.$serverAddress.'/1mb.test?a='.time().' -O '.$tempfile. ' ~ 2>&1', $out);
    unlink($tempfile); 
    foreach($out as $line){
        if (preg_match('#[\d:\s-]+\((.*?)\).*?saved#', $line, $matches)) {
            return $matches[1]; } } } 
function getPing($ip=NULL) {
                $exec = exec("ping -c 3 -s 64 -t 64 ".$ip); 
                $array = explode("/", end(explode("=", $exec )) ); 
                return ceil($array[1]) . 'ms';
                }
function testServer($serverAddress) { 
    $ping = getPing($serverAddress); 
    $download = getDownloadSpeed($serverAddress); 
    #echo "Ping test: ".$ping."\n"; 
    #echo "Download speed test: ".getDownloadSpeed($serverAddress)."\n";
    echo getDownloadSpeed($serverAddress);
    #file_put_contents('test-vps-'.$serverAddress.'.log', date('d.m.Y H:i:s').'|'.$ping.'|'.$download."\n", FILE_APPEND);
    }
#$e=$argv[1];
testServer("1.1.1.1");
?>
