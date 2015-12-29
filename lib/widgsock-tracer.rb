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

  class Tracer

	LOG_ERR = 1
	LOG_WARNING = 2
	LOG_NOTICE = 3
	LOG_INFO = 4
	LOG_DEBUG = 5

	def initialize(options={})
	  @level = options[:level] || LOG_ERR
	  @file = options[:file]
	end

	def log(str, level)
	  puts str if @level>=level
	end
	  
  end

end