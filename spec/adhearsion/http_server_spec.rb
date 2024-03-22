# encoding: utf-8

require "spec_helper"

module Adhearsion
  RSpec.describe HTTPServer do
    it "starts the HTTP server" do
      config = Adhearsion.config.core.http
      config.enable = true
      config.rackup = "spec/support/config.ru"

      HTTPServer.start
    end
  end
end
