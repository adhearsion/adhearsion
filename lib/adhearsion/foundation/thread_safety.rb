# encoding: utf-8

require 'thread'

class Object
  def synchronize(&block)
    @mutex ||= Mutex.new
    @mutex.synchronize(&block)
  end
end

