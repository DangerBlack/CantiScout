function init(){
	loadUserSpace();
}

function caricaListaTag(id,where, path){
	path = typeof path === 'undefined' ? 'php/' : path;
	$.get(path+'getTagList.php?id='+id,function(data){
			var js=JSON.parse(data);
			for(var i=0;i<js.length;i++){
				$(where).append('<li>#'+js[i].tag+'</li>');
			}  
	});
}
function loadUserSpace(path){
	path = typeof path === 'undefined' ? 'php/' : path;
	$.get(path+"getUserInfo.php",function(data){
		if(data=="404"){
			$("#userSpace").html('<li><a href="login.html">Login</a></li>');
		}
		else{
			try{
				js=JSON.parse(data);
				var info=js[0];
				$("#userSpace").html('<li class="dropdown">'+
											'<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">'+info.name+' <img src="'+info.avatar+'" class="small-circle" /> <span class="caret"></span></a>'+
											 '<ul class="dropdown-menu" role="menu">'+
												'<li><a href="profile.php">Profilo</a></li>'+
												'<li class="divider"></li>'+
												'<li><a href="#" id="logout">Logout</a></li>'+
											  '</ul>'+
									'</li>');
				$("#logout").click(function(){
					$.post(path+"logout.php",function(){
						location.replace("login.html");
					});
				});
			}catch(e){
				$("#userSpace").html('<li><a href="login.html">Login</a></li>');
			}
		}
	});          
}
