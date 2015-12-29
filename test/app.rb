
require "../lib/widgsock-app"
require "csv"

Widgsock::register("first") do |app|

  tracer = Widgsock::Tracer.new(:level=>Widgsock::Tracer::LOG_DEBUG)
  app.options(:tracer=>tracer)

  app.log "running...", Widgsock::Tracer::LOG_DEBUG

  arr = {"liste1"=>"1ere liste", "liste2"=>"deuxieme liste"}
  w = app.widget(:type=>"Select", :values=>arr)
  w.display(:x=>0, :y=>0)

  arr = {"option1"=>"Sel2Opt1", "option2"=>"Sel2Opt2"}
  w2 = app.widget(:type=>"Select", :values=>arr)
  w2.display(:x=>100, :y=>0)

  h = {
      "val1"=>"Valeur1", 
      "val2"=>"Valeur2", 
      "val3"=>"Valeur3", 
      "val4"=>"Valeur4", 
      "val5"=>"Valeur5", 
      "val6"=>"Valeur6", 
      "val7"=>"Valeur7"
    }
  w4 = app.widget(:type=>"MultiSelect", :values=>h)
  w4.display(:x=>500, :y=>100, :w=>100, :h=>100)

  noms = CSV.parse(File.read('noms.csv'), :headers => true)
  prenoms = CSV.parse(File.read('prenoms.csv'), :headers => true)

  h = {}
  for i in 1..2000
    nom = noms[rand(noms.length)].to_s.strip
    prenom = prenoms[rand(prenoms.length)].to_s.strip
    h["p"+i.to_s] = [nom, prenom]
  end

  lblFiltre = app.widget(:type=>"Text", :label=>"Filtre : ")
  lblFiltre.display(:x=>0, :y=>245)
  filtre = app.widget(:type=>"Input")
  filtre.display(:x=>60, :y=>240, :w=>200)

  titles = {:titles=>["Nom", "Prénom"]}
  w5 = app.widget(:type=>"Table", :values=>h, :infos=>titles)
  w5.display(:x=>0, :y=>270, :w=>900, :h=>250)

  lblNbre = app.widget(:type=>"Text", :label=>"Nombre : " + h.length.to_s)
  lblNbre.display(:x=>0, :y=>530, :h=>250)

  arrurls = {
    "liste1"=>{""=>"--choisir--", "url1"=>"http://site1.com", "url2"=>"http://site2.com"},
    "liste2"=>{""=>"--choisir--", "url1"=>"http://site3.com", "url2"=>"http://site4.com"}
    };
  w3 = app.widget(:type=>"Select", :values=>arrurls["liste1"], :value=>"url1")
  w3.display(:x=>0, :y=>30, :w=>300)

  i = app.widget(:type=>"Input", :value=>"salut")
  i.display(:x=>200, :y=>0, :w=>400)  

  s1 = app.widget(:type=>"Input")
  s2 = app.widget(:type=>"Input")
  s1.display(:x=>300, :y=>0)
  s2.display(:x=>400, :y=>0)

  b = app.widget(:type=>"Button", :label=>"Test bouton")
  b.display(:x=>500, :y=>0)

  t = app.widget(:type=>"Text", :label=>"Test de texte alentour")
  t.display(:x=>700, :y=>0, :w=>250)

  # ifr = app.widget(:type=>"Iframe", :url=>"http://www.apropos-fr.com")
  # ifr.display(:x=>0, :y=>270, :w=>900, :h=>250)

  txtarea = app.widget(:type=>"Textarea", :value=>"Test de textarea")
  txtarea.display(:x=>0, :y=>100, :w=>400, :h=>100)

  w4.on("change") do
    txt = w4.val.to_s
    txtarea.val = txt
  end

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
      val = w5.values[mess["value"]]
      dlg = Widgsock::Dialog.new( :w=>400, :h=>100, :app=>app, :name=>"alerte" )
      dlg_b = dlg.widget(:type=>"Button", :label=>"OK")
      dlg_b.display(:x=>190, :y=>70)
      dlg_t = dlg.widget(:type=>"Text", :label=>"Voici la fiche de "+val[0]+" "+val[1])
      dlg_t.display(:x=>20, :y=>10, :w=>350)
      dlg_b.on("click") do 
        p "click button ok"
        dlg.close
      end       
    end
  end

  w.on("change") do
    puts "w.val=" + w.val
    w3.reset(:values=>arrurls[w.val], :value=>"url1")
    # ifr.url = w3.item
    # ifr.refresh
  end

  w3.on("change") do
    if !w3.item.empty? 
      # ifr.url = w3.item
      # ifr.refresh
    end
  end

  w.on("change") do 
    puts "la valeur de "+w.name+" est "+w.val
    i.val = w.item
    i.trigger("focus")
  end

  w2.on("change") do 
    puts "la valeur de "+w2.name+" est "+w2.val
    i.val = w2.item
  end

  w2.on("focus") do
    puts "focus w2"
  end

  b.on("click") do
    puts "le bouton est cliqué"
    val = s1.val.to_i + s2.val.to_i
    i.val = val.to_s
  end

  i.on("focus") do
    puts "focus sur le champ texte"
  end

  s1.on("keydown") do
    puts "frappe touuche s1"
  end

  s2.on("mousemove") do
  end

end

Widgsock::run