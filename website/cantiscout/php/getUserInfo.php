<?php
	include "query.php";
	if(isLogged()){
		//$id=getId();
		//echo json_encode(getUser($id));
		echo '[{"name":"Danger","avatar":"https://dl.dropboxusercontent.com/u/23040379/mySelfPirate.png"}]';
	}else{
		echo 404;
	}

?>
