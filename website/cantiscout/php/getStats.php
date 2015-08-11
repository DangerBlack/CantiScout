<?php
	include('query.php');
	$kind=$_GET['stats'];
	switch($kind){
		case 'song':
			echo getNumberOfSong();
			break;
		case 'user':
			echo getNumberOfUser();
			break;
		case 'tag':
			echo getNumberOfTag();
			break;
		case 'tagList':
			echo json_encode(getTagList());
			break;
		
	}

?>
