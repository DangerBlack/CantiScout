function mediaActivate(id,where,path){
	loadMediaIdSong(id,where);
}

function loadMediaIdSong(id,where,path){
	var data='['+
			'{"id":"1","kind":"video","url":"https://www.youtube.com/watch?v=iyy6TeBjtBM","desc":""},'+
			'{"id":"2","kind":"img","url":"http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg","desc":""},'+
			'{"id":"3","kind":"img","url":"http://www.udine8.it/wp-content/uploads/2014/04/logo-agesci-22-6-05.gif","desc":""},'+
			'{"id":"4","kind":"mp3","url":"http://www.cantiscout.it/audio/Guarda%20piu%20in%20la%20-%20Como.mp3","desc":"Guarda più in la Como"},'+
			'{"id":"5","kind":"img","url":"https://fbcdn-sphotos-h-a.akamaihd.net/hphotos-ak-xpa1/v/t34.0-12/11180240_10206865464137837_495197286_n.jpg?oh=52e1c346e0bd599e4c06a13d5c9401c5&oe=553B2BC1&__gda__=1429931024_d3b0721579451ff9ca8a3f279d064d0f","desc":""},'+
			'{"id":"2","kind":"img","url":"http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg","desc":""},'+
			'{"id":"2","kind":"img","url":"http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg","desc":""},'+
			'{"id":"2","kind":"img","url":"http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg","desc":""},'+
			'{"id":"6","kind":"mp3","url":"http://www.cantiscout.it/audio/Madonna%20degli%20scout.mp3","desc":"Madonna degli scout bambini"}'+
		']';
	data='[]';
	swhere=where.substring(1,where.length);
	$(where).html('<img id="big-img" class="img-big-prev" src="../css/img/note.png" alt="scout song"/>'+
				  '<ul id="'+swhere+'img" class="img-list"></ul><ul id="'+swhere+'mp3" class="img-list"></ul>');
	var js=JSON.parse(data);
	for(var i=0;i<js.length;i++){
		if(js[i].kind=="img")
			$(where+"img").append('<li>'+getRightMediaPreview(js[i])+'</li>');
		if(js[i].kind=="mp3"){
			$(where+"mp3").append('<li><p>'+js[i].desc+'<p/><audio controls><source src="'+js[i].url+'" type="audio/ogg" ></audio></li>');
		}
	}
	
	
	$(".img-small-prev").click(function(){
		var src=$(this).attr("src");
		$("#big-img").attr("src",src);
	});
}

function getRightMediaPreview(media){
	if(media.kind=="img"){
		return '<img class="img-small-prev" src="'+media.url+'" alt="'+media.desc+'"/>'
	}
	return "";
}
/*
<img id="big-img" class="img-big-prev" src="http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg" alt="scout song"/>
<ul class="img-list">
	<li><img class="img-small-prev" src="http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg" alt="scout song"/></li>
	<li><img class="img-small-prev" src="http://www.udine8.it/wp-content/uploads/2014/04/logo-agesci-22-6-05.gif" alt="scout song"/></li>
	<li><img class="img-small-prev" src="http://yaleherald.com/wp-content/uploads/2013/02/boyscout.jpg" alt="scout song"/></li>
</ul>
*/
