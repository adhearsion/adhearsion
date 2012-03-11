class SimonGame < Adhearsion::CallController
  def run
    answer
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
    say @number
  end

  def collect_attempt
    @attempt = input @number.length
  end

  def verify_attempt
    if attempt_correct?
      say 'good'
    else
      say "#{@number.length - 1} times wrong, try again smarty"
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
