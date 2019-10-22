function pageNoFix() {
	var pages = document.getElementsByClassName('pageNumber');
	var main = document.querySelector('main');
	var main_pos = main.getBoundingClientRect().left;
	for (var x = 0; x < pages.length; x++) {
   	var rect = pages[x].getBoundingClientRect();
   	var left_margin = 0;
   	if (rect.left > main_pos) {
   	   left_margin = 0 - (rect.left - main_pos);
   	}
   	pages[x].style.marginLeft = left_margin.toString() + "px";
   	pages[x].style.paddingRight = (-left_margin).toString() + "px";
	}
}