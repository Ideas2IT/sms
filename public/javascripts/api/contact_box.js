/**
 * @author madan
 */
process_api();
function process_api(){
	var scripts=document.getElementsByTagName('script');
var query=(scripts[scripts.length - 1].src.replace(/^[^\?]+\??/,''));
var params = new Object ();
   var pairs = query.split(/[;&]/);
   for ( var i = 0; i < pairs.length; i++ ) {
      var KeyVal = pairs[i].split('=');
      if ( ! KeyVal || KeyVal.length != 2 ) continue;
      var key = unescape( KeyVal[0] );
      var val = unescape( KeyVal[1] );
      val = val.replace(/\+/g, ' ');
      params[key] = val;
   }
	alert("hi");
	document.write("<iframe src='http://localhost:3000/show_contact_admin?token="+params['token']+"' height='118px' width='155px' scrolling=no frameborder='1'></iframe>");
}