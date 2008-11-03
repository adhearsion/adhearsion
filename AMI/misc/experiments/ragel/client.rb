# line 1 "/Users/jicksta/Desktop/helloragel/spec/../client.rl"
def on(state)
	case state
	  when :handshake: puts "Hey there!"
	end
end

# line 14 "/Users/jicksta/Desktop/helloragel/spec/../client.rl"



# line 13 "/Users/jicksta/Desktop/helloragel/spec/../client.rb"
class << self
	attr_accessor :_server_actions
	private :_server_actions, :_server_actions=
end
self._server_actions = [
	0, 1, 0
]

class << self
	attr_accessor :_server_key_offsets
	private :_server_key_offsets, :_server_key_offsets=
end
self._server_key_offsets = [
	0, 0, 1, 2, 3, 4
]

class << self
	attr_accessor :_server_trans_keys
	private :_server_trans_keys, :_server_trans_keys=
end
self._server_trans_keys = [
	111, 104, 97, 105, 0
]

class << self
	attr_accessor :_server_single_lengths
	private :_server_single_lengths, :_server_single_lengths=
end
self._server_single_lengths = [
	0, 1, 1, 1, 1, 0
]

class << self
	attr_accessor :_server_range_lengths
	private :_server_range_lengths, :_server_range_lengths=
end
self._server_range_lengths = [
	0, 0, 0, 0, 0, 0
]

class << self
	attr_accessor :_server_index_offsets
	private :_server_index_offsets, :_server_index_offsets=
end
self._server_index_offsets = [
	0, 0, 2, 4, 6, 8
]

class << self
	attr_accessor :_server_trans_targs_wi
	private :_server_trans_targs_wi, :_server_trans_targs_wi=
end
self._server_trans_targs_wi = [
	2, 0, 3, 0, 4, 0, 5, 0, 
	0, 0
]

class << self
	attr_accessor :_server_trans_actions_wi
	private :_server_trans_actions_wi, :_server_trans_actions_wi=
end
self._server_trans_actions_wi = [
	0, 0, 0, 0, 0, 0, 1, 0, 
	0, 0
]

class << self
	attr_accessor :server_start
end
self.server_start = 1;
class << self
	attr_accessor :server_first_final
end
self.server_first_final = 5;
class << self
	attr_accessor :server_error
end
self.server_error = 0;

class << self
	attr_accessor :server_en_main
end
self.server_en_main = 1;

# line 17 "/Users/jicksta/Desktop/helloragel/spec/../client.rl"

# line 100 "/Users/jicksta/Desktop/helloragel/spec/../client.rb"
begin
	p ||= 0
	pe ||= data.length
	cs = server_start
end
# line 18 "/Users/jicksta/Desktop/helloragel/spec/../client.rl"

# line 108 "/Users/jicksta/Desktop/helloragel/spec/../client.rb"
begin
	_klen, _trans, _keys, _acts, _nacts = nil
	if p != pe
	if cs != 0
	while true
	_break_resume = false
	begin
	_break_again = false
	_keys = _server_key_offsets[cs]
	_trans = _server_index_offsets[cs]
	_klen = _server_single_lengths[cs]
	_break_match = false
	
	begin
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + _klen - 1

	     loop do
	        break if _upper < _lower
	        _mid = _lower + ( (_upper - _lower) >> 1 )

	        if data[p] < _server_trans_keys[_mid]
	           _upper = _mid - 1
	        elsif data[p] > _server_trans_keys[_mid]
	           _lower = _mid + 1
	        else
	           _trans += (_mid - _keys)
	           _break_match = true
	           break
	        end
	     end # loop
	     break if _break_match
	     _keys += _klen
	     _trans += _klen
	  end
	  _klen = _server_range_lengths[cs]
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + (_klen << 1) - 2
	     loop do
	        break if _upper < _lower
	        _mid = _lower + (((_upper-_lower) >> 1) & ~1)
	        if data[p] < _server_trans_keys[_mid]
	          _upper = _mid - 2
	        elsif data[p] > _server_trans_keys[_mid+1]
	          _lower = _mid + 2
	        else
	          _trans += ((_mid - _keys) >> 1)
	          _break_match = true
	          break
	        end
	     end # loop
	     break if _break_match
	     _trans += _klen
	  end
	end while false
	cs = _server_trans_targs_wi[_trans]
	break if _server_trans_actions_wi[_trans] == 0
	_acts = _server_trans_actions_wi[_trans]
	_nacts = _server_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _server_actions[_acts - 1]
when 0:
# line 10 "/Users/jicksta/Desktop/helloragel/spec/../client.rl"
		begin
 on:handshake 		end
# line 10 "/Users/jicksta/Desktop/helloragel/spec/../client.rl"
# line 180 "/Users/jicksta/Desktop/helloragel/spec/../client.rb"
		end # action switch
	end
	end while false
	break if _break_resume
	break if cs == 0
	p += 1
	break if p == pe
	end
	end
	end
	end
# line 19 "/Users/jicksta/Desktop/helloragel/spec/../client.rl"

