# line 1 "basic.rl"
require 'rubygems'

data  = "13j111ay37"
# cs = 0
# pe = cs + data.length 


# line 10 "basic.rb"
class << self
	attr_accessor :_foo_actions
	private :_foo_actions, :_foo_actions=
end
self._foo_actions = [
	0, 1, 0, 1, 1
]

class << self
	attr_accessor :_foo_key_offsets
	private :_foo_key_offsets, :_foo_key_offsets=
end
self._foo_key_offsets = [
	0, 0, 2, 5, 8, 9, 10, 12, 
	14
]

class << self
	attr_accessor :_foo_trans_keys
	private :_foo_trans_keys, :_foo_trans_keys=
end
self._foo_trans_keys = [
	48, 57, 106, 48, 57, 106, 48, 57, 
	97, 121, 48, 57, 48, 57, 48, 57, 
	0
]

class << self
	attr_accessor :_foo_single_lengths
	private :_foo_single_lengths, :_foo_single_lengths=
end
self._foo_single_lengths = [
	0, 0, 1, 1, 1, 1, 0, 0, 
	0
]

class << self
	attr_accessor :_foo_range_lengths
	private :_foo_range_lengths, :_foo_range_lengths=
end
self._foo_range_lengths = [
	0, 1, 1, 1, 0, 0, 1, 1, 
	1
]

class << self
	attr_accessor :_foo_index_offsets
	private :_foo_index_offsets, :_foo_index_offsets=
end
self._foo_index_offsets = [
	0, 0, 2, 5, 8, 10, 12, 14, 
	16
]

class << self
	attr_accessor :_foo_indicies
	private :_foo_indicies, :_foo_indicies=
end
self._foo_indicies = [
	0, 1, 3, 2, 1, 3, 2, 1, 
	4, 1, 5, 1, 6, 1, 7, 1, 
	7, 1, 0
]

class << self
	attr_accessor :_foo_trans_targs_wi
	private :_foo_trans_targs_wi, :_foo_trans_targs_wi=
end
self._foo_trans_targs_wi = [
	2, 0, 3, 4, 5, 6, 7, 8
]

class << self
	attr_accessor :_foo_trans_actions_wi
	private :_foo_trans_actions_wi, :_foo_trans_actions_wi=
end
self._foo_trans_actions_wi = [
	0, 0, 0, 1, 0, 0, 3, 0
]

class << self
	attr_accessor :foo_start
end
self.foo_start = 1;
class << self
	attr_accessor :foo_first_final
end
self.foo_first_final = 7;
class << self
	attr_accessor :foo_error
end
self.foo_error = 0;

class << self
	attr_accessor :foo_en_main
end
self.foo_en_main = 1;


# line 110 "basic.rb"
begin
	p ||= 0
	pe ||= data.length
	cs = foo_start
end

# line 117 "basic.rb"
begin
	_klen, _trans, _keys, _acts, _nacts = nil
	if p != pe
	if cs != 0
	while true
	_break_resume = false
	begin
	_break_again = false
	_keys = _foo_key_offsets[cs]
	_trans = _foo_index_offsets[cs]
	_klen = _foo_single_lengths[cs]
	_break_match = false
	
	begin
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + _klen - 1

	     loop do
	        break if _upper < _lower
	        _mid = _lower + ( (_upper - _lower) >> 1 )

	        if data[p] < _foo_trans_keys[_mid]
	           _upper = _mid - 1
	        elsif data[p] > _foo_trans_keys[_mid]
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
	  _klen = _foo_range_lengths[cs]
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + (_klen << 1) - 2
	     loop do
	        break if _upper < _lower
	        _mid = _lower + (((_upper-_lower) >> 1) & ~1)
	        if data[p] < _foo_trans_keys[_mid]
	          _upper = _mid - 2
	        elsif data[p] > _foo_trans_keys[_mid+1]
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
	_trans = _foo_indicies[_trans]
	cs = _foo_trans_targs_wi[_trans]
	break if _foo_trans_actions_wi[_trans] == 0
	_acts = _foo_trans_actions_wi[_trans]
	_nacts = _foo_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _foo_actions[_acts - 1]
when 0:
# line 11 "basic.rl"
		begin
 puts "FIRST" 		end
# line 11 "basic.rl"
when 1:
# line 11 "basic.rl"
		begin
puts 'SECOND'		end
# line 11 "basic.rl"
# line 195 "basic.rb"
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

# line 208 "basic.rb"
# line 17 "basic.rl"


