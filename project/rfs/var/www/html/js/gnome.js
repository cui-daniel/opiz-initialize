var gnome = new Object();

gnome.status = new Object();
gnome.status.timer = new Object();
gnome.status.timer.update = function () {
	var now = new Date();
	var result = "";

	var month = now.getMonth() + 1;
	if (month < 10) {
		result += '0';
	}
	result += month;
	result += '-';

	var day = now.getDate();
	if (day < 10) {
		result += '0';
	}
	result += day;
	result += ' ';

	var hours = now.getHours();
	if (hours < 10) {
		result += '0';
	}
	result += hours;
	result += ':';

	var minutes = now.getMinutes();
	if (minutes < 10) {
		result += '0';
	}
	result += minutes;

	document.getElementById(gnome.status.timer.view).innerHTML = result;
	window.setTimeout(gnome.status.timer.update, 1000);  
}
