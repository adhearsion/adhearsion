# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
module Adhearsion
	module VoIP
		module Asterisk
			class AMI
				module Machine
				# line 67 "lib/adhearsion/voip/asterisk/ami/machine.rl"

	
					class << self
						def extended(base)
							# Rename the Ragel variables. Not strictly necessary if
							# we were to make accessors for them.
							base.instance_eval do
								
# line 17 "lib/adhearsion/voip/asterisk/ami/machine.rb"
class << self
	attr_accessor :_ami_actions
	private :_ami_actions, :_ami_actions=
end
self._ami_actions = [
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 6, 1, 
	7, 1, 8, 1, 9, 1, 10, 1, 
	11, 1, 12, 1, 20, 1, 22, 1, 
	24, 1, 25, 1, 26, 1, 27, 1, 
	29, 1, 30, 1, 31, 1, 39, 1, 
	40, 1, 41, 1, 42, 1, 43, 1, 
	44, 1, 45, 1, 46, 2, 0, 11, 
	2, 2, 3, 2, 20, 21, 2, 23, 
	28, 3, 23, 13, 32, 3, 23, 14, 
	33, 3, 23, 15, 34, 3, 23, 16, 
	35, 3, 23, 17, 36, 3, 23, 18, 
	37, 3, 23, 19, 38
]

class << self
	attr_accessor :_ami_key_offsets
	private :_ami_key_offsets, :_ami_key_offsets=
end
self._ami_key_offsets = [
	0, 0, 1, 2, 4, 5, 6, 7, 
	8, 10, 12, 14, 16, 18, 20, 22, 
	24, 26, 28, 30, 32, 34, 36, 38, 
	40, 42, 44, 46, 48, 50, 52, 54, 
	56, 58, 60, 62, 64, 69, 74, 76, 
	81, 83, 85, 87, 89, 91, 93, 95, 
	97, 99, 104, 107, 109, 111, 113, 114, 
	116, 118, 120, 122, 124, 126, 128, 131, 
	133, 134, 136, 137, 139, 141, 143, 145, 
	147, 149, 150, 152, 154, 156, 158, 159, 
	161, 163, 165, 167, 169, 171, 173, 174, 
	176, 177, 178, 184, 190, 191, 192, 193, 
	195, 196, 197, 199, 200, 201, 202, 203, 
	204, 205, 206, 207, 208, 209, 210, 211, 
	212, 213, 214, 215, 216, 217, 218, 220, 
	227, 234, 236, 237, 238, 240, 244, 245, 
	246, 247, 248, 249, 250, 251, 254, 256, 
	258, 264, 270
]

class << self
	attr_accessor :_ami_trans_keys
	private :_ami_trans_keys, :_ami_trans_keys=
end
self._ami_trans_keys = [
	13, 13, 10, 13, 13, 10, 13, 10, 
	10, 13, 13, 115, 13, 116, 13, 101, 
	13, 114, 13, 105, 13, 115, 13, 107, 
	13, 32, 13, 67, 13, 97, 13, 108, 
	13, 108, 13, 32, 13, 77, 13, 97, 
	13, 110, 13, 97, 13, 103, 13, 101, 
	13, 114, 13, 47, 13, 118, 13, 101, 
	13, 110, 13, 116, 13, 58, 13, 32, 
	13, 65, 90, 97, 122, 13, 65, 90, 
	97, 122, 10, 13, 13, 65, 90, 97, 
	122, 13, 101, 13, 115, 13, 112, 13, 
	111, 13, 110, 13, 115, 13, 101, 13, 
	58, 13, 32, 13, 69, 70, 80, 83, 
	13, 114, 118, 13, 114, 13, 111, 13, 
	114, 13, 10, 13, 13, 101, 13, 110, 
	13, 116, 13, 115, 13, 32, 13, 79, 
	13, 102, 110, 13, 102, 13, 10, 13, 
	13, 13, 111, 13, 108, 13, 108, 13, 
	111, 13, 119, 13, 115, 13, 10, 13, 
	13, 111, 13, 110, 13, 103, 13, 10, 
	13, 13, 117, 13, 99, 13, 99, 13, 
	101, 13, 115, 13, 115, 13, 10, 13, 
	10, 10, 45, 58, 65, 90, 97, 122, 
	45, 58, 65, 90, 97, 122, 32, 13, 
	13, 10, 13, 13, 13, 10, 13, 45, 
	45, 69, 78, 68, 32, 67, 79, 77, 
	77, 65, 78, 68, 45, 45, 13, 10, 
	13, 10, 10, 13, 13, 45, 58, 65, 
	90, 97, 122, 13, 45, 58, 65, 90, 
	97, 122, 13, 32, 13, 13, 10, 13, 
	13, 65, 69, 82, 13, 13, 13, 13, 
	13, 13, 13, 13, 33, 126, 33, 126, 
	33, 126, 13, 45, 65, 90, 97, 122, 
	13, 45, 65, 90, 97, 122, 45, 0
]

