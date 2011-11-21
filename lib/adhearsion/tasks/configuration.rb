desc "Show configuration values"

namespace :adhearsion do

  namespace :config do

    desc "Show configuration values in STDOUT"
    task :show, :name do |t, args|
      name = args.name.nil? ? :all : args.name.to_sym
      puts Adhearsion.config.show_configuration name
    end

    desc "Show configuration description options in STDOUT"
    task :desc, :name do |t, args|
      name = args.name.nil? ? :all : args.name.to_sym
      puts name
      puts Adhearsion.config.show_configuration name, :description => true
    end
  end
end
