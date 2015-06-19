# encoding: utf-8

require 'adhearsion/error'

module Adhearsion
  module Translator
    OptionError = Class.new Adhearsion::Error
  end
end

require 'adhearsion/translator/asterisk'
