<?php
	include('query.php');
	@$kind=$_POST['kind'];
	if(isLogged()){
		$id_user=getId();
		switch($kind){
			case 0://name
				@$name=$_POST['name'];
				updateUserName($name);
			break;
			case 1://password
				@$newPswd=$_POST['newPswd'];
				@$oldPswd=$_POST['oldPswd'];
				updateUserPswd($oldPswd,$newPswd);
			break;
			case 2://picture
				@$picture=$_POST['picture'];
				updateUserPicture($picture);
			break;
			case 3://description
				@$description=$_POST['description'];
				updateUserDesc($description);
			break;
		}
		return 202;
	}else{
		return 403;
	}
	
?>
