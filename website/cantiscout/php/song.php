<html>
	<head>
		<title>Song</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8"> 
		<meta name="author" content="Daniele Baschieri" />
		<meta name="description" content="Un semplice canzoniere da viaggio per android. Pratico per le route o per tutti gli Scout smemorati." />
		<meta name ="copyright" content="" />
		<meta name="keywords" content="" />
		<title>CantiScout</title>
		<link rel="stylesheet" type="text/css" href="../css/default.css" />
		<link rel="stylesheet" type="text/css" href="../css/bootstrap.min.css" />
		<link rel="stylesheet" type="text/css" href="../css/dashboard.css" />
		<link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.3/themes/smoothness/jquery-ui.css" />


		<link rel="icon" 
			  type="image/png" 
			  href="../css/img/ic_launcher.png.png" />
			  
		 <link rel="icon" href="../css/img/favicon.ico" type="image/gif" sizes="16x16" /> 
			  
		 <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
		<!-- <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.3/jquery-ui.min.js"></script> -->
		<script type="text/javascript" src="../js/bootstrap.min.js"></script>
		<script type="text/javascript"  src="../js/default.js"></script>
		<script type="text/javascript" src="../js/chordpro.js"></script>
		<script type="text/javascript" src="../js/mediaTools.js"></script>
		 <script>
			 $(document).ready(function(){
				 init();
				 loadUserSpace("");
				 var song=$("#songRaw").text();
				 js=JSON.parse(song);
				 $("#songRaw").html('');
				 //var chordpro=require("../js/chordpro.js");
				 var output = ChordPro.to_txt(js[0].body);
				  $("#song").html("");
				  $("#song").html('<h1>'+js[0].title+' <a href="../update.php?id='+js[0].id+'"><button class="btn btn-sm btn-primary"><span class="glyphicon glyphicon-pencil" aria-hidden="true"></span></button></a> <a href="../report.php?id='+js[0].id+'"><button class="btn btn-sm btn-danger"><span class="glyphicon glyphicon-warning-sign" aria-hidden="true"></span></button></a></h1>');
				  $("#song").append('<h2>'+js[0].author+'</h2>');
				  $("#song").append('<p class="canzone_mono">'+output.replace(/\n/g,"<br />")+'</p><br /><p class="small">Conversione della canzone da chordpro di Jonathan Perkin</p>');
				  caricaListaTag(js[0].id,".hashtags","");
				  mediaActivate(js[0].id,"#multimedia","");
			});
		 </script>
		 <?php
			include('query.php');
			$id=$_GET['id'];
		 ?>
	</head>
<body>
	<nav class="navbar navbar-inverse navbar-fixed-top">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="../index.html">CantiScout</a>
        </div>
        <div id="navbar" class="collapse navbar-collapse">
          <ul class="nav navbar-nav">
          </ul>
          <ul class="nav navbar-nav navbar-right" id="userSpace">
			  <li><a href="../login.html">Login</a></li>			
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
					<li><a href="../index.html">Home</a></li>
					<li><a href="../edit.html">Inserici Canzone</a></li>
					<li class="active"><a href="../canzoniere.html">Canzoniere</a></li>
					<li><a href="../stats.html">Statistiche</a></li>
					<li><a href="../credits.html">Chi Siamo</a></li>
					<li><a href="https://play.google.com/store/apps/details?id=danielebaschieri.eu.cantiscout">
					  <img alt="Get it on Google Play" title="CantiScout download from Google Play"
						   src="../css/img/it_generic_rgb_wo_45.png" width="100%" />
					</a></li>
				</ul>
			</div>
			<div id="main" class="col-sm-9 col-sm-offset-3 col-md-10 col-md-offset-2 main">
				<div class="container">
					<div class="row">
						<div class="col-sm-7">
							<?php
								
								//echo str_replace("\\n","<br />",json_encode(getSong($id)));
								echo "<div id=\"songRaw\">".json_encode(getSong($id))."</div>";
							?>
							<div id="song"></div>
						</div>
						<div class="col-sm-5">
							<div id="multimedia">							
								<img id="big-img" class="img-big-prev" src="http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg" alt="scout song"/>
								<ul class="img-list">
									<li><img class="img-small-prev" src="http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg" alt="scout song"/></li>
									<li><img class="img-small-prev" src="http://www.udine8.it/wp-content/uploads/2014/04/logo-agesci-22-6-05.gif" alt="scout song"/></li>
									<li><img class="img-small-prev" src="http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg" alt="scout song"/></li>
								</ul>
							</div>
							<br />
							<h3>Hashtag</h3>
							<ul class="hashtags">
							</ul>
						</div>
					</div>
				</div>
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
