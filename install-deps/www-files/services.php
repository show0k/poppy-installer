 <!DOCTYPE html>
<html>
<head>
<title>Poppy script page</title>
</head>
<body>
<link rel="stylesheet" type="text/css" href="css/style.css" />
<?php
function tty($kill) {
	if($kill == true) {
		exec('fuser -k /dev/ttyACM0');
	} else {
		exec('fuser /dev/ttyACM0');
	}
}

// Start python only if not previously started
if($_GET["python"] === "start") {
	echo "python start";

	if (exec('fuser /dev/ttyACM0') == NULL){
		echo "/dev/ttyACM0 is free";
		// Start poppy-services
		exec('POPPY_SERVICE_PATH poppy-torso --http --snap --no-browser > services.log 2>&1 &');
	              
    }
} elseif($_GET["python"] === "restart") {
	echo "Restart python";
	exec('fuser -k /dev/ttyACM*');
	exec('POPPY_SERVICE_PATH poppy-torso --http --snap --no-browser > services.log 2>&1 &');
} elseif($_GET["python"] === "stop") {
        echo "Stop python";
        exec('fuser -k /dev/ttyACM*');
        # Redirect to home page
        echo "
                <script type=\"text/javascript\">
                document.location.href=\"index.html\"
                </script>
            ";
} elseif($_GET["python"] === "update") {
        echo "Not implemented";
} 

if($_GET["web"] === "snap"){
	echo "Snap redirection";
	echo "
           	<script type=\"text/javascript\">
            	document.location.href=\"snap/\"
		</script>
       	";
}
if($_GET["web"] === "poppy-monitor"){
	echo "
                <script type=\"text/javascript\">
                document.location.href=\"poppy-monitor/\"
                </script>
	";
}
?>
</body>

</html>

