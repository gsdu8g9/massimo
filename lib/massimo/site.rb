module Massimo
  class Site
    include Singleton
    
    # Default options. Overriden by values in config.yml or command-line opts.
    DEFAULT_OPTIONS = {
      :source      => ".",
      :output      => File.join(".", "public"),
      :server_port => "1984"
    }.freeze
    
    attr_accessor :options, :template
    
    # 
    def setup(options = {})
      options.symbolize_keys!
      
      # start with default options
      @options = DEFAULT_OPTIONS.dup
      
      # get source from options
      @options[:source] = options[:source] if options[:source]
      
      # get options from config.yml file if it exists
      config_path = self.source_dir("config.yml")
      config = YAML.load_file(config_path) if File.exist?(config_path)
      @options.merge!(config.symbolize_keys) if config.is_a?(Hash)
      
      # finally merge the given options.
      @options.merge!(options)
      
      # Create the basic template
      @template ||= Massimo::Template.new(self.helper_modules)
      
      self
    end
    
    # Processes all the Pages, Stylesheets, and Javascripts and outputs
    # them to the output dir.
    def process!
      pages(true).each(&:process!)
      stylesheets(true).each(&:process!)
      javascripts(true).each(&:process!)
    end
    
    # Get all the Pages in the pages dir.
    def pages(reload = false)
      return @pages if defined?(@pages) && !reload
      page_paths = self.find_files_in(:pages, Massimo::Filters.extensions)
      @pages = page_paths.collect { |path| Massimo::Page.new(path) }
    end
    
    # Get all the Stylesheets in the stylesheets dir.
    def stylesheets(reload = false)
      return @stylesheets if defined?(@stylesheets) && !reload
      stylesheet_paths = self.find_files_in(:stylesheets, [ :css, :sass, :less ])
      @stylesheets = stylesheet_paths.collect { |path| Massimo::Stylesheet.new(path) }
    end
    
    # Get all the Javascripts in the javascripts dir.
    def javascripts(reload = false)
      return @javascripts if defined?(@javascripts) && !reload
      javascript_paths = self.find_files_in(:javascripts, [ :js ])
      @javascripts = javascript_paths.collect { |path| Massimo::Javascript.new(path) }
    end
    
    # Finds a view by the given name
    def find_view(name, meta_data = {})
      view_path = Dir.glob(self.views_dir("#{name}.*")).first
      view_path && Massimo::View.new(view_path, meta_data)
    end
    
    # Finds a view then renders it with the given locals
    def render_view(name, locals = {})
      view = self.find_view(name)
      view && view.render(locals)
    end
    
    # The path to the source dir
    def source_dir(*path)
      File.join(@options[:source], *path)
    end
    
    # The path to the pages directory.
    def pages_dir(*path)
      self.source_dir("pages", *path)
    end
    
    # The path to the views directory.
    def views_dir(*path)
      self.source_dir("views", *path)
    end
    
    # The path to the stylesheets directory.
    def stylesheets_dir(*path)
      self.source_dir("stylesheets", *path)
    end
    
    # The path to the javascripts directory.
    def javascripts_dir(*path)
      self.source_dir("javascripts", *path)
    end
    
    # The path to the output dir
    def output_dir(*path)
      File.join(@options[:output], *path)
    end
    
    protected
    
      #
      def find_files_in(type, extensions)
        # the directory where these files will be found
        type_dir = self.send("#{type}_dir")
        
        # By default get the file list from the options
        files = @options[type]
        
        unless files && files.is_a?(Array)
          # If files aren't listed in the options, get them
          # from the given block
          files = Dir.glob(File.join(type_dir, "**", "*.{#{extensions.join(",")}}"))
          
          # normalize the files by removing the directory from the path
          files.collect! { |file| file.gsub("#{type_dir}/", "") }
          
          # reject the files in the skip_files option, which can
          # either be an array or a Proc.
          if skip_files = @options["skip_#{type}".to_sym]
            files.reject! do |file|
              case skip_files
              when Array
                skip_files.include?(file)
              else Proc
                skip_files.call(file)
              end
            end
          end
        end
        
        # Reject all files that begin with _ (like partials)
        files.reject! { |file| File.basename(file) =~ /^_/ }
        
        # now add the directory back to the path
        files.collect { |file| File.join(type_dir, file) }
      end
      
      # Find all the helper modules
      def helper_modules
        Dir.glob(source_dir("helpers", "*.rb")).collect do |file|
          require file
          File.basename(file).gsub(File.extname(file), "").classify.constantize
        end
      end
  end
end