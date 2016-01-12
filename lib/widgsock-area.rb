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

  class Area
    attr_accessor :decorator, :w, :h, :app, :x, :y
    attr_reader :name

    def initialize(options={})
      raise ArgumentError, "area must have a name." if !options.has_key?(:name)

      @w = options[:w] || 1024
      @h = options[:h] || 728
      @x = options[:x] || 0
      @y = options[:y] || 0

      @app = options[:app] || nil
      @name = options[:name]
      @decorator = options[:decorator] || "default"

      # widgets linked to this area
      @widgets = {}

    end

    def widget(args)
      args[:area] = self
      args[:app] = @app
      w = Widgsock::Widget.factory(args)
      @widgets[w.name] = w
    end

    def refresh
      @app.refresh_area(@name)
    end

  end

  class Dialog < Area

    def initialize(options)
      raise ArgumentError, "dialog must be linked to an app." if !options.has_key?(:app)
      raise ArgumentError, "dialog must have a name." if !options.has_key?(:name)

      @app = options[:app]
      @name = "dialog_" + options[:name]
      @decorator = options[:decorator] || "default"

      # compute position of dialog
      @w = options[:w] || 1024
      @h = options[:h] || 728
      area = @app.get_area("main")
      @x = ( (area.w - area.x) - @w ) / 2
      @y = ( (area.h - area.y) - @h ) / 2

      @app.set_area(@name, self, "dialog")
      @widgets = {}
    end

    def widget(args)
      args[:app] = @app 
      super args
    end

    def close
      @app.unset_area(@name)
    end

  end


end