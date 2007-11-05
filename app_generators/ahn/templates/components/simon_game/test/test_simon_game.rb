require File.dirname(__FILE__) + "/test_helper"

class TestSimonGame < Test::Unit::TestCase
  attr_reader :game
  def setup
    @game = SimonGame.new
    @game.call_context = mock_call_context
  end
  
  def test_game_executes_say_digits_when_asked_to_say_number
    flexmock(game).should_receive(:random_number).and_return("2")
    mock_call_context.should_receive(:say_digits).once.with('2')
    @game.say_number
  end
  
  
  # Didn't get very far on this
  def xtest_can_play_one_round_and_receive_the_players_score
    flexmock(game).should_receive(:random_number).and_return("2")
    assert_equal(3, 'x')
  end
  
    private
    def mock_call_context
      @mock_call_context ||= flexmock("Mock Call Context")
    end
    
    def stub_random_number
      
    end
end