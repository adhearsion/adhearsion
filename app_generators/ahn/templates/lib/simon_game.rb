class SimonGame < Adhearsion::Plugin

  dialplan :simon_game do
    SimonGame.new(self).start
  end

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
    @call.speak @number
  end

  def collect_attempt
    @attempt = @call.input @number.length
  end

  def verify_attempt
    if attempt_correct?
      @call.speak 'good'
    else
      @call.speak %W[#{@number.length - 1} times wrong-try-again-smarty]
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
