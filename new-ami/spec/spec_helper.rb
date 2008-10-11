require 'ostruct'
require 'pp'
require 'stringio'
require 'rubygems'
require 'active_support'
require 'test/spec'
require 'flexmock/test_unit'
require File.dirname(__FILE__) + "/../generate_code"

# Regenerate the Ruby source code
ragel_to_ruby

alias the_following_code lambda

class Object
  def metaclass
    class << self; self; end
  end
  
  def meta_eval(&block)
    metaclass.instance_eval(&block)
  end
  
  def meta_def(name, &block)
    meta_eval { define_method(name, &block) }
  end
end

FIXTURES = YAML.load_file File.dirname(__FILE__) + "/ami_fixtures.yml"

def fixture(path, overrides={})
  path_segments = path.split '/'
  selected_event = path_segments.inject(FIXTURES.clone) do |hash, segment|
    raise ArgumentError, path + " not found!" unless hash
    hash[segment.to_sym]
  end
  
  # Downcase all keys in the event and the overrides
  selected_event = selected_event.inject({}) do |downcased_hash,(key,value)|
    downcased_hash[key.to_s.downcase] = value
    downcased_hash
  end
  overrides = overrides.inject({}) do |downcased_hash,(key,value)|
    downcased_hash[key.to_s.downcase] = value
    downcased_hash
  end
  
  # Replace variables in the selected_event with any overrides, ignoring case of the key
  keys_with_variables = selected_event.select { |(key, value)| value.kind_of?(Symbol) || value.kind_of?(Hash) }
  
  keys_with_variables.each do |original_key, variable_type|
    # Does an override an exist in the supplied list?
    if overriden_pair = overrides.find { |(key, value)| key == original_key }
      # We have an override! Let's replace the template value in the event with the overriden value
      selected_event[original_key] = overriden_pair.last
    else
      # Based on the type, let's generate a placeholder.
      selected_event[original_key] = case variable_type
        when :string
          rand(100000).to_s
        when Hash
          if variable_type.has_key? "one_of"
            # Choose a random possibility
            possibilities = variable_type['one_of']
            possibilities[rand(possibilities.size)]
          else
            raise "Unrecognized Hash fixture property! ##{variable_type.keys.to_sentence}"
          end
        else
          raise "Unrecognized fixture variable type #{variable_type}!"
      end
    end
    
  end
  returning hash_to_stanza(selected_event) do |event|
    selected_event.each_pair do |key, value|
      event.meta_def(key) { value }
    end
  end
end

def hash_to_stanza(hash)
  ordered_hash = hash.to_a
  starter = hash.find { |(key, value)| key =~ /^(Response|Action)$/i }
  ordered_hash.unshift ordered_hash.delete(starter) if starter
  ordered_hash.inject(String.new) do |stanza,(key, value)|
    stanza + "#{key}: #{value}\r\n"
  end + "\r\n"
end