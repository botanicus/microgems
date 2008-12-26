require 'rbconfig'

unless $LOADED_FEATURES.find { |file| file.match(/rubygems/) }
  module Gem
    # Gem::LoadError: Could not find RubyGem sdfsdf (>= 0)
    class LoadError < ::LoadError
    end
  end

  class Microgems
    VERSION = "1.0.0"
    class << self
      # TODO: configuration
      # TODO: modularize, ~/.gems
      def root
        File.join(self.path, "gems")
      end

      # Microgem.gems("merb-core")
      # => ["/usr/lib/ruby/gems/1.8/gems/merb-core-0.9.8/lib"]
      def gems(name)
        Dir["#{self.root}/#{name}-*/lib"]
      end

      # Microgem.gem("merb-core", "0.9.8")
      # => "/usr/lib/ruby/gems/1.8/gems/merb-core-0.9.8/lib"
      def gem(name, version)
        if version.nil?
          self.gems(name).last
        else
          dir = File.join(self.root, "#{name}-#{version}", "lib")
          return self.gem(name, nil) unless File.directory?(dir)
        end
      end

      def loaded_gems
        @loaded_gems ||= Array.new
      end

      # stolen from minigems
      def path
        @default_path ||= if defined? RUBY_FRAMEWORK_VERSION then
          File.join File.dirname(RbConfig::CONFIG["sitedir"]), 'Gems', 
            RbConfig::CONFIG["ruby_version"]
        elsif defined?(RUBY_ENGINE) && File.directory?(
          File.join(RbConfig::CONFIG["libdir"], RUBY_ENGINE, 'gems', 
            RbConfig::CONFIG["ruby_version"])
          )
            File.join RbConfig::CONFIG["libdir"], RUBY_ENGINE, 'gems', 
              RbConfig::CONFIG["ruby_version"]
        else
          File.join RbConfig::CONFIG["libdir"], 'ruby', 'gems', 
            RbConfig::CONFIG["ruby_version"]
        end
      end

      def activate(name, version = nil)
        gem = if version.nil?
          self.gems(name).last
        else
          # TODO: > = ~ version
          # >= 0
          version.delete!("<>=~ ")
          self.gem(name, version)
        end
        self.loaded_gems.push(File.basename(File.dirname(gem)))
        $:.push(gem)
      end

      def deactivate(name, version = nil)
        if version.nil?
          $:.each do |path|
            if File.dirname(path).match(/^#{Regexp::quote(name)}-/)
              $:.delete!(path)
            end
          end
        else
          # TODO: > = ~ version
          # >= 0
          version.delete!("<>=~ ")
          libdir = self.gem(name, version)
          $:.delete(libdir) if $:.include?(libdir)
        end
      end
    end
  end

  module Kernel
    def gem(name, version = nil)
      Microgems.activate(name, version)
    end

    alias_method :__require__, :require
    def require(file)
      Microgems.activate(file) rescue nil
      __require__(file)
    rescue LoadError
      path_info
      raise $!
    end

    private
    def path_info
      if $DEBUG or $VERBOSE
        STDERR.puts "Load paths: #{$:.inspect}"
        STDERR.puts "Loaded gems: #{::Microgems.loaded_gems.inspect}"
      end
    end
  end
end
