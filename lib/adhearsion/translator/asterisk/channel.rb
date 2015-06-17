# encoding: utf-8

require 'delegate'

module Adhearsion
  module Translator
    class Asterisk
      class Channel < SimpleDelegator
        NORMALIZATION_REGEXP = /^(?<prefix>Bridge\/)*(?<name>[^<>]*)(?<suffix><.*>)*$/.freeze

        def self.new(other)
          other.is_a?(self) ? other : super
        end

        def name
          matchdata[:name]
        end

        def prefix
          matchdata[:prefix]
        end

        def suffix
          matchdata[:suffix]
        end

        def bridged?
          @bridged ||= (prefix || suffix)
        end

        def to_s
          __getobj__
        end

        private

        def matchdata
          @matchdata ||= __getobj__.match(NORMALIZATION_REGEXP)
        end
      end
    end
  end
end
