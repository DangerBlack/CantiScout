<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<head>
<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
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


 
 <script type="text/javascript" > 
 $(document).ready(function(){
				init();
				$.post("php/login.php",function(data){
					if(data==200){						
					}else{
						location.replace("login.html");
					}
				});
				$("#id_song").keypress(function(e) {
					if(e.which == 13) {
						location.replace("report.php?id="+$("#id_song").val());
					}
				});
				$("#submit").click(function(){
					if($("#id_song").val()!=""){
					$.post("php/postReport.php",{"id_song":$("#id_song").val(),"kind":$("#kind").val(),"description":$("#description").val()},function(data){
							if(data=="201"){
								location.replace("index.html");
							}else{
								$(".error").html("Attenzione! Non avete i permessi per creare contenuti");
							}
						});
					}else{
						$(".error").html("Attenzione! Non avete selezionato nessuna canzone");
					}
				});
			});
</script>
<style>
		
</style>

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
          <a class="navbar-brand" href="index.html">CantiScout</a>
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
					<li class="active"><a href="index.html">Home</a></li>
					<li><a href="edit.html">Inserici Canzone</a></li>
					<li><a href="canzoniere.html">Canzoniere</a></li>
					<li><a href="stats.html">Statistiche</a></li>
					<li><a href="credits.html">Chi Siamo</a></li>
					<li><a href="https://play.google.com/store/apps/details?id=danielebaschieri.eu.cantiscout">
					  <img alt="Get it on Google Play" title="CantiScout download from Google Play"
						   src="css/img/it_generic_rgb_wo_45.png" width="100%" />
					</a></li>
				</ul>
			</div>
			<div id="main" class="col-sm-9 col-sm-offset-3 col-md-10 col-md-offset-2 main">
				<div class="row">
					<div class="col-md-8">
						<h1>Riporta un problema</h1>
						<p class="error"></p>
						<?php
							include('php/query.php');
							$id_song=$_GET['id'];
							echo "<p>Mandare un rapporto sulla canzone [<input id=\"id_song\" value=\"".$id_song."\" />]: <i>".getSongTitle($id_song)."</i></p>";
						?>
						<select id="kind">
							<option value="0">Infrazione copyright</option>
							<option value="1">contenuti espliciti</option>
							<option value="2">errore nelle note</option>
							<option value="3">errore nel testo</option>
							<option value="4">altro</option>
						</select>
						<textarea id="description" placeholder="descrizione"></textarea>
						<button id="submit" class="btn btn-lg btn-primary pull-right">Submit</button>
					</div>
					<div class="col-md-4">
						<form id="paypalForm" action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
							<input type="hidden" name="cmd" value="_s-xclick">
							<input type="hidden" name="hosted_button_id" value="2PG76GLSEMBAC">
							<input id="paypalButton" type="image" src="https://www.paypalobjects.com/it_IT/IT/i/btn/btn_donate_LG.gif" border="0" name="submit" alt="PayPal - Il metodo rapido, affidabile e innovativo per pagare e farsi pagare.">
							<img alt="" border="0" src="https://www.paypalobjects.com/it_IT/i/scr/pixel.gif">
						</form>
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
