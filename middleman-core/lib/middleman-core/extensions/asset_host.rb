module Middleman::Extensions
  module AssetHost
    class << self
      def registered(app)
        app.set :asset_host, false
      
        app.send :include, InstanceMethods
      end
      alias :included :registered
    end
  
    module InstanceMethods
      def asset_url(path, prefix="")
        original_output = super
        return original_output unless asset_host

        # valid_extensions = %w(.png .gif .jpg .jpeg .svg .svgz .js .css)

        asset_prefix = if asset_host.is_a?(Proc)
          asset_host.call(original_output)
        elsif asset_host.is_a?(String)
          asset_host
        end
        
        File.join(asset_prefix, original_output)
      end
    end
  end
end
