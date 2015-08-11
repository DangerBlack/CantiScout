<html>
	<head>
		<title>Song</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8"> 
		<meta name="author" content="Daniele Baschieri" />
		<meta name="description" content="Un semplice canzoniere da viaggio per android. Pratico per le route o per tutti gli Scout smemorati." />
		<meta name ="copyright" content="" />
		<meta name="keywords" content="" />
		<title>CantiScout</title>
		<link rel="stylesheet" type="text/css" href="css/default.css" />
		<link rel="stylesheet" type="text/css" href="css/bootstrap.min.css" />
		<link rel="stylesheet" type="text/css" href="css/dashboard.css" />
		<link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.3/themes/smoothness/jquery-ui.css" />


		<link rel="icon" 
			  type="image/png" 
			  href="css/img/ic_launcher.png.png" />
			  
		 <link rel="icon" href="css/img/favicon.ico" type="image/gif" sizes="16x16" /> 
			  
		 <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
		<!-- <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.3/jquery-ui.min.js"></script> -->
		<script type="text/javascript" src="js/bootstrap.min.js"></script>


		<script type="text/javascript"  src="js/default.js"></script>
		<script type="text/javascript" src="js/chordpro.js"></script>
		 <script>
			 $(document).ready(function(){
				 init();
				 $("#id_song").keypress(function(e) {
					if(e.which == 13) {
						location.replace("update.php?id="+$("#id_song").val());
					}
				});
				 $("#songRaw").hide();
				 $("#showText").hide();
				 var song=$("#songRaw").text();
				 try{
					 js=JSON.parse(song);
					 $("#songRaw").html('');
					  //$("#song").html("");
					  $("#title").val(js[0].title);
					  $("#author").val(js[0].author);
					  //$("#song").append('<textarea>'+output+'</textarea><br /><p class="small">Conversione della canzone da chordpro di Jonathan Perkin</p>');
					  $("#body").val(js[0].body);
					  caricaListaTag($("#id_song").val(),"#tagList");
					  
				  }catch(e){
					  $(".error").html("E' necessario selezionare una canzone");
				  }
				  //Funzione sperimentale
				  function smartCheck5(){
						setTimeout(function(){
							$("#conversion").val("");
							var output = ChordPro.to_txt($("#body").val());
							$("#conversion").val(output);
							smartCheck5();
						},5000);
				  }
				  smartCheck5();
				  $("#submit").click(function(){
						var go=true;
						if(!$("#tos").is(':checked')){
							$(".error").html("Attenzione! Se non accettate il Contratto di Licenza non potete aggiungere canzoni");
							go=false;
							return true;
						}
						if($("#title").val()==""){
						$(".error").html("Attenzione! Non avete inserito nessun titolo per questa canzone");
							go=false;
							return true;
						}
						if($("#body").val()==""){
							$(".error").html("Attenzione! Non avete inserito il testo della canzone");
							go=false;
							return true;
						}
						var id_song=$("#songRaw").attr("value");
						//alert(id_song);
						if(go)
							$.post("php/updateSong.php",{"id_song":id_song,"title":$("#title").val(),"author":$("#author").val(),"body":$("#body").val()},function(data){
									if(data=="201"){
										$("#title").val("");
										$("#author").val("");
										$("#body").val("");
										alert("ha fungiato");
									}else{
										if(data=="400"){
											$(".error").html("Attenzione! c'è un errore nel testo della canzone!");
										}else{
											$(".error").html("Attenzione! Non avete i permessi per creare contenuti");
										}
									}
								});
				  });
			});
		 </script>
	</head>
