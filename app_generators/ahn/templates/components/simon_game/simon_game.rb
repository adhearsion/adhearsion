methods_for :dialplan do
  def simon_game
    SimonGame.new(self).start
  end
end

class SimonGame

  def initialize(call)
    @call = call
    reset
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
    @number << random_number
  end

  def say_number
    update_number
    @call.say_digits @number
  end

  def collect_attempt
    @attempt = @call.input @number.length
  end

  def verify_attempt
    if attempt_correct? 
      @call.play 'good'
    else
      @call.play %W[#{@number.length-1} times wrong-try-again-smarty]
      reset
    end
  end

  def attempt_correct?
    @attempt == @number
  end
  
  def reset
    @attempt, @number = '', ''
  end
  
end