class << self
	attr_accessor :_ami_single_lengths
	private :_ami_single_lengths, :_ami_single_lengths=
end
self._ami_single_lengths = [
	0, 1, 1, 2, 1, 1, 1, 1, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 1, 1, 2, 1, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 5, 3, 2, 2, 2, 1, 2, 
	2, 2, 2, 2, 2, 2, 3, 2, 
	1, 2, 1, 2, 2, 2, 2, 2, 
	2, 1, 2, 2, 2, 2, 1, 2, 
	2, 2, 2, 2, 2, 2, 1, 2, 
	1, 1, 2, 2, 1, 1, 1, 2, 
	1, 1, 2, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 2, 3, 
	3, 2, 1, 1, 2, 4, 1, 1, 
	1, 1, 1, 1, 1, 1, 0, 0, 
	2, 2, 1
]

class << self
	attr_accessor :_ami_range_lengths
	private :_ami_range_lengths, :_ami_range_lengths=
end
self._ami_range_lengths = [
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 2, 2, 0, 2, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 2, 2, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 2, 
	2, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 1, 1, 1, 
	2, 2, 0
]

class << self
	attr_accessor :_ami_index_offsets
	private :_ami_index_offsets, :_ami_index_offsets=
end
self._ami_index_offsets = [
	0, 0, 2, 4, 7, 9, 11, 13, 
	15, 18, 21, 24, 27, 30, 33, 36, 
	39, 42, 45, 48, 51, 54, 57, 60, 
	63, 66, 69, 72, 75, 78, 81, 84, 
	87, 90, 93, 96, 99, 103, 107, 110, 
	114, 117, 120, 123, 126, 129, 132, 135, 
	138, 141, 147, 151, 154, 157, 160, 162, 
	165, 168, 171, 174, 177, 180, 183, 187, 
	190, 192, 195, 197, 200, 203, 206, 209, 
	212, 215, 217, 220, 223, 226, 229, 231, 
	234, 237, 240, 243, 246, 249, 252, 254, 
	257, 259, 261, 266, 271, 273, 275, 277, 
	280, 282, 284, 287, 289, 291, 293, 295, 
	297, 299, 301, 303, 305, 307, 309, 311, 
	313, 315, 317, 319, 321, 323, 325, 328, 
	334, 340, 343, 345, 347, 350, 355, 357, 
	359, 361, 363, 365, 367, 369, 372, 374, 
	376, 381, 386
]

class << self
	attr_accessor :_ami_trans_targs_wi
	private :_ami_trans_targs_wi, :_ami_trans_targs_wi=
