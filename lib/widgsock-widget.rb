# This file is part of Widgsock-ruby.

# Widgsock-ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Widgsock-ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License
# along with Widgsock-ruby.  If not, see <http://www.gnu.org/licenses/>. 

# Copyright 2015 Florent Jugla <florent@jugla.name>

module Widgsock

  # proxy of a javascipt object
  class ProxyJS

    attr_reader :app, :proxy_name, :widget_name

    def initialize(app, widget_name, proxy_name)
      @widget_name = widget_name
      @proxy_name = proxy_name
      @app = app
    end

    def method_missing(key, *args)
      text = key.to_s
      if text[-1,1] == "="
        @app.sendmsg({:action=>"proxy_assign_value", :proxy_name=>@proxy_name,
         :name=>@widget_name, :proxy_field=>text.chomp("="), :proxy_value=>args[0]})
      else
        @app.sendmsg({:action=>"proxy_apply_method", :proxy_name=>@proxy_name,
         :name=>@widget_name, :proxy_function=>text, :proxy_args=>args})
      end
    end

  end

  # widget class
  class Widget

    attr_reader :type, :name
    attr_accessor :surrounding_widget

    # used to name widgets
    @@cpt = 0
    # table of all widgets
    @@widgets = {}

    # return unique name of widget
    def self.new_name(type="widg")
      @@cpt = @@cpt+1
      cpt = @@cpt
      ret = type + cpt.to_s
      ret
    end

    # return the widget by name
    def self.get_widget(name)
      @@widgets[name]
    end

    # unregister widget
    def self.unset_widget(name)
      @@widgets.delete(name)
    end

    # check arguments used in widget constructors
    def self.check_args(args, keys)
      keys.each do |key,out|
        raise ArgumentError, "#{out} must be initialialized. #{args}" if !args[key]  
      end
    end

    # make a new widget
    def self.factory(args)
      Widget::check_args(args, {:type=>"Type"})    
      type = args[:type]
      cl = Object.const_get('Widgsock::'+type)
      raise ArgumentError, "unknown widgsock type #{type}" if !cl.is_a?(Class)
      w = cl.new(args)
    end

    def initialize(args)
      Widget::check_args(args, {:area=>"Area", :type=>"Type", :app=>"App"})
      @type = args[:type]
      @name = Widgsock::Widget.new_name
      @app = args[:app]
      @handlers = {}
      @area = args[:area]    
      @@widgets[@name] = self
      @app.sendmsg(message.merge({:action=>"new"}))
      # used when a widget is display inside antother widget
      # (example: tabs)
      @surrounding_widget = nil  
    end

    def on(ev, &block)
      if !@handlers[ev]
        @handlers[ev] = [ block  ]
      else
        @handlers[ev].push block
      end
      
      # send a message to client to register this event
      @app.sendmsg(message.merge({:action=>"register_event", :event=>ev}))
    end

     def trigger(ev)
      self.focus_clt if ev=="focus"
    end

       # used by widgets which return big data (i.e images)
       def get_data(which)
         ""
       end

      def message
       ret = {:type=>@type, :name=>@name}
       if @surrounding_widget!=nil
        refpos = @surrounding_widget.get_ref_pos(@name)
        ret[:refpos] = refpos if refpos!=nil
      end
      ret
    end

    def display(args)
     x = args[:x] || -1
     y = args[:y] || -1
     raise ArgumentError, "#{x}  #{y} invalid position." if (x==-1) || (y==-1)
     mess = message.merge({:action=>"display", :x=>x, :y=>y})
     mess[:area] = @area.name
     mess[:w] = args[:w] if args[:w]
     mess[:h] = args[:h] if args[:h]
     @app.sendmsg(mess)
   end  

   def refresh
     mess = message.merge({:action=>"refresh"})
     @app.sendmsg(mess)
   end

 end

  # implements stubs on class Widget
  stubs = [ "focus", "blur", "focusin", "focusout", "change", "click", "dblclick",
    "keydown", "keyup", "mousedown", "mouseenter", "mouseleave", "mousemove", "mouseout", 
    "mouseover", "mouseup", "resize", "scroll", "wheel" ]

   stubs.each do |stub|
    Widget.class_eval <<-EVAL
    def #{stub}_clt
      mess = message.merge({:action=>'apply_event', :event=>'#{stub}'})
      @app.sendmsg(mess)
    end

    def #{stub}_srv mess
      #{stub}_lcl mess
      if @handlers['#{stub}']
       for block in @handlers['#{stub}']
        block.call mess
      end
    end
  end

  def #{stub}_lcl mess
  end
  EVAL