<body>
	<?php
		include('php/query.php');
		$id_song=$_GET['id'];
		//echo "<p>Mandare un aggiornamento sulla canzone [<input id=\"id_song\" value=\"".$id_song."\" />]: <i>".getSongTitle($id_song)."</i></p>";
		//echo str_replace("\\n","<br />",json_encode(getSong($id)));
		echo "<div id=\"songRaw\" value=\"".$id_song."\">".json_encode(getSong($id_song))."</div>";
	?>
	<nav class="navbar navbar-inverse navbar-fixed-top">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="#">CantiScout</a>
        </div>
        <div id="navbar" class="collapse navbar-collapse">
          <ul class="nav navbar-nav">
          </ul>
          <ul class="nav navbar-nav navbar-right" id="userSpace">
			  <li><a href="login.html">Login</a></li>			
          </ul>
          <form class="navbar-form navbar-center form-group">
			<div class="input-group">
				<input type="text" class="form-control" placeholder="Search...">
				<span class="input-group-addon"><span class="glyphicon glyphicon-search"></span></span>
			</div>
          </form>
        </div><!--/.nav-collapse -->
      </div>
    </nav>
    <div class="container-fluid">
		<div class="row">
			<div class="col-sm-3 col-md-2 sidebar">
			   <ul id="menu" class="nav nav-sidebar">
					<li><a href="index.html">Home</a></li>
					<li><a href="edit.html">Inserici Canzone</a></li>
					<li class="active"><a href="canzoniere.html">Canzoniere</a></li>
					<li><a href="stats.html">Statistiche</a></li>
					<li><a href="credits.html">Chi Siamo</a></li>
					<li><a href="https://play.google.com/store/apps/details?id=danielebaschieri.eu.cantiscout">
					  <img alt="Get it on Google Play" title="CantiScout download from Google Play"
						   src="css/img/it_generic_rgb_wo_45.png" width="100%" />
					</a></li>
				</ul>
			</div>
			<div id="main" class="col-sm-9 col-sm-offset-3 col-md-10 col-md-offset-2 main">
				<div class="form-group">
					<label for="InputSongId">Id</label>
					<div class="input-group">
						<?php
							echo '<input id="id_song" value="'.$id_song.'" name="id" type="text" class="form-control" placeholder="null" readonly/>';
						?>
						<span class="input-group-addon"><span class="glyphicon glyphicon-asterisk"></span></span>
					</div>
				</div>
				<p class="error"></p>
				<div class="form-group">
						<label for="InputTitle">Titolo</label>
						<div class="input-group">
							<input type="text" id="title" name="title" placeholder="titolo" class="form-control"/>
							<span class="input-group-addon"><span class="glyphicon glyphicon-asterisk"></span></span>
						</div>
				</div>
				<div class="form-group">
						<label for="InputAuthor">Autore</label>
						<div class="input-group">
							<input type="text" id="author" name="author" placeholder="autore" class="form-control"/>
							<span class="input-group-addon"><span class=" glyphicon glyphicon-minus"></span></span>
						</div>
				</div>
				
				<p>Inserire testo in formato <a href="http://web.skeed.it/index.php?q=chordpro-it.html">ChordPro</a></p>
				<div class="row">
					<div class="col-sm-6">
						<h5>Canzone sorgente</h5>
						<textarea class="canzone_mono" id="body" placeholder="testo e note chordpro {title:Il titolo della canzone} {author:L'autore della canzone} {soc}ritornello{eoc}"></textarea>
					</div>
					<div class="col-sm-6">
						<h5>Canzone convertita</h5>
						<textarea class="canzone_mono" id="conversion" placeholder="" readonly></textarea>
					</div>
				</div>
				<div class="row">
					<div class="col-sm-12">
						<ul id="tagList">
						</ul>
					</div>
				</div>
				<span class="warning" id="tagWarning"></span>
				<div class="form-group">
						<label for="InputHashTag">Hashtag</label>
						<div class="input-group">
							<input type="text" id="tag" name="hashtag" placeholder="#hashtag #chiesa #amore #bans #fuoco #rs #coccinelle  " class="form-control"/>
							<span class="input-group-addon"><span class="glyphicon glyphicon-minus"></span></span>
						</div>
				</div>
				
				<div>
					<div class="scelta">
						<input type="checkbox" name="chiesa" value="chiesa" id="chiesa"/><span>chiesa</span>
					</div>
					<div class="scelta">
						<input type="checkbox" name="lc" value="lc" id="lc" /><span>L/C</span> 
					</div>
					<div class="scelta">
						<input type="checkbox" name="eg" value="eg" id="eg" /><span>E/G</span>
					</div>
					<div class="scelta">
						<input type="checkbox" name="rs" value="rs" id="rs" /><span>R/S</span>
					</div>
					<div class="scelta">
						<input type="checkbox" name="altro" value="altro" id="altro" /><span>altro</span>
					</div>
				</div>
				<div id="tosbox"><input type="checkbox" name="tos" value="tos" id="tos" /><span>Accetto i <a href="tos.html">Termini di servizio</a> e le <a href="tos.html">norme</a> sulla privacy di CantiScout</span></div>
				<button id="submit" class="btn btn-lg btn-primary pull-right">Submit</button>
			</div>
		</div>
	</div>

</body>
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-54152381-1', 'auto');
  ga('require', 'displayfeatures');
  ga('send', 'pageview');

</script>
</html>
