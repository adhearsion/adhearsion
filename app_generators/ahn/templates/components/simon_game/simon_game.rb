class SimonGame
  add_call_context :as => :call_context

  attr_accessor :number, :attempt
  def initialize
    initialize_number
    initialize_attempt
  end
  
  def start
    loop do
      say_number
      collect_attempt
      verify_attempt
    end
  end

  def random_number
    rand(10).to_s
  end

  def update_number
    initialize_attempt
    @number << random_number
  end

  def say_number
    update_number
    call_context.say_digits number
  end

  def collect_attempt
    @attempt = call_context.input(number.size)
  end

  def verify_attempt
    if attempt_correct? 
      call_context.play 'good'
    else
      call_context.play %W(#{number.size - 1} times wrong-try-again-smarty)
      reset
    end
  end

  def attempt_correct?
    attempt == number
  end
  
  def initialize_attempt
    @attempt ||= ''
  end
  
  def initialize_number
    @number ||= ''
  end
  
  def reset
    @attempt, @number = '', ''
  end
  
end