end

class Select < Widget

  attr_reader :val
  attr_reader :item

  def val=(value)
   old = @val
   @val = value
   if old!=@val
    @item = @values[@val] if @values.has_key?(@val) 
    self.refresh
  end
end

def message
 super.merge({:values=>@values, :value=>@val})
end

def reset(args)
 @values = args[:values]
 @val = args[:value] || ""
 @item = @values[@val] if @values.has_key?(@val)
 @app.sendmsg(message.merge({:action=>"refresh"}))
end  

def change_lcl(mess)
  @val = mess["val"];      
 @item = @values[@val]
 puts "item=" + @item
 super mess
end

protected

def initialize(args)
 args[:type] = "Select" if !args[:type]
 @values = args[:values]
 @val = args[:value] || "0"
 @item = ""
 @item = @values[@val] if @val!="0"
 super args
 @app.sendmsg(message.merge({:action=>"register_event", :event=>"change"}))
end

end

class MultiSelect < Widget

  attr_reader :val
  attr_reader :values

  def val=(val)
   old = @val
   @val = val
   self.refresh if old!=val
 end

 def message
   super.merge({:values=>@values, :val=>@val})
 end

 def reset(args)
   @values = args[:values]
   @val = args[:val] || []
   @app.sendmsg(message.merge({:action=>"refresh"}))
 end  

 def change_lcl(mess)
   @val = mess["val"]
   super mess
 end

 protected

 def initialize(args)
   args[:type] = "MultiSelect" if !args[:type]
   @values = args[:values]
   @val = args[:val] || []
   super args
   @app.sendmsg(message.merge({:action=>"register_event", :event=>"change"}))
 end

end

class FileUpload < Widget

  attr_reader :label
  attr_reader :filters

  def message
   super.merge({:label=>@label, :filters=>@filters})
 end

 def file_srv mess
   if @handlers['file']
    for block in @handlers['file']
     block.call mess
   end
 end
end

def on(ev, &block)
 if ev=='file'
  if !@handlers[ev]
    @handlers[ev] = [ block  ]
 else
   @handlers[ev].push block
 end
else
  super ev, block
end
end

protected

def initialize(args)
  args[:type] = "FileUpload" if !args[:type]      
 @label = ""
 @label = args[:label] if args[:label]
 @filters = []
 @filters = args[:filters] if args[:filters]
 super args      
end

end

class Menu < Widget

  attr_reader :title
  attr_reader :items

  def message
    super.merge({:items=>@items, :title=>@title})
  end

  def reset(args)
   @items = args[:items] if args[:items]
   @title = args[:title] if args[:title]
   @app.sendmsg(message.merge({:action=>"refresh"}))
 end  

 protected

 def initialize(args)
   args[:type] = "Menu" if !args[:type]
   @items = {}
   @title = ""
   @items = args[:items] if args[:items]
   @title = args[:title] if args[:title]
   super args      
 end

end

class Table < Widget

  attr_reader :val
  attr_reader :values

  def val=(val)
   old = @val
   @val = val
   self.refresh if old!=val
 end

 def message
   super.merge({:values=>@values, :val=>@val, :infos=>@infos})
 end

 def reset(args)
   @values = args[:values]
   @val = args[:val] if args[:val]
   @infos = args[:infos] if args[:infos]
   reset_infos
   @app.sendmsg(message.merge({:action=>"refresh"}))
 end  

  # change values in the table
  def reset_infos      
    if @values.first
      nb = @values.first[1].length
    elsif @infos["title"]
      nb = @infos["title"].length
    else
      nb = 1
    end        
    if !@infos["w"]
      w = (100 / nb).to_s + "%"
      @infos["w"] = Array.new(nb, w)
    end
    if !@infos["position"]
      @infos["position"] = Array.new(nb, "center")
    end
  end

  protected

  def initialize(args)
    args[:type] = "Table" if !args[:type]
    @values = args[:values]
    @val = args[:val] || []
    @infos = args[:infos] || {}
    reset_infos
    super args
  end

end


