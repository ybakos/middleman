module Middleman::Sitemap
  class Store
    attr_accessor :app
    
    def initialize(app)
      @app = app
      @pages = {}
    end
    
    # Check to see if we know about a specific path
    def exists?(path)
      @pages.has_key?(path.sub(/^\//, ""))
    end
    
    def set_context(path, opts={}, blk=nil)
      page(path) do
        template.options = opts
        template.blocks  = [blk]
      end
    end
    
    def ignore(path)
      page(path) { ignore }
      app.cache.remove(:ignored_paths)
    end
    
    def proxy(path, target)
      page(path) { proxy_to(target.sub(%r{^/}, "")) }
      app.cache.remove(:proxied_paths)
    end
    
    def page(path, &block)
      path = path.sub(/^\//, "").gsub("%20", " ")
      @pages[path] = ::Middleman::Sitemap::Page.new(self, path) unless @pages.has_key?(path)
      @pages[path].instance_exec(&block) if block_given?
      @pages[path]
    end
    
    def each(&block)
      @pages.each do |k, v|
        yield k, v
      end
    end
    
    def all_paths
      @pages.keys
    end
    
    def ignored?(path)
      ignored_paths.include?(path.sub(/^\//, ""))
    end
    
    def ignored_paths
      app.cache.fetch :ignored_paths do
        @pages.values.select(&:ignored?).map(&:path)
      end
    end
    
    def generic?(path)
      generic_paths.include?(path.sub(/^\//, ""))
    end
    
    def generic_paths
      app.cache.fetch :generic_paths do
        @pages.values.select(&:generic?).map(&:path)
      end
    end
    
    def proxied?(path)
      proxied_paths.include?(path.sub(/^\//, ""))
    end
    
    def proxied_paths
      app.cache.fetch :proxied_paths do
        @pages.values.select(&:proxy?).map(&:path)
      end
    end
    
    def remove_file(file)
      path = file_to_path(file)
      return false unless path
      
      path = path.sub(/^\//, "")
      @pages.delete(path) if @pages.has_key?(path)
    end
    
    def file_to_path(file)
      file = File.expand_path(file, @app.root)
      
      prefix = @app.source_dir.sub(/\/$/, "") + "/"
      return false unless file.include?(prefix)
      
      path = file.sub(prefix, "")
      path = extensionless_path(path)
      
      path
    end
    
    def touch_file(file)
      return false if file == @app.source_dir || File.directory?(file)
      
      path = file_to_path(file)
      return false unless path
      
      return false if @app.ignored_sitemap_matchers.any? do |name, callback|
        callback.call(file, path)
      end
          
      # Add generic path
      p = page(path)
      p.source_file = File.expand_path(file, @app.root)
      p.touch
      
      true
    end
    
    def sitemap_should_ignore?(file, path)
      @app.sitemap_ignore.every(&:call)
    end
    
  protected
    def extensionless_path(file)
      app.cache.fetch(:extensionless_path, file) do
        path = file.dup

        end_of_the_line = false
        while !end_of_the_line
          if !::Tilt[path].nil?
            path = path.sub(File.extname(path), "")
          else
            end_of_the_line = true
          end
        end

        path
      end
    end
  end
end
