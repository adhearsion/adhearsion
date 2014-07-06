# encoding: utf-8

module RSpec::Support::RubyFeatures
  def module_prepends_supported?
    false
  end
  module_function :module_prepends_supported?
end
