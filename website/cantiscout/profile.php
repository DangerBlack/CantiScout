<html>
	<head>
		<title>Profilo</title>
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
		<script type="text/javascript" src="js/profile-user.js"></script>
		<script type="text/javascript" src="js/chordpro.js"></script>
		 <script>
			 $(document).ready(function(){
				 init();
				 <?php
					include('php/query.php');
					@$id_user=$_GET['id'];
					echo "var dati='".json_encode(getUser($id_user))."';\n";
					echo "var id=\"".$id_user."\";\n";
				?>
				if((typeof id != 'undefined') && (id!="")){
					inizializzaUtente(dati);
				}
				$.get("php/getUserInfo.php",function(data){
					var js=JSON.parse(data);
					if((typeof id == 'undefined') || (id=="")){
						id=js[0].id;
						inizializzaUtente(data);
					}
					else{
						if(id!=js[0].id){
							hideAllEdit();
						}
					}
				});
				function inizializzaUtente(dati){
					var js=JSON.parse(dati);
					$("#username").html(js[0].name);
					$("#userAvatar").html('<img src="'+js[0].picture+'" />');
					initProfile();
				}
				
				
			});
		 </script>
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
				<div id="userDetails" class="row">
				  <div class="col-md-4">
					 <h1 id="username"></h1>
					 <div>
						<button class="username-edit btn btn-xs btn-info" type="button">Modifica</button>
						<button class="username-send btn btn-xs btn-info" type="button">Invia</button>
					 </div> 
					 <div class="thumbnail" id="userAvatar">
					 </div>
					 <button class="avatar-edit btn btn-xs btn-info" type="button">Modifica</button>
					 <button class="avatar-send btn btn-xs btn-info" type="button">Invia</button>
				  </div>
				  <div class="col-md-4">
					  <h2>Descrizione</h2>
					  <article id="userDescription"></article>
					  <div>
						<button class="description-edit btn btn-xs btn-info" type="button">Modifica</button>
						<button class="description-send btn btn-xs btn-info" type="button">Invia</button>
					  </div>
				  </div>
				  <div class="col-md-4 pswd">
					  <h2>Password</h2>
					  <input class="profile" type="password" id="oldPswd" placeholder="old password" />
					  <input class="profile" type="password" id="newPswd" placeholder="new password" />
					  <input class="profile" type="password" id="newPswd2" placeholder="confirm" />
					  <div>
						<button class="pswd-send btn btn-xs btn-info" type="button">Invia</button>
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
