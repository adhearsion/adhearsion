class SimonGame
  
  class << self
    
    def start
      returning new do |game|
        loop do
          game.say_number
          game.collect_attempt
          game.verify_attempt
        end
      end
    end
    
  end

  attr_accessor :number, :attempt
  def initialize
    initialize_number
    initialize_attempt
  end

  def random_number
    rand(10).to_s
  end

  def update_number
    initialize_attempt
    number << random_number
  end

  def say_number
    update_number
    exec "saydigits", number
  end

  def collect_attempt
    self.attempt = input(number.size)
  end

  def verify_attempt
    if attempt_correct? 
      play 'good'
    else
      play %W(#{number.size - 1} times wrong-try-again-smarty)
      initialize_attempt
      initialize_number
    end
  end

  def attempt_correct?
    attempt == number
  end
  
  def initialize_attempt
    @attempt = ''
  end
  
  def initialize_number
    @number = ''
  end

  [:exec, :play, :input, :hangup].each do |method_to_delegate_to_context|
    class_eval(<<-EVAL, __FILE__, __LINE__)
      def #{method_to_delegate_to_context}(*args, &block)
        Thread.current[:container].#{method_to_delegate_to_context}(*args, &block)
      end
    EVAL
  end
end