end
self._ami_trans_targs_wi = [
	3, 2, 3, 2, 4, 3, 2, 5, 
	125, 6, 125, 7, 125, 125, 125, 0, 
	3, 2, 3, 10, 2, 3, 11, 2, 
	3, 12, 2, 3, 13, 2, 3, 14, 
	2, 3, 15, 2, 3, 16, 2, 3, 
	17, 2, 3, 18, 2, 3, 19, 2, 
	3, 20, 2, 3, 21, 2, 3, 22, 
	2, 3, 23, 2, 3, 24, 2, 3, 
	25, 2, 3, 26, 2, 3, 27, 2, 
	3, 28, 2, 3, 29, 2, 3, 126, 
	2, 3, 31, 2, 3, 32, 2, 3, 
	33, 2, 3, 34, 2, 3, 35, 2, 
	3, 36, 2, 3, 37, 37, 2, 38, 
	39, 39, 2, 127, 3, 2, 38, 39, 
	39, 2, 3, 41, 2, 3, 42, 2, 
	3, 43, 2, 3, 44, 2, 3, 45, 
	2, 3, 46, 2, 3, 47, 2, 3, 
	48, 2, 3, 49, 2, 3, 50, 67, 
	75, 80, 2, 3, 51, 56, 2, 3, 
	52, 2, 3, 53, 2, 3, 54, 2, 
	55, 2, 128, 3, 2, 3, 57, 2, 
	3, 58, 2, 3, 59, 2, 3, 60, 
	2, 3, 61, 2, 3, 62, 2, 3, 
	63, 66, 2, 3, 64, 2, 65, 2, 
	129, 3, 2, 65, 2, 3, 68, 2, 
	3, 69, 2, 3, 70, 2, 3, 71, 
	2, 3, 72, 2, 3, 73, 2, 74, 
	2, 130, 3, 2, 3, 76, 2, 3, 
	77, 2, 3, 78, 2, 79, 2, 131, 
	3, 2, 3, 81, 2, 3, 82, 2, 
	3, 83, 2, 3, 84, 2, 3, 85, 
	2, 3, 86, 2, 87, 2, 132, 3, 
	2, 133, 0, 136, 0, 91, 92, 91, 
	91, 0, 91, 92, 91, 91, 0, 93, 
	0, 95, 94, 95, 94, 136, 95, 94, 
	98, 97, 98, 97, 99, 98, 97, 100, 
	0, 101, 137, 102, 137, 103, 137, 104, 
	137, 105, 137, 106, 137, 107, 137, 108, 
	137, 109, 137, 110, 137, 111, 137, 112, 
	137, 113, 137, 114, 137, 115, 137, 116, 
	137, 117, 137, 137, 137, 0, 98, 97, 
	98, 120, 121, 120, 120, 97, 98, 120, 
	121, 120, 120, 97, 98, 122, 97, 124, 
	123, 124, 123, 138, 124, 123, 8, 9, 
	30, 40, 1, 3, 2, 5, 125, 5, 
	125, 5, 125, 5, 125, 5, 125, 5, 
	125, 88, 134, 0, 135, 133, 135, 133, 
	89, 90, 90, 90, 0, 118, 119, 119, 
	119, 96, 100, 137, 0
]

class << self
	attr_accessor :_ami_trans_actions_wi
	private :_ami_trans_actions_wi, :_ami_trans_actions_wi=
end
self._ami_trans_actions_wi = [
	0, 0, 0, 0, 0, 0, 0, 25, 
	59, 0, 59, 0, 59, 45, 59, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 73, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 9, 9, 0, 11, 
	0, 0, 0, 89, 0, 0, 11, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 15, 17, 
	13, 13, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 85, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 13, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	93, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 97, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 81, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 77, 0, 
	0, 31, 0, 37, 0, 0, 3, 0, 
	0, 0, 0, 3, 0, 0, 0, 0, 
	0, 64, 5, 7, 0, 35, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 25, 
	0, 0, 43, 0, 43, 0, 43, 0, 
	43, 0, 43, 0, 43, 0, 43, 0, 
	43, 0, 43, 0, 43, 0, 43, 0, 
	43, 0, 43, 0, 43, 0, 43, 0, 
	43, 0, 43, 39, 43, 0, 0, 0, 
	0, 0, 3, 0, 0, 0, 0, 0, 
	3, 0, 0, 0, 0, 0, 0, 64, 
	5, 7, 0, 70, 7, 0, 23, 23, 
	23, 23, 23, 0, 0, 25, 53, 25, 
	51, 25, 55, 25, 57, 25, 49, 25, 
	47, 21, 19, 0, 0, 33, 0, 33, 
	0, 1, 1, 1, 0, 23, 61, 61, 
	61, 23, 25, 41, 0
]

