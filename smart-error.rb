require 'rubygems'
require 'rack'
require 'sinatra/base'
require 'rack-flash'
require 'redis'

class Site
	def initialize(info)
		@info = info
	end
	def name; @info[:name]; end
	[:host]
end
def Site(*args);Site.new(*args);end
Sites = { 'localhost' => Site(:name => 'Local Site') }

class SmartError < Sinatra::Base
	VALID_EMAIL = /^([\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+\.)*[\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+@((((([a-z0-9]{1}[a-z0-9\-]{0,62}[a-z0-9]{1})|[a-z])\.)+[a-z]{2,6})|(\d{1,3}\.){3}\d{1,3}(\:\d{1,5})?)$/i

	enable :sessions
	use Rack::Flash, :sweep => true
	configure do
	  uri = URI.parse(ENV["REDISTOGO_URL"]||"redis://locahost:6379/0")
	  REDIS = Redis.new
	end
	set :public, File.join(File.dirname(__FILE__), "public")

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

post '/letmeknow' do
	host = params[:host] || request.host
	email = params[:email]

	if email && VALID_EMAIL.match(email)
		REDIS.sadd('hosts/toEmail', host)
		REDIS.sadd("hosts/#{host}/emails", email)
		flash[:notice] = "<p style='color:#260'>Thanks - we'll let you know as soon as #{h host} is back online!</p>"
	else
		flash[:warn] = "<p style='color:red'>Sorry - the email address #{h email} isn't valid.</p>"
	end
	redirect '/thankyou'
end
['/', '/default', '/order/*', '/find/*', '/about/*', '/contact', '/terms', '/thankyou', '/mylab/*'].each do |path|
get path do
	host = params[:host] || request.host

	form = <<-EOFORM
<form method="post" action="/letmeknow" oninvalid="alert('Not good!')">
	<input type="hidden" name="host" value="#{h host}"/>
	<input name="email" id="email" type="email" placeholder="Email address" value="" oninvalid="warnInvalid('#email')">
	<input type="submit" value=" Let me know ">
</form>
EOFORM

<<-EOSTD
<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" href="/styles/reset.css">
<title>#{h host}</title>
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
<script>
function warnInvalid(selector) {
	jQuery(selector).css({'borderColor':'#c00',backgroundColor:"#fcc"});
	jQuery(selector).animate({'left': '+=15'}, 150, function () { 
		jQuery(selector).animate({'left':'-=20'}, 160, function () {
			jQuery(selector).animate({'left': '+=15'}, 80, function () {
				jQuery(selector).animate({'left': '-=10'}, 50, function () {
					jQuery(selector).css({'borderColor':'#ccc',backgroundColor:'#fff'});
					jQuery('selector').focus();
				});
			});
		});
	});
}
</script>
<style type="text/css">
body { background: black;}
#image {
 width: 550px; 
 float: left;
 margin-top: 40px;
}
#info {
	width: 340px;
	float: left;
	background-image: url(/info-box.png);
	padding: 35px;
	min-height: 470px;
}
h1 {
	font-family: Verdana, Helvetica, sans-serif;
	font-weight: bold;
	color: #734d7b;
	font-size: 38px;
	margin-bottom: 14px;
}
h2 {
	font-family: Verdana, Helvetica, sans-serif;
	font-style: italic;
	font-size: 18px;
	color: #63426a;
	margin-bottom: 14px;
}
p {
	font-family: Verdana, Helvetica, sans-serif;
	font-size: 12px;
	margin-top: 2px;
	margin-bottom: 14px;
	color: #666;
}
input[type=text], input[type=email] {
	position: relative;
	border: 2px solid #ccc;
	padding: 4px;
	border-radius: 6px;
	-moz-border-radius: 6px;
	-webkit-border-radius: 6px;
	font-size: 14px;
	width: 250px;
}
input[type=submit] {
	padding: 4px;
	border-radius: 6px;
	-moz-border-radius: 6px;
	-webkit-border-radius: 6px;
	font-weight: bold;
	background: #734d7b;
	color: white;
	width: 250px;
	border: 2px solid #63426a;
}
form { text-align: center; }
</style>
</head>
<body>
<div style="width: 960px; margin: 0 auto;">
	<div id="image">
	<img src="/monitor-background.png" 
		style="background-image: url(/small/#{h host}.jpg); background-position: 22px 22px;">
	</div>
	<div id="info">
		<h1>Sorry</h1>
		<h2>That site's not available right now...</h2>
		<p>We're in the middle of some scheduled maintenance right now - unfortunately that 
		means you can't access the site you were trying to.</p>
		<p>Everything should be back to normal by tomorrow morning (9 am, Wednesday 29th September) 
		so you can check back then.</p>
		<p>Alternatively if you'd like to know as soon as the #{h host} site is back online, 
		you can leave your email address in the form below and we'll email you as soon as the site is up.</p>
		
		#{flash[:warn]}
		#{flash[:notice] || form}
		</div>
</div>
</body>
</html>
EOSTD
end
end
end


