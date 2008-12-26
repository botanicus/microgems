#!/usr/bin/env ruby

require 'rbconfig'
require 'fileutils'

include RbConfig
sitedir = File.join(CONFIG["sitedir"], CONFIG["ruby_version"])

begin
  FileUtils.cp "microgems.rb", sitedir
rescue Errno::EACCES
  abort "You as user #{ENV["USER"]} haven't access to #{sitedir}. Try to use sudo ruby install.rb"
end

puts "Microgems were successfully installed into #{sitedir}."
puts "Do not forget to add export RUBYOPT=rmicrogems to /etc/profile."
