#!/bin/bash

function http_parameter() {
	echo "$QUERY_STRING" | tr '&' '\n' | grep "^$1=" | sed "s/^$1=//g" | head -n 1
}

function http_parameters() {
	echo "$QUERY_STRING" | tr '&' '\n' | grep "^$1=" | sed "s/^$1=//g"
}

function http_decode() {
	busybox httpd -d "$1"
}

function http_load() {
	PAGE=$1
	if [ -z "$PAGE" ]
	then
		PAGE=home.page
	elif echo "$PAGE" | grep -q /
	then
		ERROR="$PAGE not exist"
		PAGE=home.page
	elif [ ! -e "pages/$PAGE" ]
	then
		ERROR="$PAGE not exist"
		PAGE=home.page
	fi

	source pages/$PAGE
}

function http_action_download() {
	target=$(http_parameter target)
	target=$(http_decode "$target")
	if [ -z "$target" ]
	then
		return 1
	elif [ -f "$target" ]
	then
		name=$(basename "$target")
		echo "Content-Type: application/x-download"
		echo "Content-Disposition: attachment;filename="
		echo
		cat $target
	elif [ -d "$target" ]
	then
		name=$(basename "$target")
		echo "Content-Type: application/x-download"
		echo "Content-Disposition: attachment;filename=$target"
		echo
		ls -l $target
	else
		return 2
	fi
}

function http_action_delete() {
	target=$(http_parameter target)
	target=$(http_decode "$target")
	[ -z "$target" -o "$target" = "/" ] && return
	ERROR=$(rm -rf "$target" 2>&1)
	[ -z "$ERROR" ] || ERROR="Create file: '$path' failed, $ERROR"
}

function http_action_create() {
	path=$(http_parameter path)
	path=$(http_decode "$path")
	name=$(http_parameter name)
	name=$(http_decode "$name")
	type=$(http_parameter type)
	if [ "$path" = "/" ]
	then
		path="/$name"
	else
		path="$path/$name"
	fi
	case "$type" in
		file)
			ERROR=$(touch "$path" 2>&1)
			[ -z "$ERROR" ] || ERROR="Create file: '$path' failed, $ERROR"
		;;
		folder)
			ERROR=$(mkdir -p "$path" 2>&1)
			[ -z "$ERROR" ] || ERROR="Create folder: '$path' failed, $ERROR"
		;;
		*)
			ERROR="Unknown type: '$type'"
		;;
	esac
}

function http_action_save() {
	path=$(http_parameter path)
	path=$(http_decode "$path")
	content=$(cat - | sed 's/^content=//g');
	http_decode "$content" > "$path"
}

function page_error() {
	[ -z "$ERROR" ] && return
cat <<EOF:ERROR
	<div class="alert alert-warning" style="margin: 15px;">
		<a href="#" class="close" data-dismiss="alert">&times;</a>
		<strong>Error! </strong>$ERROR.
	</div>
EOF:ERROR
}
case "$(http_parameter action)" in
	reboot)
		/bin/bash -c 'sleep 3;reboot' &>/dev/null &
	;;
	shutdown)
		/bin/bash -c 'sleep 3;poweroff' &>/dev/null &
	;;
	download)
		http_action_download && exit
	;;
	create)
		http_action_create
	;;
	delete)
		http_action_delete
	;;
	save)
		http_action_save
	;;
esac

http_load $(http_parameter page)


module_process

echo

#start
cat <<EOF:HTML
<!DOCTYPE html>
<html>
	<head>
		<title>$(module_title)</title>
		<meta charset="utf-8"> 
		<meta name="viewport" content="width=device-width, initial-scale=0.8">
		<link rel="stylesheet" href="/bootstrap/css/bootstrap.min.css">  
		<script src="/jquery/jquery.js"></script>
		<script src="/bootstrap/js/bootstrap.min.js"></script>

		<link rel="stylesheet" href="/pikaday/css/pikaday.css">
		
		<script src="/pikaday/js/pikaday.js"></script>

		<link rel="stylesheet" href="/css/gnome.css">
		<script src="/js/gnome.js"></script>

		<script>
			function onLoad(){
				gnome.status.timer.view="time-viewer";
				gnome.status.timer.update();

				new Pikaday({
					field: document.getElementById("time-viewer"),
					firstDay: 1,
					minDate: new Date(),
					maxDate: new Date(2020, 12, 31),
					yearRange: [2000,2020]
				});
				onResize();
			}
			function onResize(){
				var desktop = document.getElementById("gnome-desktop");
				var height = document.body.clientHeight - desktop.offsetTop;
				desktop.style.height = height + "px";
			}
		</script>
		
		$(module_head)

	</head>
	<body onload="onLoad()"  onResize='onResize();'>
		<div id="gnome-status-bar-left" align="left">
			<div class="btn-group">
				<span data-toggle="dropdown" class="dropdown-toggle">
					<span style="margin-right: 5px">Application</span>
					<span class="caret" style="margin-right: 5px"></span>
					<span style="margin-right: 5px">$(module_icon)$(module_title)</span>
				</span>
				<ul class="dropdown-menu">
					<li><a href="$SCRIPT_NAME?page=home.page"><span class="glyphicon glyphicon-home" style="margin-right: 5px"></span>Home</a></li>
					<li><a href="$SCRIPT_NAME?page=storage.page"><span class="glyphicon glyphicon-hdd" style="margin-right: 5px"></span>Storage</a></li>
					<li><a href="$SCRIPT_NAME?page=terminal.page"><span class="glyphicon glyphicon-play" style="margin-right: 5px"></span>Terminal</a></li>
					<li><a href="$SCRIPT_NAME?page=explorer.page"><span class="glyphicon glyphicon-folder-open" style="margin-right: 5px"></span>Explorer</a></li>
				</ul>
				$(module_action)
			</div>
		</div>
		<div id="gnome-status-bar-center" align="center">
			<div class="btn-group">
				<span id="time-viewer" data-toggle="dropdown" class="dropdown-toggle">$(date "+%F %H:%M")</span>
			</div>
		</div>
		<div id="gnome-status-bar-right" align="right">
			<div class="btn-group">
				<span data-toggle="dropdown" class="dropdown-toggle">
					<span class="glyphicon glyphicon-off" style="margin-right: 5px"></span>
					<span class="glyphicon glyphicon-user" style="margin-right: 5px"></span>
					<span class="glyphicon caret"></span>
				</span>
				<ul class="dropdown-menu pull-right">
					<li><a href="#"><span class="glyphicon glyphicon-user" style="margin-right: 5px"></span>$REMOTE_USER</a></li>
					<li class="divider"></li>
					<li><a href="$SCRIPT_NAME?page=$PAGE&action=reboot"><span class="glyphicon glyphicon-refresh" style="margin-right: 5px"></span>Reboot</a></li>
					<li><a href="$SCRIPT_NAME?page=$PAGE&action=shutdown"><span class="glyphicon glyphicon-off" style="margin-right: 5px"></span>Shutdown</a></li>
				</ul>
			</div>
		</div>
		<div id="gnome-desktop" style="float:left; width:100%; height:auto">
			$(page_error)
			$(module_body 2>&1)
		</div>
	</body>
</html>
EOF:HTML
