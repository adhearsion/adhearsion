desc "Show configuration values"

namespace :adhearsion do

  namespace :config do

    desc "Show configuration values in STDOUT"
    task :show, :name do |t, args|
      name = args.name.nil? ? :platform : args.name.to_sym
      puts Adhearsion.config.description name, :show_values => true
    end

    desc "Show configuration description options in STDOUT"
    task :desc, :name do |t, args|
      name = args.name.nil? ? :platform : args.name.to_sym
      puts Adhearsion.config.description name, :show_values => false
    end
  end
end
