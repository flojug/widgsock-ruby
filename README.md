
Introduction
================

Widgsock is a javascript library which, combined with a symetric proxy server library, allows one to write web application in the server targeted language.

The programer will never have to write some HTML code nor Javascript or CSS.

Everything is done in the targeted language.

For now the only server library exists in ruby : widgsock-ruby.

Technology
============

Widgsock uses websockets to build a communication channel with the server.

The browser first retrieves a simple HTML5 page which just contains a web area and a link to the Widgsock library.

Widgsock library then connects to the websocket server and all the rest of exchanges are made by this channel.

Ruby implementation
=====================

The ruby implementation of widgsock uses websocket-eventmachine-server to build the websocket server.

Installation
=====================

	gem install "websocket-eventmachine-server"
	gem install "json"
	gem install "rmagick"
	git clone https://github.com/flojug/widgsock
	git clone https://github.com/flojug/widgsock-ruby

How to use it
=====================

First define a simple web page which contains a link to the library (see below). This page (and the targeted library) must be accessible through a web server.

Then run the ruby application which contains the code to run.

	cd examples
	ruby app2.rb

Then point your browser to the HTML page and the application should run in your browser.

Example 
============

HTML page : 
--------------

The only HTML code the programmer has to write is to define an area (or several areas) in a web page and apply the widgsock library on it.


	<!DOCTYPE html>
	<html>
	<header>
	  <meta charset="utf-8" />
	  <link rel="stylesheet" href="css/widgsock.css" type="text/css" media="screen">
	  <script language='javascript' src='http://code.jquery.com/jquery-2.1.4.js' type='text/javascript'></script>
	  <script language='javascript' src='libjs/widgsock.js' type='text/javascript'></script>
	<script>
	  $(function() {  widgsock.run("first");  });  
	</script>
	</header>
	<body>
	  <div id="first" style="width:900px;height:600px;position:relative;">
	   </div>
	</body>
	</html>

It is possible to define several zones on the page and target specific programs on those zones.

	$(function() {
		widgsock.run("first");
		widgsock.run("second");
	});  


Ruby application :
-------------------

The server builds an widgsock-app object and passes it to the loop which contains the code for application.

	Widgsock::register("first") do |app|
		... application
	end
	Widgsock::run

Widsock-ruby impements some widgets which allow the programer to draw the sreens of application. 

Everything is done in ruby language.

Example : for drawing a select widget on the screen :

	arr = {"val1"=>"first value", "val2"=>"second value"}
	w = app.widget(:type=>"Select", :values=>arr)
	w.display(:x=>0, :y=>0)

For now all the widgets are displayed in absolute mode (x,y,w,h) in the area of the application.

Each widget allows the programer to retrieve events :

	w.on("change") do
		puts "w.val=" + w.val
	end

Application
========

Areas
========

A default area is set to the default zone from the HTML window. It is then possible to define new areas from this one and attach widgets to those areas.

	Widgsock::register("first") do |app|

		main = app.get_area

		menuarea = Area.new(:w=>main.w, :h=>30, :name=>"menu")
		app.set_area("menu", menuarea)

		m = menuarea.widget(:type=>"Menu", :title=>"Menu 1", :items=>{:option1=>"Page1", :option2=>"Page2 bla bla bla"})
		m.on("click") do |mess|
			if mess["item"]=="option1"
				...
			elsif mess["item"]=="option2"
				...
			end
		end

	end

Widgets 
========

Widgets can be constructed either from an aera or an application. They are constructed by a factory method which receveives the widget type as argument :

	w = app.widget( :type=> ..., ... )


Select widget
------------------

	arr = {"val1"=>"first value", "val2"=>"second value"}
	w = app.widget(:type=>"Select", :values=>arr)
	w.display(:x=>0, :y=>0)

	w.on("change") do
		puts "w.val=" + w.val
	end

MultiSelect widget
------------------

	w = app.widget(:type=>"MultiSelect", :values=>h)
	w.display(:x=>500, :y=>100, :w=>100, :h=>100)

	w.on("change") do
		txt = w.val.to_s
	end

FileUpload widget
------------------

	w = app.widget(:type=>"FileUpload", :label=>"Upload file")
	w.display(:x=>20, :y=>300)
	w.on("file") do |f|
		puts "file name " + f["local_name"]
	end

Menu widget
------------------

	w = app.widget(:type=>"Menu", :title=>"Menu 1", :items=>{:option1=>"Page1", :option2=>"Page2 bla bla bla"})
	w.on("click") do |mess|
		if wess["item"]=="option1"
			...
		elsif mess["item"]=="option2"
			...
		end
	end

Input widget
------------------

	w = self.widget(:type=>"Input")
	w.display(:x=>60, :y=>0, :w=>200)

Textarea widget
------------------

	txtarea = app.widget(:type=>"Textarea", :value=>"Test")
	txtarea.display(:x=>0, :y=>100, :w=>400, :h=>100)
	txtarea.on("change") do |mess|
		...
	end

Button widget
------------------

	b = self.widget(:type=>"Button", :label=>"Page 1")
	b.on("click") do
		...
	end

Canvas widget
------------------

For manipulation of canvas into HTML5 page, a proxy object is built. All calls are made as they would be done in javascript onto this object.

	w = app.widget(:type=>"Canvas")
	w.display(:x=>0, :y=>400, :h=>150, :w=>300)
	wctx = w.get_context2d
	wctx.fillStyle = "green";
	wctx.fillRect(10, 10, 100, 100)

Iframe widget
------------------

	ifr = app.widget(:type=>"Iframe", :url=>"http://google.com")
	ifr.display(:x=>0, :y=>270, :w=>900, :h=>250)

Text widget
------------------

Used to display text in the window.

	w = app.widget(:type=>"Text", :label=>"Filter : ")
	w.display(:x=>0, :y=>5)

Img widget
------------------

Used to display an image in the window. The image is given as a local file on the server. It will be given to the browser directly into the HTML5 code.

	w = tab.widget(:tab=>"tab4", :type=>"Img", :file=>"/tmp/img.jpg")
	w.display(:x=>0, :y=>0)


Tabs widget
------------------

	# display a 3 tabs widget
	tab = self.widget(:type=>"Tabs", :tabs=>{"tab1"=>"Tab 1", "tab2"=>"Tab 2", 
		"tab3"=>"Tab 3", "tab4"=>"Tab 4"} )
	tab.display(:x=>20, :y=>40, :w=>400, :h=>150)

	# display a button in tab1
	b = tab.widget(:tab=>"tab1", :type=>"Button", :label=>"Test button")
	b.display(:x=>0, :y=>0)


Table widget
------------------

	infos = {:titles=>["First name", "Last name"]}
	w = self.widget(:type=>"Table", :values=>h, :infos=>infos)
	w.display(:x=>0, :y=>30, :w=>900, :h=>250)



