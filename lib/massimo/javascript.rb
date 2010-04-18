require 'sprockets'

module Massimo
  class Javascript < Massimo::Resource
    def render
      case source_path.extname.to_s
      when '.coffee'
        CoffeeScript.compile(content)
      else
        secretary = Sprockets::Secretary.new(
          :assert_root  => Massimo.config.output_path,
          :source_files => [ source_path.to_s ]
        )
        secretary.install_assets
        secretary.concatenation.to_s
      end
    end
    
    def extension
      @extension ||= '.js'
    end
  end
end