class Input < Widget
  attr_reader :val

  def val=(value)
   old = val
   @val = value
   self.refresh if old!=@val
 end

 def message
   super.merge({:value=>@val})
 end

 def change_lcl(mess)
   @val = mess["val"];
   super mess
 end

    # init the widget with the new val
    def keyup_lcl(mess)
      @val = mess["val"]
      super mess
    end

    protected

    def initialize(args)
      args[:type] = "Input" if !args[:type]
      @val = args[:value] || ""
      super args
      @app.sendmsg(message.merge({:action=>"register_event", :event=>"change"}))
      @app.sendmsg(message.merge({:action=>"register_event", :event=>"keyup"}))
    end

  end

  class Textarea < Widget
    attr_reader :val

    def val=(value)
      old = val
      @val = value
      self.refresh if old!=@val
    end

    def message
      super.merge({:value=>@val})
    end

    def change_lcl(mess)
      @val = mess["val"];
      super mess
    end

    # init the widget with the new val
    def keyup_lcl(mess)
      @val = mess["val"]
      super mess
    end

    protected

    def initialize(args)
      args[:type] = "Textarea" if !args[:type]
      @val = args[:value] || ""
      super args
      @app.sendmsg(message.merge({:action=>"register_event", :event=>"change"}))
      @app.sendmsg(message.merge({:action=>"register_event", :event=>"keyup"}))
    end

  end

  class Button < Widget

    attr_accessor :label

    def message
      super.merge({:label=>@label})
    end

    protected

    def initialize(args)
      args[:type] = "Button" if !args[:type]
      @label = args[:label]
      super args
    end

  end

  class Canvas < Widget

    attr_accessor :label

    def get_context2d()
      pname = Widgsock::Widget.new_name("proxy")
      @app.sendmsg(message.merge({:action=>"proxy_new", :proxy_name=>pname, :type=>"context2d"}))
      return ProxyJS.new(@app, @name, pname)
    end

    protected

    def initialize(args)
      args[:type] = "Canvas" if !args[:type]
      super args
    end

  end

  class Iframe < Widget

    attr_accessor :url

    def message
      super.merge({:url=>@url})
    end

    protected

    def initialize(args)
      args[:type] = "Iframe" if !args[:type]
      @url = args[:url]
      super args
    end
  end


  class Text < Widget

    attr_accessor :label

    def message
      super.merge({:label=>@label})
    end

    def reset(args)
      @label = args[:label] if args[:label]
      @app.sendmsg(message.merge({:action=>"refresh"}))
    end

    protected

    def initialize(args)
      args[:type] = "Text" if !args[:type]
      @label = args[:label]
      super args
    end
  end

  class Img < Widget

    attr_accessor :title
    attr_accessor :src
    attr_accessor :mime

    def message
      super.merge({:title=>@title, :mime=>@mime })
    end

    def reset(args)
      @title = args[:title] if args[:title]
      @img = ImageList.new(args[:file]) if args[:file]
      @mime = @img.mime_type
      @src = "data:"+@mime+";base64,"+ Base64.encode64(@img.to_blob).gsub(/\n/, "")
      @app.sendmsg(message.merge({:action=>"refresh"}))
    end

   def get_data(which)
    return @src if which=="src"
    ""
  end

  protected

  def initialize(args)
   args[:type] = "Img" if !args[:type]
   @title = @src = ""
   @title = args[:title] if args[:title]
   @img = ImageList.new(args[:file]) if args[:file]
   @mime = @img.mime_type
   @src = "data:"+@mime+";base64,"+ Base64.encode64(@img.to_blob).gsub(/\n/, "")
   super args
 end
end


class Tabs < Widget

  def message
   super.merge({:tabs=>@tabs})
 end

 def initialize(args)
   args[:type] = "Tabs" if !args[:type]
   Widget::check_args(args, {:tabs=>"Tabs"})
   @tabs = {}
   args[:tabs].each do |key, lib|
    @tabs[key] = {:name=>lib, :widgets=>[] }
  end
  super args
end

def get_ref_pos(name)
      # returns ref pos for the named widget
      @tabs.each do |key, tab|
        return @name+"-"+key if tab[:widgets].include? name 
      end
      return nil
    end

    def widget(args)
      Widget::check_args(args, {:tab=>"Tab"})
      widg = @area.widget(args)
      @tabs[args[:tab]][:widgets].push(widg.name)
      widg.surrounding_widget = self
      widg
    end

  end


end
