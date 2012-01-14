class SimonGame < Adhearsion::CallController
  def run
    reset
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
    speak @number
  end

  def collect_attempt
    @attempt = input @number.length
  end

  def verify_attempt
    if attempt_correct?
      speak 'good'
    else
      speak "#{@number.length - 1} times wrong, try again smarty"
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
