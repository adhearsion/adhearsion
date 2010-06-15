namespace:create do

  task:war do
    # Hmm, this will is a tough one
  end

  task:rails_plugin do

  end

  task:migration do
    name = ARGV.shift
  end
end

namespace:delete do
  task:migration do
    # Take arg.underscore and remove it
  end
end
