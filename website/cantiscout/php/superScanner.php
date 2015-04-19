<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8"> 
	</head>
	<body>
<?php
	 
	 include('query.php');
	 $path="res/egrs/";
	 $filename="Come Maria.crd";
	 $arrayTagLc = array("lc", "branco", "cerchio", "lupetti", "coccinelle");
	 $arrayTagEg = array("eg", "reparto", "esploratori", "guide");
	 $arrayTagRs = array("rs", "clan", "rover", "scolte");
	 $arrayTagEgRs = array("eg", "reparto", "esploratori", "guide","rs", "clan", "rover", "scolte");
	 $arrayTagMessa = array("messa", "liturgia", "preghiera");
	 $utf8=false;
	
	 /*
	 scanDirAddSongAndTag("res/messa_noutf8/",false,$arrayTagMessa);
	 scanDirAddSongAndTag("res/messa/",true,$arrayTagMessa);
	 scanDirAddSongAndTag("res/lc_noutf8/",false,$arrayTagLc);
	 scanDirAddSongAndTag("res/lc/",true,$arrayTagLc);
	 scanDirAddSongAndTag("res/egrs/",true,$arrayTagEgRs);
	 */
	function scanDirAddSongAndTag($path,$utf8,$arrayList){
		 $listOfFile=scandir($path); 	 
		 echo "<h2>Cartella:".$path."</h2>";
		 echo "<p>Codifica utf8: ".$utf8."</p>";
		 for($i=2;$i<count($listOfFile);$i++){
			 $filename=$listOfFile[$i];
			 echo "filename: ".$filename."<br />";
			 $body=file_get_contents($path.$filename);
			 $init=strpos($body,"{title:")+7;
			 echo strpos($body,"{title:");
			 if(strpos($body,"{title:")===false){
				$init=strpos($body,"{t:")+3;
			}
			 //echo "init: ".$init."<br />";
			 $fine=strpos($body,"}",$init)-$init;
			 //echo "fine: ".$fine."<br />";
			 $title=substr($body,$init,$fine);
			 if($utf8===false)
			 echo ">>title encode: ".utf8_encode($title)."<br />";
			 if($utf8===true)
			 echo ">>title decode: ".$title."<br />";
			 $author="";
			 $id_user=1;
			 if($utf8===false)
				insertSong(utf8_encode($title),$author,utf8_encode($body),$id_user);
			  else
				insertSong($title,$author,$body,$id_user);
			 $id_song=getMaxId();
			 inserisciTagArray($id_song,$arrayList);
			 //inserisciTagArray($id_song,$arrayTagRs);
		}
	} 
	function inserisciTagArray($id,$arrayList){
		for($i=0;$i<count($arrayList);$i++){
			echo ">>>>tag:".$arrayList[$i]."<br />";
			insertTag($id,$arrayList[$i]);
		}
	}
?>
</body>
</html>
