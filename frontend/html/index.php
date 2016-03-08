<html>
	<!-- the frontend code is very very very ugly but works for the moment. -->
	<!-- If you want to do it nice, drop me a message or pull request, thanks :-) -->
	<head>
		<meta http-equiv="refresh" content="60" charset="utf-8">	<!--HTML-AUTOREFRESH de page alle 60 Sec-->
		<link rel="stylesheet" type="text/css" href="tsstatus.css" /> <!--fuer TS3 Server view-->
		<script type="text/javascript" src="tsstatus.js"></script> <!--fuer TS3 Server view-->
		
		<LINK REL="SHORTCUT ICON" HREF="https://www.moerbst.de/favicon.ico">
	</head>
	<body background="img/wallpaper.jpg" id="startseite"> 

	<div id="headerimage" style="border-width:0px;border-style:solid;width:700px; margin: auto;">
		<img src="img/header-grumpy.png" alt="header-moerbst-de"> 
	</div>
	<div id="nav" style="background-color:#e6e6e6; width: 210px; padding: 0px; margin: 0px auto; float: left" >
		<?php 
			require_once("/var/www/ts3/tsstatus.php"); 
			$tsstatus = new TSStatus("127.0.0.1", 10011, 1); 
			$tsstatus->imagePath = "img/"; 
			$tsstatus->showNicknameBox = false; 
			$tsstatus->showPasswordBox = false; 
			$tsstatus->timeout = 2; 
			$tsstatus->setCache(60); 
        		$tsstatus->setCache(60, "/tmp/ts3statusphpviewer.cache"); 
        		$tsstatus->setLoginPassword("queryuser", "querypassword"); 
			echo $tsstatus->render(); 
		?>
	</div>


	<div id="toplist" style="background-color:#e6e6e6; width: 280px; padding: 0px; margin: 0px auto; float: right;">
	<?php
		include 'highscore.php';
	?>
	</div>


	<div id="main" style="border-width:0px;border-style:solid;width:947px; margin: auto;">
		<img src="https://moerbst.de/munin/localdomain/localhost.localdomain/ts3top_users_by_countries-day.png"></img>
		<img src="https://moerbst.de/munin/localdomain/localhost.localdomain/ts3top_channels_by_minutes-day.png"></src>
	</div>

	<div id="footer" style="border-width:0px;border-style:solid;width:100px; margin: auto;">
		<br/>
		<a href="https://moerbst.de/munin/localdomain/localhost.localdomain/index.html#teamspeak" data-toggle="tooltip" title="Gimme more stats!!"><img src="img/morestats-48x48.png"></img></a>
		<a href="https://moerbst.de/aliases.txt" data-toogle="tooltip" title="show player aliases"><img src="img/aliases-48x48.png"></img></a>
	</div>
	</body>
</html>

