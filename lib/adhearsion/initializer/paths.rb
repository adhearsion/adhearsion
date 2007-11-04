module Adhearsion
  
  # Paths are a way for helpers to have Adhearsion manage dynamic
  # paths.
  module Paths
    
    # May need to build some kind of namespacing?
    
    @@path_managers = {}
    
    def self.manager_for(name, hash)
      globs = Array hash[:pattern] || hash[:patterns]
      directory = hash[:directory]
      name = name.to_s.underscore
      singular, plural = name.singularize, name.pluralize
      @@path_managers[singular] = globs
      #TODO: YAGNI.  Bad magic
      Kernel.module_eval do
        define_method "#{singular}_path" do |query|
          target = nil
          globs.each do |mgr|
            Dir.glob(mgr).each do |f|
              #return f if File.basename(f) == query
              target = File.expand_path(f) if File.basename(f) == query
            end
          end
          target
        end
        define_method "all_#{plural}" do
          globs.map { |g| Dir.glob g }.flatten
        end
      end
    end
    
    def self.manager_for?(name)
      @@path_managers[name.to_s.underscore.singularize]
    end
    
    def self.remove_manager_for(name)
      name = name.to_s
      singular, plural = name.singularize, name.pluralize
      Kernel.module_eval do
        undef_method "all_#{plural}", "#{singular}_path"
      end
    end

    # When creating with a combined managers, the first
    # writable directory is returned.
    def self.combine_managers(name, *managers)
      # TODO: Searches several managers in sequence.
      name = name.to_s.underscore
      singular, plural = name.singularize, name.pluralize
    end
  end
end
