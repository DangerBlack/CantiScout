<?php
	 $path="res/crd/";
	 $filename="Come Maria.crd";
	 $listOfFile=scandir($path); 
	 for($i=2;$i<count($listOfFile);$i++){
		 $filename=$listOfFile[$i];
		 $body=file_get_contents($path.$filename);
		 
?>
