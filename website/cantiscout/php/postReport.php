<?
	include('query.php');
	$arrayKindOfReport = array("copiright", "espliciti-odio-sesso-discriminazione", "note errate", "testo errato", "altro");
	$id_song=$_POST['id_song'];
	$description=$_POST['description'];
	$kind=$_POST['kind'];
	if(isLogged()){
		$id_user=getIdFromMail($_COOKIE["mail"]);	
		insertReport($id_song,$kind,$description,$id_user);
		$today = date("H:i:s d/m/Y");
		$to      = "daniele.baschieri@gmail.com";
		$subject = 'Report on Song';
		$message = '<html>'.
					'<body>'.
					'Un utente ha segnalato la canzone '.getSongTitle($id_song).'<br />'.
					'Il tipo di segnalazione è: '.$arrayKindOfReport[$kind].'<br />'.
					'L\'utente ha descritto in questo modo il problema:<br />'.
					$description."<br />".
					'Potete rispondere all\'utente all\'indirizzo: '.getMailFromId($id_user).'<br />'.					
					'<br />'.
					'Lo Staff<br />'.
					'</body>'.
					'</html>';
		
		$headers  = 'MIME-Version: 1.0' . "\r\n";
		$headers .= 'Content-type: text/html; charset=iso-8859-1' . "\r\n";
		$headers .= 'From: CantiScout <cantiscout@512b.it>'. "\r\n";
		mail($to, $subject, $message, $headers);
		
		echo "201";
	}else{
		echo "401"; 
	}
?>
