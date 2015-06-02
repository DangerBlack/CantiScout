$.get("php/get.php",function(data){
	var js=JSON.parse(data).songlist;
	var canzoni="";
	for(var i=0;i<js.length;i++){
		canzoni=canzoni+js[i].body;
	}
	canzoni=canzoni.replace(/\[.*\]/gi,"").replace(/\{.*\}/gi,"").replace(/\n/g,' ');
	parole=canzoni.split(' ');
	//TODO rimuovere stampe


	var safeword=[' ','I','L','il','gli','la','le','lo','li','di','a','da','in','con','su','per','tra','fra','che','fa','sto','e','è','se','si','sa','ti','te','lo','i','chi','o','nel','nella','della','negli','al','od','del','dell','dall','non','più','ci','c\'è','ed','mi','ne','un','ce','ma','La','Le','E','ha','Ã¨','una','piÃ','piÃ¹'];
	ridpar=[];
	function cerca(a,word){
		for(var i=0;i<a.length;i++){
			if(a[i][0]==word)
				return i;
		}
		return -1;
	}
	for(var i=0;i<parole.length;i++){
		if((safeword.indexOf(parole[i])==-1)&&(parole[i]!='')&&(parole[i]!='\r')){
			var t=cerca(ridpar,parole[i]);
			if(t!=-1){
				i
				ridpar[t][1]=ridpar[t][1]+1;
				//$("#word-all").append('old:'+ridpar[t][1]+'#');
			}
			else{
				ridpar.push([parole[i],1]);
				//$("#word-all").append('nuova!');
			}
			//$("#word-all").append('<span>accept:'+parole[i]+'#</span><br />');
		}else{
			//$("#word-all").append('<span>reject:'+parole[i]+'#</span><br />');
		}
	}
	//$("#word-all").append('<p>Parole: '+parole.length+'</p>');
	parole=ridpar;
	//$("#word-all").append('<p>Ridotte: '+parole.length+'</p>');
	parole.sort(function(a,b){
		return b[1]-a[1]
	});
	var reduce=500;
	parole.splice(reduce,parole.length-reduce);

	var fill = d3.scale.category20();

	d3.layout.cloud().size([800, 500])
	  .words(parole.map(function(d) {
		return {text: d[0], size: 10 + d[1]};
	  }))
	  .padding(5)
	  .rotate(function() { return ((Math.random() * 2) * 90); })
	  .font("Impact")
	  .fontSize(function(d) { return d.size; })
	  .on("end", draw)
	  .start();

	function draw(words) {
	d3.select("#word-all").append("svg")
		.attr("width", 800)
		.attr("height", 500)
	  .append("g")
		.attr("transform", "translate(400,250)")
	  .selectAll("text")
		.data(words)
	  .enter().append("text")
		.style("font-size", function(d) { return d.size + "px"; })
		.style("font-family", "Impact")
		.style("fill", function(d, i) { return fill(i); })
		.attr("text-anchor", "middle")
		.attr("transform", function(d) {
		  return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")";
		})
		.text(function(d) { return d.text; });
	}

});
