<?php
	include('query.php');
	$id_song=$_GET['id'];
	echo json_encode(getListOfTagById($id_song));
?>
