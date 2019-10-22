function pageNoFix() {
	var pages = document.getElementsByClassName('pageNumber');
	for (var x = 0; x < pages.length; x++) {
   	var rect = pages[x].getBoundingClientRect();
   	var left_margin = 0;
   	if (rect.left > 100) {
   	   left_margin = 0 - (rect.left - 100);
   	}
   	pages[x].style.marginLeft = left_margin.toString() + "px";
   	pages[x].style.paddingRight = (-left_margin).toString() + "px";
	}
}