
require "../lib/widgsock-app"
require "csv"

class Menu < Widgsock::Area

	def page(wnd)
		b1 = self.widget(:type=>"Button", :label=>"Page 1")
  		b1.on("click") do
  			wnd.page_init
  		end

		b2 = self.widget(:type=>"Button", :label=>"Page 2")
  		b2.on("click") do
  			wnd.page_2
  		end

  		b1.display(:x=>0, :y=>0)
  		b2.display(:x=>100, :y=>0)

  		m = self.widget(:type=>"Menu", :title=>"Menu 1", :items=>{:option1=>"Page1", :option2=>"Page2 bla bla bla"})
  		m.on("click") do |mess|
  			if mess["item"]=="option1"
  				wnd.page_init
  			elsif mess["item"]=="option2"
  				wnd.page_2
  			end
  		end

  		m.display(:x=>200, :y=>0)
	end

end

class Wnd < Widgsock::Area

	def page_init
  		self.refresh
		b1 = self.widget(:type=>"Button", :label=>"Button 1")
  		b1.display(:x=>0, :y=>0)

  		tab = self.widget(:type=>"Tabs", :tabs=>{"tab1"=>"Tab 1", "tab2"=>"Tab 2", 
  			"tab3"=>"Tab 3", "tab4"=>"Tab 4"} )
  		tab.display(:x=>20, :y=>40, :w=>400, :h=>150)

  		b3 = tab.widget(:tab=>"tab1", :type=>"Button", :label=>"Test button")
  		b3.display(:x=>0, :y=>0)

  		noms = CSV.parse(File.read('noms.csv'), :headers => true)
		prenoms = CSV.parse(File.read('prenoms.csv'), :headers => true)

		h = {}
		for i in 1..200
			nom = noms[rand(noms.length)].to_s.strip
			prenom = prenoms[rand(prenoms.length)].to_s.strip
			h["p"+i.to_s] = [nom, prenom]
		end

		titles = {:titles=>["Nom", "Prénom"]}
		w5 = tab.widget(:tab=>"tab2", :type=>"Table", :values=>h, :infos=>titles)
		w5.display(:x=>0, :y=>0, :w=>400, :h=>150)

		h = h.to_a.shuffle.to_h
		w6 = tab.widget(:tab=>"tab3", :type=>"Table", :values=>h, :infos=>titles)
		w6.display(:x=>0, :y=>0, :w=>400, :h=>150)

		w7 = self.widget(:type=>"FileUpload", :label=>"Upload file")
		w7.display(:x=>20, :y=>300)
		w7.on("file") do |f|
			puts "file name " + f["local_name"]
		end

		w8 = self.widget(:type=>"Input")
		w8.display(:x=>20, :y=>250)

		# w9 = tab.widget(:tab=>"tab4", :type=>"Img", :file=>"/tmp/img.jpg")
		# w9.display(:x=>0, :y=>0)


	    w10 = self.widget(:type=>"Canvas")
		w10.display(:x=>0, :y=>400, :h=>150, :w=>300)

		w10ctx = w10.get_context2d
	    w10ctx.fillStyle = "green";
     	w10ctx.fillRect(10, 10, 100, 100)

  	end

  	def page_2
  		self.refresh

  		noms = CSV.parse(File.read('noms.csv'), :headers => true)
		prenoms = CSV.parse(File.read('prenoms.csv'), :headers => true)

		h = {}
		for i in 1..200
			nom = noms[rand(noms.length)].to_s.strip
			prenom = prenoms[rand(prenoms.length)].to_s.strip
			h["p"+i.to_s] = [nom, prenom]
		end

		lblFiltre = self.widget(:type=>"Text", :label=>"Filtre : ")
		lblFiltre.display(:x=>0, :y=>5)
		filtre = self.widget(:type=>"Input")
		filtre.display(:x=>60, :y=>0, :w=>200)

		titles = {:titles=>["Nom", "Prénom"]}
		w5 = self.widget(:type=>"Table", :values=>h, :infos=>titles)
		w5.display(:x=>0, :y=>30, :w=>900, :h=>250)

		lblNbre = self.widget(:type=>"Text", :label=>"Nombre : " + h.length.to_s)
		lblNbre.display(:x=>0, :y=>290, :h=>250)

		filtre.on("keyup") do
			f = filtre.val
			puts "valeur filtre "+f
			nh = h.select { |k,v| 
			  r = Regexp.new(f, Regexp::IGNORECASE)
			  r =~ v[0] || r =~ v[1]
			}    
			w5.reset(:values=>nh, :infos=>titles) if nh
			lblNbre.reset(:label=>"Nombre : " + nh.length.to_s)
		end

		w5.on("click") do |mess|
			puts "click table"
			if mess["title"]!=nil
			  idxt = mess["title"].to_i
			  nh = Hash[h.sort_by{|k,v|v[idxt]}]
			  w5.reset(:values=>nh)
			end
			if mess["row"]!=nil
			  w5.val = mess["value"]
			  val = w5.values[mess["value"]]
			  dlg = Widgsock::Dialog.new( :w=>400, :h=>100, :app=>app, :name=>"alerte" )
			  dlg_b = dlg.widget(:type=>"Button", :label=>"OK")
			  dlg_b.display(:x=>190, :y=>65, :w=>80)
			  dlg_t = dlg.widget(:type=>"Text", :label=>"Voici la fiche de "+val[0]+" "+val[1])
			  dlg_t.display(:x=>20, :y=>10, :w=>350)
			  dlg_b.on("click") do 
			    p "click button ok"
			    dlg.close
			  end       
			end
		end

  	end
end


Widgsock::register("first") do |app|

  tracer = Logger.new(STDOUT)
  tracer.level = Logger::DEBUG
  app.options(:tracer=>tracer)

  main = app.get_area

  menu = Menu.new(:w=>main.w, :h=>30, :name=>"menu")
  app.set_area("menu", menu)

  wnd = Wnd.new(:w=>main.w, :y=>40, :h=>main.h-40, :name=>"wnd", :app=>app)
  app.set_area("wnd", wnd)

  menu.page(wnd)
  wnd.page_init

end

Widgsock::run
