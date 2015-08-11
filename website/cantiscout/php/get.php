<?php
	include('query.php');
	
	@$data=$_GET['max'];
	
	if(checkData($data)){
		class Update{
			public $songlist="";
			public $taglist="";
		}
		$out=new Update();
		$out->songlist=getListOfSongAfter($data);
		$out->taglist=getListOfTagAfter($data);		
		echo json_encode($out);
	}else
		echo "204";
?>
