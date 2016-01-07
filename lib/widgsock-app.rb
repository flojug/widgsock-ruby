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

require "websocket-eventmachine-server"
require "json"
require "base64"
require "rmagick"

$LOAD_PATH << File.dirname(__FILE__)

require "widgsock-widget"
require "widgsock-tracer"
require "widgsock-area"

include Magick


module Widgsock

	@@host = "localhost"
	@@port = 8080
	@@blocks = {}
	@@files = {}

	def self.register(name="app", &block)
		@@blocks[name] = block
	end

	def self.get_block(name)
		raise ArgumentError, "#{name} app unknown" if !@@blocks.has_key?(name)
		@@blocks[name]
	end

	class App
		attr_reader :default_area, :temp_dir

		def initialize(ws, name="app", temp_dir="/tmp/")
			@ws = ws
			@frames = {}
			@tracer = Widgsock::Tracer.new(:level=>Tracer::LOG_ERR)
			@areas = {}
			@default_area = ""
			@temp_dir = temp_dir
		end

		def options(args)
			if args[:name]
				@name = args[:name]
			elsif args[:tracer]
				@tracer = args[:tracer]
			end
		end

		def set_area(name, area, aclass="")
			raise ArgumentError, "this area '#{name}' exists." if @areas.has_key?(name)
			if @areas.empty?
				@default_area = name
			end
			@areas[name] = area
			area.app = self
			mess = { :action=>"register_area", :w=>area.w, :h=>area.h, :name=>name, :decorator=>area.decorator, :x=>area.x, :y=>area.y }
			mess[:aclass] = aclass if !aclass.empty? 
			self.sendmsg(mess)
		end

		def unset_area(name)
			raise ArgumentError, "main area cannot be deleted." if name=="main"
			@areas.delete(name) 
			Widgsock::Widget::unset_widget(name)
			mess = { :action=>"unregister_area", :name=>name }
			self.sendmsg(mess)
		end

		def refresh_area(name)
			if @areas.has_key?(name)
				mess = { :action=>"refresh_area", :name=>name }
				self.sendmsg(mess)
			end
		end

		def get_area(name=nil)
			if name && @areas.has_key?(name)
				@areas[name] 
			else
				@areas[default_area]
			end	
		end

		def set_default_area(name)
			if @areas.has_key? name
				@default_area = name
			else
				raise ArgumentError, "area #{name} does not exist."
			end
		end

		def log(msg, level)
			@tracer.log msg, level if @tracer
		end

		def run
			raise ArgumentError, "widgsock app name required." if @name.empty? 
			Widgsock::get_block(@name).call self
		end

		def widget(args)
			args[:app] = self
			area = @areas[args[:area]] || @areas[self.default_area]
			return area.widget(args)
		end

		def sendmsg(msg)
			raise StandardError, "unconnected app." if @ws==nil
			msg[:app] = @name
			mess = JSON.generate(msg)
			@tracer.log "<==== : #{msg}", Tracer::LOG_DEBUG
			@ws.send(mess)
		end

	end

	def self.run
		# launch Websocket Event Machine, 
		#  open websocket => calls app block
		EM.run do

			WebSocket::EventMachine::Server.start(:host => @@host, :port => @@port) do |ws|

				app = Widgsock::App.new(ws)

				ws.onopen do
					app.log "client connected", Tracer::LOG_DEBUG
					puts @@files
				end

				ws.onmessage do |msg, type|
					
					begin
						app.log "====> : #{msg}", Tracer::LOG_DEBUG
						app.log "type: #{type}", Tracer::LOG_DEBUG

						mess = JSON.parse msg

						if mess["action"]=="run"
							app.options(:name=>mess["name"])
							area = Widgsock::Area.new(:name=>"main", :w=>mess["w"].to_i, :h=>mess["h"].to_i)
							app.set_area("main", area)
							app.run
						end

						if mess["action"]=="apply_event"
							w = Widgsock::Widget::get_widget(mess["name"])
							event = mess["event"]
							w.send event+"_srv", mess if w.respond_to? event+"_srv"
						end

						# retrieve file and send a file event to the widget
						if mess["action"]=="send_files"
							lclname = app.temp_dir + mess["filename"]
							File.open(lclname, 'w') { |f| 
								f.write(Base64.decode64(mess["data"])) 
							}
							mess["local_name"] = lclname
							w = Widgsock::Widget::get_widget(mess["name"])
							w.send "file_srv", mess 
							# erase file ?
						end

						# retrieve big data associated with widgets (like images)
						if mess["action"]=="get_data"
							w = Widgsock::Widget::get_widget(mess["name"])
							data = w.get_data(mess["which"])
							app.sendmsg({:action=>"data", :data=>data, :name=>mess["name"], :which=>mess["which"]})
						end

					rescue => exp
						mess = "Fatal Error : #{exp.class}: #{exp.message}"
						app.sendmsg({:action=>"error", :message=>mess})
						app.log mess, Tracer::LOG_ERR
						ws.close
					end

				end

				ws.onclose do
					app.log "client disconnected", Tracer::LOG_DEBUG
				end

			end

		end
	end

end


