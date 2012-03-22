# encoding: utf-8

class SimonGame < Adhearsion::CallController
  def run
    answer
    reset
    loop do
      update_number
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

  def collect_attempt
    result = ask @number, :limit => @number.length
    @attempt = result.response
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
