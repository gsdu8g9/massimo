module Massimo
  autoload :Config,     'massimo/config'
  autoload :Helpers,    'massimo/helpers'
  autoload :Javascript, 'massimo/javascript'
  autoload :Page,       'massimo/page'
  autoload :Resource,   'massimo/resource'
  autoload :Server,     'massimo/server'
  autoload :Site,       'massimo/site'
  autoload :Stylesheet, 'massimo/stylesheet'
  autoload :View,       'massimo/view'
  autoload :Watcher,    'massimo/watcher'
  
  VERSION = File.read File.expand_path('../../VERSION', __FILE__)
  
  class << self
    def site
      @site ||= Site.new
    end
  
    def site=(site)
      @site = site
    end
    
    def config
      site.config
    end
  end
end
