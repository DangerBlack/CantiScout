<?php
    require  'medoo.min.php';
	function connect(){
		$database = new medoo([
				// required
				'database_type' => 'mysql',
				'database_name' => 'bit_cantiscout',//DB_NAME
				'server' => 'localhost',
				'username' => 'bit_cantiscout',//DB_USERNAME
				'password' => 'bit_cantiscout',//PASSWORD
				 
				// optional
				'port' => 3306,
				'charset' => 'utf8',
				// driver_option for connection, read more from http://www.php.net/manual/en/pdo.setattribute.php
				'option' => [
				PDO::ATTR_CASE => PDO::CASE_NATURAL
			]
		]);
		return $database;
	}
    //GESTIONE UTENTI LOGIN REGISTER ETC
    function login($mail,$pswd){
		$database=connect();
		$result=$database->has("user",[
			"AND" => [
				"mail" => $mail,
				"pswd" => $pswd
			]
		]);
		return $result;
	}
    function isLogged(){		
		$mail=$_COOKIE["mail"];
		$pswd=$_COOKIE["pswd"];
		if(login($mail,$pswd)){
			return true;
		}else{
			return false;
		}		
	}
	function getId(){
		$mail=$_COOKIE["mail"];
		return getIdFromMail($mail)[0]['id'];
	}
    function getIdFromMail($mail){
		$database=connect();
		$datas=$database->select("user",[
			"id"
		],[
			"mail[=]"=>$mail
		]);
		return $datas;
	}
	function getUser($id){
		$database=connect();
		$res=$database->select("user",[
			"mail",
			"name",
            "picture"
		],[
			"id[=]"=>$id
		]);
		return $res;
	}
	function insertUser($name,$mail,$pswd){
		$database=connect();
		$res=$database->insert("user",[
			"name"=>$name,
			"mail"=>$mail,
			"pswd"=>$pswd
		]);
		return $res;
	}
    
    //GESTIONE CANZONI
	function insertSong($title,$author,$body,$id_user)
	{
        $database=connect();
		$idSong=$database->insert("list",[
			"title"=>$title,
			"author"=>$author,
			"body"=>$body,
            "id_user"=>$id_user
		]);
        return $idSong;
	}
	function updateSong($id,$title,$author,$body,$id_user)
	{
		$database=connect();
		$idSong=$database->update("list",[
			"title"=>$title,
			"author"=>$author,
			"body"=>$body,
            "id_user"=>$id_user
		],
        [
            "id[=]"=>$id
        ]);
        return $idSong;
	}
    //la togliamo questa
	function insertLog($id_user,$id_song){
        $database=connect();
        $ip=$_SERVER['REMOTE_ADDR'];
		$ip_prox=$_SERVER['HTTP_X_FORWARDED_FOR'];
		$res=$database->insert("log",[
			"id_user"=>$id_user,
			"id_list"=>$id_list,
			"ip"=>$ip,
            "ip_prox"=>$ip_prox
		]);
        return $res;
	}
    //questa va fatta inclusa
	function logHistory($id_song){
		$song=getSong($id_song)[0];//che cazzo fa ucfirst? 
		$title=ucfirst($song->title);
		$author=$song->author;
		$body=$song->body;
		$id_user=$song->id_user;
		$time=$song->time;        
        $database=connect(); //dovremmo già essere connessi al db
		$idSong=$database->insert("history",[
            "id_list"=>$id_song,
			"title"=>$title,
			"author"=>$author,
			"body"=>$body,
            "id_user"=>$id_user,
            "time"=>$time
		]);
        return $idSong;
	}
	function insertTag($id_list,$tag)
	{
        $database=connect();
		$res=$database->insert("tag",[
			"id_list"=>$id_list,
			"tag"=>$tag
		]);
        return $res;
	}
	function insertReport($id_song,$kind,$description,$id_user)
	{
        $database=connect();
		$res=$database->insert("report",[
			"id_list"=>$id_list,
			"kind"=>$kind,
            "description"=>$description,
            "id_user"=>$id_user
		]);
        return $res;
	}
    
    //FUNZIONI CHE RESTITUISCONO DATI
	function getMaxId(){
        $database=connect();
		$max=$database->max("list",[
			"id(max)"
		]);
        return $max;		
	}
	function checkData($data){
		if($data=="")
			return true;
        $database=connect();
		$count=$database->count("list",[
            "[>]time"=>$data
        ]);
		if($count>0){
			return true;
		}else
			return false;
		//return $row['max'];		
	}
	function getListOfSong(){//Aggiungere l'utente che ha condiviso la canzone #SOCIAL
        $database=connect();
		$res=$database->select("list",[
            "id",
            "title",
            "author",
            "body",
            "time"
        ]);
        return $res;
	}
	function getListOfSongTitle(){
        $database=connect();
		$res=$database->select("list",[
            "id",
            "title"
        ],[
            "ORDER" => "title ASC"
        ]);
        return $res;
	}
	function getListOfSongAfter($time){
		if($time=="")
			return getListOfSong();
        $database=connect();
		$res=$database->select("list",[
            "id",
            "title",
            "author",
            "body",
            "time"
        ],[
            "[>]time"=>$time
        ]);
        return $res;	
	}
	function getListOfTag(){
        $database=connect();
		$res=$database->select("tag",[
            "id",
            "id_list(id_song)",
            "tag",
        ]);
        return $res;		
	}
	function getListOfTagAfter($time){
		if($time=="")
			return getListOfTag();
        $database=connect();
		$res=$database->select("tag",
        [
            "[>]list"=>["id_list"=>"id"]
        ],[
            "tag.id",
            "tag.id_list(id_song)",
            "tag.tag",
        ],
        [
            "[>]list.time"=>$time
        ]);
        return $res;	
	}
	function getSong($id_song){
        $database=connect();
		$res=$database->select("list",[
            "id",
            "title",
            "author",
            "body",
            "time"
        ],[
            "[=]id"=>$id_song
        ]);
        return $res;
	}
	function getSongTitle($id_song){
        $database=connect();
		$res=$database->select("list",[
            "title"
        ],[
            "[=]id"=>$id_song
        ]);
		return $res[0]['title'];	
	}
	function getListOfTagById($id_song){
        $database=connect();
		$res=$database->select("tag",[
            "id",
            "id_list(id_song)",
            "tag",
        ],[
            "[=]id_list"=>$id_song
        ]);
        return $res;		
	}	
	/**
	 * Sezione dedicata alle query di statistiche
	 * */
	function getNumberOfSong(){
        $database=connect();
		$number=$database->count("list");
        return $number;			
	}
	function getNumberOfUser(){
        $database=connect();
		$number=$database->count("user");
        return $number;				
	}
	function getNumberOfTag(){
        $database=connect();
		$number=$database->count("tag");
        return $number;			
	}
	function getTagList(){
        $database=connect();
		$res=$database->select("tag",[
            "tag"
            ],[
            "GROUP"=>'tag'
            ]);
        foreach($res as &$tag){
			$tag['freq']=$database->count("tag",["tag"=>$tag['tag']]);
		}
		usort($res, function($a, $b) { //Sort the array using a user defined function
			return $a['freq'] > $b['freq'] ? -1 : 1; //Compare the scores
		});  
        return $res;	
		//$connessione=make_connession();
		//$query=make_query($connessione,"SELECT tag,count(*) as freq FROM tag GROUP BY tag ORDER BY count(*) DESC");
		//return generaElencoTag($query);			
	}
?>
