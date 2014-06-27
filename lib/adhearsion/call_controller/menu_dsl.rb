# encoding: utf-8

%w(
  calculated_match
  calculated_match_collection
  match_calculator
  fixnum_match_calculator
  range_match_calculator
  string_match_calculator
  array_match_calculator
  menu_builder
  menu
).each { |r| require "adhearsion/call_controller/menu_dsl/#{r}" }

module Adhearsion
  class CallController
    # @private
    module MenuDSL
    end
  end
end