class << self
	attr_accessor :_ami_to_state_actions
	private :_ami_to_state_actions, :_ami_to_state_actions=
end
self._ami_to_state_actions = [
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 67, 0, 0, 
	0, 0, 0, 0, 0, 27, 0, 0, 
	27, 67, 0
]

class << self
	attr_accessor :_ami_from_state_actions
	private :_ami_from_state_actions, :_ami_from_state_actions=
end
self._ami_from_state_actions = [
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 29, 0, 0, 
	0, 0, 0, 0, 0, 29, 0, 0, 
	29, 29, 0
]

class << self
	attr_accessor :ami_start
end
self.ami_start = 125;
class << self
	attr_accessor :ami_error
end
self.ami_error = 0;

class << self
	attr_accessor :ami_en_prompt
end
self.ami_en_prompt = 133;
class << self
	attr_accessor :ami_en_response_normal
end
self.ami_en_response_normal = 136;
class << self
	attr_accessor :ami_en_response_follows
end
self.ami_en_response_follows = 137;
class << self
	attr_accessor :ami_en_main
end
self.ami_en_main = 125;

# line 83 "lib/adhearsion/voip/asterisk/ami/machine.rl"

							end			
						end
					end

					private					
					def ragel_init
						
# line 376 "lib/adhearsion/voip/asterisk/ami/machine.rb"
begin
	 @__ragel_p ||= 0
	 @__ragel_pe ||=  @__ragel_data.length
	 @__ragel_cs = ami_start
	 @__ragel_tokstart = nil
	 @__ragel_tokend = nil
	 @__ragel_act = 0
end
# line 91 "lib/adhearsion/voip/asterisk/ami/machine.rl"
					end
					
					def ragel_exec
						
# line 390 "lib/adhearsion/voip/asterisk/ami/machine.rb"
begin
	_klen, _trans, _keys, _acts, _nacts = nil
	if  @__ragel_p !=  @__ragel_pe
	if  @__ragel_cs != 0
	while true
	_break_resume = false
	begin
	_break_again = false
	_acts = _ami_from_state_actions[ @__ragel_cs]
	_nacts = _ami_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _ami_actions[_acts - 1]
			when 22:
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokstart =  @__ragel_p
		end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
# line 412 "lib/adhearsion/voip/asterisk/ami/machine.rb"
		end # from state action switch
	end
	break if _break_again
	_keys = _ami_key_offsets[ @__ragel_cs]
	_trans = _ami_index_offsets[ @__ragel_cs]
	_klen = _ami_single_lengths[ @__ragel_cs]
	_break_match = false
	
	begin
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + _klen - 1

	     loop do
	        break if _upper < _lower
	        _mid = _lower + ( (_upper - _lower) >> 1 )

	        if  @__ragel_data[ @__ragel_p] < _ami_trans_keys[_mid]
	           _upper = _mid - 1
	        elsif  @__ragel_data[ @__ragel_p] > _ami_trans_keys[_mid]
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
	  _klen = _ami_range_lengths[ @__ragel_cs]
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + (_klen << 1) - 2
	     loop do
	        break if _upper < _lower
	        _mid = _lower + (((_upper-_lower) >> 1) & ~1)
	        if  @__ragel_data[ @__ragel_p] < _ami_trans_keys[_mid]
	          _upper = _mid - 2
	        elsif  @__ragel_data[ @__ragel_p] > _ami_trans_keys[_mid+1]
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
	 @__ragel_cs = _ami_trans_targs_wi[_trans]
	break if _ami_trans_actions_wi[_trans] == 0
	_acts = _ami_trans_actions_wi[_trans]
	_nacts = _ami_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _ami_actions[_acts - 1]
