require 'rbconfig'

class Microgem
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

    # Microgem.gem("merb-core
    def gem(name, version)
      if version 
        File.join(self.root, "#{name}-#{version}", "lib")
      else
        self.gems.last
      end
    end

    def loaded_gems
      @loaded_gems ||= {}
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
      if version.nil?
        $:.push(self.gem(self.gems(name).last))
      else
        # TODO: > = ~ version
        version.delete("<>=~")
        $:.push(self.gem(name, version))
      end
    end

    def deactivate(name, version = nil)
      if version.nil?
        $:.each do |path|
          if File.dirname(path).match(/^#{Regexp::quote(name)}-/)
            $:.delete(path)
          end
        end
      else
        # TODO: > = ~ version
        version.delete("<>=~")
        libdir = self.gem(name, version)
        $:.delete(libdir) if $:.include?(libdir)
      end
    end
  end
end

module Kernel
  def gem(name, version = nil)
    Microgem.activate(name, version)
  end

  alias_method :__require__, :require
  def require(file)
    __require__(file)
  rescue LoadError
    gem file
    __require__(file)
  end
end
