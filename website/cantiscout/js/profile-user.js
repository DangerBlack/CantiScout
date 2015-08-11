function initProfile(){
	//loadUserSpace();
	//loadUserDetail();
	$(".description-send").hide();
	$(".avatar-send").hide();
	$(".username-send").hide();
	//loadGamesList("#gamesList",createGameViewLi);
	$(".description-edit").click(function(){
		var desc=$("#userDescription").text();
		$("#userDescription").html('<textarea id="desc-area">'+desc+'</textarea>');
		$(".description-edit").hide();
		$(".description-send").show();
		$(".description-send").click(function(){
			var description=$("#desc-area").val();
			$.post("php/setUserInfo.php",{"kind":3,"description":description},function(data){
				$("#userDescription").text(description);
				$(".description-edit").hide();
				$(".description-send").show();
			});
		});
	});
	$(".avatar-edit").click(function(){
		var avatar=$("#userAvatar img").attr("src");
		$("#userAvatar").html('<label>URL: </label><input id="avatar-area" class="profile" type="text" value="'+avatar+'" />');
		$(".avatar-edit").hide();
		$(".avatar-send").show();
		$(".avatar-send").click(function(){
			var avatar=$("#avatar-area").val();
			$.post("php/setUserInfo.php",{"kind":2,"picture":avatar},function(data){
				$("#userAvatar").html('<img src="'+avatar+'" />');
				$(".avatar-edit").hide();
				$(".avatar-send").show();
			});
		});
	});
	$(".username-edit").click(function(){
		var username=$("#username").text();
		$("#username").html('<label>Username: </label><input id="username-area" class="profile" type="text" value="'+username+'" />');
		$(".username-edit").hide();
		$(".username-send").show();
		$(".username-send").click(function(){
			var username=$("#username-area").val();
			$.post("php/setUserInfo.php",{"kind":0,"name":username},function(data){
				$("#username").text(username);
				$(".username-edit").hide();
				$(".username-send").show();
			});
		});
	});
	$(".pswd-send").click(function(){
		var oldPswd=$("#oldPswd").val();
		var newPswd=$("#newPswd").val();
		var newPswd2=$("#newPswd2").val();
		if(newPswd==newPswd2){
			$.post("php/setUserInfo.php",{"kind":2,"newPswd":newPswd,"oldPswd":oldPswd},function(data){
				$("#oldPswd").val("");
				$("#newPswd").val("");
				$("#newPswd2").val("");
			});
		}else{
			alert("Password non match");
		}
	});
}
function hideAllEdit(){
	$(".description-send").hide();
	$(".avatar-send").hide();
	$(".username-send").hide();
	$(".pswd-send").hide();
	$(".description-edit").hide();
	$(".avatar-edit").hide();
	$(".username-edit").hide();
	$("#oldPswd").hide();
	$("#newPswd").hide();
	$("#newPswd2").hide();
	$(".pswd").hide();
	
}
