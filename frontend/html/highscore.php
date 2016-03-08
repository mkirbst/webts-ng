<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>moerbst.de TS3-Top10 </title>
        <link rel="stylesheet" href="css/style.css" type="text/css">
</head>

<body>

<div id="container" style="font-family: Lucida Console; font-size: 32px; font-style: normal;">

<style>
	table, td, th {
	    font-family: Lucida Console; font-size: 12px; font-style: normal;
	}
	
	table {
	    border-collapse: collapse;
	    width: 100%;
	}
	p {
	    font-family: Lucida Console; 
	    font-size: 10px; 
            font-style: normal; 
	    vertical-align: right;
	    text-align: center;
	}
</style>


<table>
    <caption><b>HIGHSCORE</b></caption>
                <thead>
                <tr>
                                <th></th>
                                <th></th>
                                <th></th>
                                <th align="left">nickname</th>
                                <th align="right">time on server</th>
            </tr>
                </thead>
        <tbody>
<?php 	

$COUNTER=1;

function secondsToTime($inputSeconds) {

    $secondsInAMinute = 60;
    $secondsInAnHour  = 60 * $secondsInAMinute;
    $secondsInADay    = 24 * $secondsInAnHour;

    // extract days
    $days = floor($inputSeconds / $secondsInADay);

    // extract hours
    $hourSeconds = $inputSeconds % $secondsInADay;
    $hours = floor($hourSeconds / $secondsInAnHour);

    // extract minutes
    $minuteSeconds = $hourSeconds % $secondsInAnHour;
    $minutes = floor($minuteSeconds / $secondsInAMinute);

    // extract the remaining seconds
    $remainingSeconds = $minuteSeconds % $secondsInAMinute;
    $seconds = ceil($remainingSeconds);

    // return the final array
    $obj = array(
        'd' => (int) $days,
        'h' => (int) $hours,
        'm' => (int) $minutes,
        's' => (int) $seconds,
    );

//	$res= $days."d".$hours."h".$minutes."m";

	if($days > 0)
	{
		$res = $days."d";
	}
	
	if($hours > 0)
	{
		$res = $res.$hours."h";
	}

	if($minutes > 0)
	{
		$res = $res.$minutes."m";
	}

	return $res;
}



// Verbindung aufbauen, auswählen einer Datenbank
// $link = mysql_connect("127.0.0.1", "ts3queryuser", "Start123!")
$link = mysql_connect("localhost", "ts3queryuser", "mysqlpassword")
    or die("Keine Verbindung möglich: " . mysql_error());
# echo "Verbindung zum Datenbankserver erfolgreich";
mysql_select_db("ts3db") or die("Auswahl der Datenbank fehlgeschlagen");

// only users with at least 2h online time on server, max 64 users
$query = "SELECT online,country,CLNAME,Minutes FROM ts3top  WHERE clname NOT LIKE '%bot%' AND clname NOT LIKE  '%127.0.0.1%' AND Minutes > 120 ORDER BY Minutes DESC, CLDBID ASC LIMIT 64";
$result = mysql_query($query) or die("Anfrage fehlgeschlagen: " . mysql_error());

// Ausgabe der Ergebnisse in HTML
while ($line = mysql_fetch_array($result, MYSQL_ASSOC)) {
//	$col = "#e6e6e6";
	$led ="off";
	$n=0;
    
//    echo "<td>".$COUNTER++."</td>";
     echo "<tr>";
     foreach ($line as $col_value) {
	$n++;

//online
	if($n == 1)
	{
		if($col_value==1)
		{
			$col="green";
			$led ="on";
		}
	}
//country
        else if($n == 2) 
	{	## country
        	echo "<td align=\"right\">";

		if($col_value != "")	//## if no country code is given, set - to load the -.png flag picture (empty flag) 
		{
        		echo "<img height=16 src=\"https://moerbst.de/img/flags/"   .   strtolower($col_value)   .   ".png\"></img>" ;
		}
        } 
//nickname
	else if ($n == 3)	//## nickname add gold silver bronze to top3
	{
        	echo "<td align=\"left\">";
		
		if($COUNTER == 1)
		{
			echo "<td align=\"center\"><img width=24 src=\"https://moerbst.de/img/highscore/gold.png\"></img></td> <td><img width=11 src=\"img/led-".$led."-green-16x16.png\"></img>".$col_value."</td>";
		}
		else if($COUNTER == 2)
		{
			echo "<td align=\"center\"><img width=24 src=\"https://moerbst.de/img/highscore/silber.png\"></img></td> <td><img width=11 src=\"img/led-".$led."-green-16x16.png\"></img>".$col_value."</td>";
		}
		else if($COUNTER == 3)
		{
			echo "<td align=\"center\"><img width=24 src=\"https://moerbst.de/img/highscore/bronze.png\"></img></td> <td align=\"left\"><img width=11 src=\"img/led-".$led."-green-16x16.png\"></img>".$col_value."</td>";
		}
		else 
		{
			echo "<td align=\"center\"><b>$COUNTER</b></td> <td><img width=11 src=\"img/led-".$led."-green-16x16.png\"></img>".substr($col_value, 0, 20)."</td>";
		}
	} 
//time
	else if($n == 4) 
	{
	        echo "<td align=\"right\">";
        	echo secondsToTime($col_value*60);
        } 

	else {
//                echo $col_value;
	}
        
        echo "</td>\n";
    }
    $COUNTER++;
    echo "<tr/>";
}

// Freigeben des Resultsets
mysql_free_result($result);

// Schliessen der Verbinung
mysql_close($link);

?>

        </tbody>
	</table>
<p>- hint: you have to stay at least 2h on server to get ranked -</p>
</div>
</body>
</html>

