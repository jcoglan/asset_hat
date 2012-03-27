require 'jsmin'
require File.join(File.dirname(__FILE__), 'js', 'vendors')

module AssetHat
  # Methods for minifying JavaScript.
  module JS
    # A list of supported minification
    # <a href=JS/Engines.html>engine</a> names.
    ENGINES = [:weak, :jsmin, :packr]

    # A list of supported
    # <a href=JS/Vendors.html>3rd-party JavaScript plugin/vendor</a> names.
    VENDORS = Vendors::VENDORS

    # Returns the expected path for the minified version of a JS asset:
    #
    #     AssetHat::JS.min_filepath('public/javascripts/bundles/application.js')
    #       # => 'public/javascripts/bundles/application.min.js'
    def self.min_filepath(filepath)
      AssetHat.min_filepath(filepath, 'js')
    end

    # Accepts a string of JS, and returns that JS minified. Options:
    #
    # [engine]  Default is <code>:jsmin</code>; see
    #           <a href=JS/Engines.html#method-c-jsmin>Engines.jsmin</a>.
    #           Allowed values are in ENGINES.
    def self.minify(input_string, options={})
      options.reverse_merge!(:engine => :jsmin)

      engine = options[:engine].to_sym
      unless ENGINES.include?(engine)
        raise %{
          Unknown JS minification engine '#{engine}'.
          Allowed: #{ENGINES.map{ |e| "'#{e}'" }.join(', ')}
        }.strip.gsub(/\s+/, ' ') and return
      end

      AssetHat::JS::Engines.send(engine, input_string, options)
    end

    # Swappable JavaScript minification engines.
    module Engines
      # Barebones JavaScript minification engine that:
      # - Skips leading/trailing whitespace for each line, excluding line
      #   breaks; and
      # - Removes one-line comments that had no actual code on that line.
      def self.weak(input_string, options = {})
        input   = StringIO.new(input_string)
        output  = StringIO.new

        input.each do |line|
          # Remove indentation and trailing whitespace
          line.strip!
          next if line.blank?

          # Skip single-line comments
          next if !(line =~ /^\/\//).nil?
          # TODO: Also skip single-line comments that began mid-line, but not
          #       inside a string or regex

          # TODO: Skip multi-line comments
          # - Should not strip from within a string or regex
          # - Should not strip comments that begin with `/*!` (e.g., licenses)

          output.write(line + "\n")
        end

        output.rewind
        output.read.strip
      end

      # JavaScript minification engine that simply uses the JSMin gem, a Ruby
      # port of Crockford's JSMin.
      #
      # Sources:
      # - http://github.com/rgrove/jsmin
      # - http://rubygems.org/gems/jsmin
      def self.jsmin(input_string, options = {})
        JSMin.minify(input_string + "\n").strip
      end
      
      # Dean Edwards' Packer engine, using --shrink-vars
      def self.packr(input_string, options = {})
        packer_options = {:shrink_vars => true}
        
        if sources = options[:sources]
          packer_options[:output_file] = options[:output_file]
          input_string = sources.map { |tuple| {:code => tuple[1], :source => tuple[0]} }
        end
        
        Packr.pack(input_string, packer_options)
      end
    end # module Engines

  end

end
