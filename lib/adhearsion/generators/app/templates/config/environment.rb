# encoding: utf-8

require 'bundler'
Bundler.setup

require 'adhearsion'

Bundler.require(:default, Adhearsion.environment)

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../app/')))