when 0:
# line 11 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark("key") 			end
# line 11 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 1:
# line 12 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 set("key");				end
# line 12 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 2:
# line 13 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark("value") 		end
# line 13 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 3:
# line 14 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 set("value"); 		end
# line 14 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 4:
# line 17 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark("event") 		end
# line 17 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 5:
# line 18 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 set("event"); @current_packet = EventPacket.new(@__ragel_event) 		end
# line 18 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 6:
# line 21 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @current_packet = Packet.new; 		end
# line 21 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 7:
# line 22 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @current_packet = Packet.new(true); 		end
# line 22 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 8:
# line 29 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @current_packet = FollowsPacket.new; 		end
# line 29 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 9:
# line 36 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark("version"); 		end
# line 36 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 10:
# line 37 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 set("version"); @signal.signal			end
# line 37 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 11:
# line 47 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark_array("raw") 		end
# line 47 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 12:
# line 47 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 insert("raw") 		end
# line 47 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 13:
# line 56 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 133
		_break_again = true
		break
	end
 								end
# line 56 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 14:
# line 57 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 136
		_break_again = true
		break
	end
 			end
# line 57 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 15:
# line 58 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 136
		_break_again = true
		break
	end
 			end
# line 58 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 16:
# line 59 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 136
		_break_again = true
		break
	end
 			end
# line 59 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 17:
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 136
		_break_again = true
		break
	end
 			end
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 18:
# line 61 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 136
		_break_again = true
		break
	end
 			end
# line 61 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 19:
# line 62 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 137
		_break_again = true
		break
	end
 			end
# line 62 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 23:
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
		end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 24:
# line 37 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  	begin
		 @__ragel_cs = 125
		_break_again = true
		break
	end
  end
		end
# line 37 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 25:
# line 36 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 36 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 26:
# line 42 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  pair;  end
		end
# line 42 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 27:
# line 43 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  packet; 	begin
		 @__ragel_cs = 125
		_break_again = true
		break
	end
  end
		end
# line 43 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 28:
# line 51 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 5;		end
# line 51 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 29:
# line 52 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  packet; 	begin
		 @__ragel_cs = 125
		_break_again = true
		break
	end
  end
		end
# line 52 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 30:
# line 51 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1; begin  pair;  end
		end
# line 51 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 31:
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
	case  @__ragel_act
	when 0:
	begin	begin
		 @__ragel_cs = 0
		_break_again = true
		break
	end
end
	when 5:
	begin begin  @__ragel_p = (( @__ragel_tokend))-1; end
 pair; end
end 
			end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 32:
# line 56 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 7;		end
# line 56 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 33:
# line 57 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 8;		end
# line 57 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 34:
# line 58 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 9;		end
# line 58 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 35:
# line 59 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 10;		end
# line 59 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 36:
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 11;		end
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 37:
# line 61 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 12;		end
# line 61 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 38:
# line 62 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 13;		end
# line 62 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 39:
# line 65 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  @current_packet = ImmediatePacket.new; packet;  end
		end
# line 65 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 40:
# line 57 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 57 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 41:
# line 58 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 58 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 42:
# line 59 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 59 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 43:
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 44:
# line 61 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 61 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 45:
# line 62 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 62 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 46:
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
	case  @__ragel_act
	when 0:
	begin	begin
		 @__ragel_cs = 0
		_break_again = true
		break
	end
end
end 
			end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
# line 785 "lib/adhearsion/voip/asterisk/ami/machine.rb"
		end # action switch
	end
	end while false
	break if _break_resume
	_acts = _ami_to_state_actions[ @__ragel_cs]
	_nacts = _ami_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _ami_actions[_acts - 1]
when 20
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokstart = nil;		end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 21
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 0
		end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
# line 808 "lib/adhearsion/voip/asterisk/ami/machine.rb"
		end # to state action switch
	end
	break if  @__ragel_cs == 0
	 @__ragel_p += 1
	break if  @__ragel_p ==  @__ragel_pe
	end
	end
	end
	end
# line 95 "lib/adhearsion/voip/asterisk/ami/machine.rl"
					end
				end
			end
		end
	end
end
