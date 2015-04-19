<?
	include('query.php');
	
	$id_song=$_POST['id_song'];
	$title=$_POST['title'];
	$author=$_POST['author'];
	$body=$_POST['body'];
	if(isLogged()){	
		$id_user=getIdFromMail($_COOKIE["mail"]);
		$b=checkSong($body);
		if($b){
			logHistory($id_song);
			updateSong($id_song,$title,$author,$body,$id_user);
			insertLog($id_user,$id_song);
			echo "201";
		}else{
			echo "400";
		}
	}else{
		echo "401"; 
	}
	function checkSong($body){
		$l=explode("\n",$body);
		$b=true;
		for ($i = 0; $i < count($l); $i++) {
			if(!isBalancedNotNested($l[$i],'[',']')){
				$b=false;
			}else{
				//echo "E' bilanciata []: ".$l[$i]."<br />";
			}
			if(!isBalancedNotNested($l[$i],'{','}')){
				$b=false;
			}else{
				//echo "E' bilanciata {}: ".$l[$i]."<br />";
			}
			if(preg_match('/.*\[([^\]]*)\].*/',$l[$i])<=0){
				if(preg_match('/.*\{.*\}.*/',$l[$i])<=0){
					if(preg_match('/#.*/',$l[$i])<=0){
						if(preg_match('/ */',$l[$i])<=0){
							$b=false;
						}else{
							//echo "E' spazio ".$l[$i]."<br />";
						}
					}else{
						//echo "E' commento al codice: ".$l[$i]."<br />";
					}
				}else{
					//echo "E' note e commento: ".$l[$i]."<br />";
				}
			}else{
				//echo "E' note e testo: ".$l[$i]." ".preg_match('/.*\[([^\]]*)\].*/',$l[$i])."<br />";
			}
				
		}
		return $b;
	}
	function isBalancedNotNested($row,$kindOpen,$kindClose){
		$count=0;
		for ($i = 0; $i < strlen($row); $i++) {
			if ( substr($row, $i, 1) == $kindOpen ) {
				$count++;
			}
			if ( substr($row, $i, 1) == $kindClose ) {
				$count--;
			}
			//echo $count;
			if($count>1)
				return false;
			if($count<0)
				return false;
		}
		//echo "<br />";
		if($count==0)
			return true;
	}
?>
