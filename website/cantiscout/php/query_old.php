<?php
	function make_connession()
	{
		$dbhost='localhost'; 
		$dbname='cantiscout';
		$dbpassword='cantiscout';
		$connessione = mysql_connect($dbhost,$dbname,$dbpassword)or die("Connessione non riuscita: " . mysql_error());
    	//print ("Connesso con successo");
		mysql_select_db($dbname, $connessione) or die("Errore nella selezione del database");
		return $connessione;
	}
	function make_query($connessione,$query_string){
		$query = mysql_query($query_string,$connessione);
		if ($query==FALSE) die("errore nella composizione della query ".$query_string);
		mysql_close($connessione);
		return $query;
	}
	function safe($value){ 
		return mysql_real_escape_string($value); 
	}
	function make_easy_connession($query_string){
		make_query(make_connession(),$query_string);
	}
	function checkLogin($mail,$pswd)
	{
		if(($pswd!=null)&&($pswd==getPswd($mail))){
			return true;
		}else{
			return false;
		}
	}
	function isLogged(){ 
		$user= $_COOKIE["mail"];
		$pswd= $_COOKIE["pswd"];
		return checkLogin($user,$pswd);
	}
	function getPswd($mail) 
	{
		$connessione=make_connession();
		$mail=safe($mail);
		$query_string="SELECT pswd FROM user WHERE mail='".$mail."'";
		$query=make_query($connessione,$query_string);
		$row=mysql_fetch_array($query);
		return $row['pswd'];
	}
	function getIdFromMail($mail){
		$connessione=make_connession();
		$mail=safe($mail);
		$query_string="SELECT id FROM user WHERE mail='".$mail."'";
		$query=make_query($connessione,$query_string);
		$row=mysql_fetch_array($query);
		return $row['id'];
	}
	function getMailFromId($id){
		$connessione=make_connession();
		$id=safe($id);
		$query_string="SELECT mail FROM user WHERE id='".$id."'";
		$query=make_query($connessione,$query_string);
		$row=mysql_fetch_array($query);
		return $row['mail'];
	}
	function insertUser($mail,$pswd)
	{
		$connessione=make_connession();
		$mail=safe($mail);
		$pswd=safe($pswd);
		$query_string="INSERT INTO user (mail,pswd) ". 
		"VALUES ('".$mail
			."','".$pswd
			 ."')";
		return make_query($connessione,$query_string);
	}
	function insertSong($title,$author,$body,$id_user)
	{
		$connessione=make_connession();
		$title=safe(ucfirst($title));
		$author=safe($author);
		$body=safe($body);
		$id_user=safe($id_user);
		$query_string="INSERT INTO list (title,author,body,id_user) ". 
		"VALUES ('".$title
			."','".$author
			 ."','".$body
			 ."','".$id_user
			 ."')";
		return make_query($connessione,$query_string);
	}
	function updateSong($id,$title,$author,$body,$id_user)
	{
		$connessione=make_connession();
		$title=safe(ucfirst($title));
		$author=safe($author);
		$body=safe($body);
		$id_user=safe($id_user);
		$query_string="UPDATE list SET ". 
		"title='".$title
			."', author='".$author
			 ."', body='".$body
			 ."', id_user='".$id_user
			 ."', time=NOW() WHERE id='".$id."'";
		return make_query($connessione,$query_string);
	}
	function insertLog($id_user,$id_song){
		$connessione=make_connession();
		$id_song=safe($id_song);
		$ip=safe($_SERVER['REMOTE_ADDR']);
		$ip_prox=safe($_SERVER['HTTP_X_FORWARDED_FOR']);
		$query_string="INSERT INTO log (id_user,id_list,ip,ip_prox) ". 
		"VALUES ('".$id_user
			."','".$id_song
			."','".$ip
			 ."','".$ip_prox
			 ."')";
		return make_query($connessione,$query_string);
	}
	function logHistory($id_song){
		$song=getSong($id_song)[0];
		$connessione=make_connession();
		$title=safe(ucfirst($song->title));
		$author=safe($song->author);
		$body=safe($song->body);
		$id_user=safe($song->id_user);
		$time=safe($song->time);
		$query_string="INSERT INTO history (id_list,title,author,body,id_user,time) ". 
		"VALUES ('".$id_song
			 ."','".$title
			 ."','".$author
			 ."','".$body
			 ."','".$id_user
			 ."','".$time
			 ."')";
		return make_query($connessione,$query_string);
	}
	function insertTag($id_list,$tag)
	{
		$connessione=make_connession();
		$id_list=safe($id_list);
		$tag=safe($tag);
		$query_string="INSERT INTO tag (id_list,tag) ". 
		"VALUES ('".$id_list
			."','".$tag
			 ."')";
		return make_query($connessione,$query_string);
	}
	function insertReport($id_song,$kind,$description,$id_user)
	{
		$connessione=make_connession();
		$id_song=safe($id_song);
		$kind=safe($kind);
		$description=safe($description);
		$id_user=safe($id_user);
		$query_string="INSERT INTO report (id_list,kind,description,id_user) ". 
		"VALUES ('".$id_song
			."','".$kind
			 ."','".$description
			 ."','".$id_user
			 ."')";
		return make_query($connessione,$query_string);
	}
	function getMaxId(){
		$connessione=make_connession();
		$imei=safe($imei);
		$query=make_query($connessione,"SELECT MAX(id) AS max FROM list");
		$row=mysql_fetch_array($query);
		return $row['max'];			
	}
	function checkData($data){
		if($data=="")
			return true;
		$connessione=make_connession();
		$data=safe($data);
		$query=make_query($connessione,"SELECT * FROM list WHERE time>'".$data."'");
		$row=mysql_fetch_array($query);
		if(mysql_num_rows($query)>0){
			return true;
		}else
			return false;
		//return $row['max'];		
	}
	function getListOfSong(){
		$connessione=make_connession();
		$query=make_query($connessione,"SELECT id,title,author,body,time FROM list"); 		
		return generaLista($query);	
	}
	function getListOfSongTitle(){
		$connessione=make_connession();
		$query=make_query($connessione,"SELECT id,title FROM list ORDER BY title"); 		
		return generaLista($query);	
	}
	function getListOfSongAfter($time){
		if($time=="")
			return getListOfSong();
		$connessione=make_connession();
		$time=safe($time);
		$query=make_query($connessione,"SELECT id,title,author,body,time FROM list WHERE time>'".$time."'"); 		
		return generaLista($query);	
	}
	function getListOfTag(){
		$connessione=make_connession();
		$query=make_query($connessione,"SELECT id,id_list,tag FROM tag");		
		return generaListaTag($query);	
	}
	function getListOfTagAfter($time){
		if($time=="")
			return getListOfTag();
		$connessione=make_connession();
		$time=safe($time);
		$query=make_query($connessione,"SELECT t.id,t.id_list,t.tag FROM tag AS t JOIN list AS l ON l.id=t.id_list WHERE l.time>'".$time."'");		
		return generaListaTag($query);	
	}
	function getSong($id_song){
		$connessione=make_connession();
		$id_song=safe($id_song);
		$query=make_query($connessione,"SELECT id,title,author,body,time,id_user FROM list WHERE id='".$id_song."'");		
		return generaLista($query);	
	}
	function getSongTitle($id_song){
		$connessione=make_connession();
		$id_song=safe($id_song);
		$query=make_query($connessione,"SELECT title FROM list WHERE id='".$id_song."'");		
		$row=mysql_fetch_array($query);
		return $row['title'];	
	}
	function getListOfTagById($id_song){
		$connessione=make_connession();
		$id_song=safe($id_song);
		$query=make_query($connessione,"SELECT id,id_list,tag FROM tag WHERE id_list='".$id_song."'");		
		return generaListaTag($query);			
	}
	function generaLista($query){
		/*class Update{
			public $update="";
		}*/
		class listOfSong{
			public $id="";
			public $title="";
			public $author="";
			public $body="";
			public $time="";
			public $id_user="";
		}
		$u=array();
		while($row=mysql_fetch_array($query))
		{
			$b=new listOfSong();
			@$b->id=$row['id'];
			@$b->title=$row['title'];
			@$b->author=$row['author'];
			@$b->body=$row['body'];
			@$b->time=$row['time'];
			@$b->id_user=$row['id_user'];
			$u[]=$b;			
		}
		//$out=new Update();
		//$out->update=$u;
		return $u;	
	}
	function generaListaTag($query){
		/*class Update{
			public $update="";
		}*/
		class tag{
			public $id="";
			public $id_song="";
			public $tag="";
		}
		$u=array();
		while($row=mysql_fetch_array($query))
		{
			$b=new tag();
			$b->id=$row['id'];
			$b->id_song=$row['id_list'];
			$b->tag=$row['tag'];
			$u[]=$b;			
		}
		//$out=new Update();
		//$out->update=$u;
		return $u;	
	}
	
	/**
	 * Sezione dedicata alle query di statistiche
	 * */
	function getNumberOfSong(){
		$connessione=make_connession();
		$query=make_query($connessione,"SELECT COUNT(*) AS number FROM list");
		$row=mysql_fetch_array($query);
		return $row['number'];			
	}
	function getNumberOfUser(){
		$connessione=make_connession();
		$query=make_query($connessione,"SELECT COUNT(*) AS number FROM user");
		$row=mysql_fetch_array($query);
		return $row['number'];			
	}
	function getNumberOfTag(){
		$connessione=make_connession();
		$query=make_query($connessione,"SELECT COUNT(*) AS number FROM tag");
		$row=mysql_fetch_array($query);
		return $row['number'];			
	}
	function getTagList(){
		$connessione=make_connession();
		$query=make_query($connessione,"SELECT tag,count(*) as freq FROM tag GROUP BY tag ORDER BY count(*) DESC");
		return generaElencoTag($query);			
	}
	
	function generaElencoTag($query){
		class tag{
			public $tag;
			public $freq;
		}
		$u=array();
		while($row=mysql_fetch_array($query))
		{
			$b=new tag();
			$b->tag=$row['tag'];
			$b->freq=$row['freq'];
			$u[]=$b;			
		}
		//$out=new Update();
		//$out->update=$u;
		return $u;	
	}
?>
