# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
module Adhearsion
	module VoIP
		module Asterisk
			class AMI
				module Machine
				# line 76 "lib/adhearsion/voip/asterisk/ami/machine.rl"

	
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
	11, 1, 12, 1, 13, 1, 21, 1, 
	23, 1, 24, 1, 25, 1, 26, 1, 
	27, 1, 28, 1, 29, 1, 30, 1, 
	31, 1, 32, 1, 33, 1, 34, 1, 
	42, 1, 43, 1, 44, 1, 45, 1, 
	46, 1, 47, 1, 48, 1, 49, 2, 
	0, 11, 2, 2, 3, 2, 21, 22, 
	2, 24, 2, 3, 24, 14, 35, 3, 
	24, 15, 36, 3, 24, 16, 37, 3, 
	24, 17, 38, 3, 24, 18, 39, 3, 
	24, 19, 40, 3, 24, 20, 41
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
	195, 196, 197, 199, 201, 203, 205, 207, 
	209, 211, 213, 215, 217, 219, 221, 223, 
	225, 227, 228, 229, 231, 233, 235, 237, 
	239, 241, 243, 245, 247, 249, 251, 252, 
	254, 256, 258, 260, 262, 264, 266, 268, 
	270, 272, 274, 276, 278, 280, 281, 283, 
	285, 289, 290, 291, 292, 293, 294, 295, 
	296, 299, 301, 303, 309, 313, 314, 315
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
	13, 10, 13, 10, 10, 10, 45, 10, 
	69, 10, 78, 10, 68, 10, 32, 10, 
	67, 10, 79, 10, 77, 10, 77, 10, 
	65, 10, 78, 10, 68, 10, 45, 10, 
	45, 10, 13, 10, 10, 10, 99, 10, 
	116, 10, 105, 10, 111, 10, 110, 10, 
	73, 10, 68, 10, 58, 10, 32, 10, 
	13, 10, 13, 13, 10, 13, 10, 13, 
	10, 114, 10, 105, 10, 118, 10, 105, 
	10, 108, 10, 101, 10, 103, 10, 101, 
	10, 58, 10, 32, 10, 13, 10, 13, 
	13, 10, 13, 10, 13, 13, 65, 69, 
	82, 13, 13, 13, 13, 13, 13, 13, 
	13, 33, 126, 33, 126, 33, 126, 13, 
	45, 65, 90, 97, 122, 10, 45, 65, 
	80, 13, 13, 13, 0
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
	1, 1, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 1, 1, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 1, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 1, 2, 2, 
	4, 1, 1, 1, 1, 1, 1, 1, 
	1, 0, 0, 2, 4, 1, 1, 1
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	1, 1, 1, 2, 0, 0, 0, 0
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
	280, 282, 284, 287, 290, 293, 296, 299, 
	302, 305, 308, 311, 314, 317, 320, 323, 
	326, 329, 331, 333, 336, 339, 342, 345, 
	348, 351, 354, 357, 360, 363, 366, 368, 
	371, 374, 377, 380, 383, 386, 389, 392, 
	395, 398, 401, 404, 407, 410, 412, 415, 
	418, 423, 425, 427, 429, 431, 433, 435, 
	437, 440, 442, 444, 449, 454, 456, 458
]

class << self
	attr_accessor :_ami_trans_targs_wi
	private :_ami_trans_targs_wi, :_ami_trans_targs_wi=
end
self._ami_trans_targs_wi = [
	3, 2, 3, 2, 4, 3, 2, 5, 
	144, 6, 144, 7, 144, 144, 144, 0, 
	3, 2, 3, 10, 2, 3, 11, 2, 
	3, 12, 2, 3, 13, 2, 3, 14, 
	2, 3, 15, 2, 3, 16, 2, 3, 
	17, 2, 3, 18, 2, 3, 19, 2, 
	3, 20, 2, 3, 21, 2, 3, 22, 
	2, 3, 23, 2, 3, 24, 2, 3, 
	25, 2, 3, 26, 2, 3, 27, 2, 
	3, 28, 2, 3, 29, 2, 3, 145, 
	2, 3, 31, 2, 3, 32, 2, 3, 
	33, 2, 3, 34, 2, 3, 35, 2, 
	3, 36, 2, 3, 37, 37, 2, 38, 
	39, 39, 2, 146, 3, 2, 38, 39, 
	39, 2, 3, 41, 2, 3, 42, 2, 
	3, 43, 2, 3, 44, 2, 3, 45, 
	2, 3, 46, 2, 3, 47, 2, 3, 
	48, 2, 3, 49, 2, 3, 50, 67, 
	75, 80, 2, 3, 51, 56, 2, 3, 
	52, 2, 3, 53, 2, 3, 54, 2, 
	55, 2, 147, 3, 2, 3, 57, 2, 
	3, 58, 2, 3, 59, 2, 3, 60, 
	2, 3, 61, 2, 3, 62, 2, 3, 
	63, 66, 2, 3, 64, 2, 65, 2, 
	148, 3, 2, 65, 2, 3, 68, 2, 
	3, 69, 2, 3, 70, 2, 3, 71, 
	2, 3, 72, 2, 3, 73, 2, 74, 
	2, 149, 3, 2, 3, 76, 2, 3, 
	77, 2, 3, 78, 2, 79, 2, 150, 
	3, 2, 3, 81, 2, 3, 82, 2, 
	3, 83, 2, 3, 84, 2, 3, 85, 
	2, 3, 86, 2, 87, 2, 151, 3, 
	2, 152, 0, 155, 0, 91, 92, 91, 
	91, 0, 91, 92, 91, 91, 0, 93, 
	0, 95, 94, 95, 94, 155, 95, 94, 
	156, 97, 156, 97, 156, 99, 97, 156, 
	100, 97, 156, 101, 97, 156, 102, 97, 
	156, 103, 97, 156, 104, 97, 156, 105, 
	97, 156, 106, 97, 156, 107, 97, 156, 
	108, 97, 156, 109, 97, 156, 110, 97, 
	156, 111, 97, 156, 112, 97, 156, 113, 
	97, 157, 97, 156, 156, 156, 116, 97, 
	156, 117, 97, 156, 118, 97, 156, 119, 
	97, 156, 120, 97, 156, 121, 97, 156, 
	122, 97, 156, 123, 97, 156, 124, 97, 
	158, 128, 125, 158, 128, 125, 127, 126, 
	156, 127, 126, 156, 128, 125, 156, 130, 
	97, 156, 131, 97, 156, 132, 97, 156, 
	133, 97, 156, 134, 97, 156, 135, 97, 
	156, 136, 97, 156, 137, 97, 156, 138, 
	97, 156, 139, 97, 159, 143, 140, 159, 
	143, 140, 142, 141, 156, 142, 141, 156, 
	143, 140, 8, 9, 30, 40, 1, 3, 
	2, 5, 144, 5, 144, 5, 144, 5, 
	144, 5, 144, 5, 144, 88, 153, 0, 
	154, 152, 154, 152, 89, 90, 90, 90, 
	0, 0, 98, 115, 129, 96, 114, 156, 
	127, 126, 142, 141, 0
]

class << self
	attr_accessor :_ami_trans_actions_wi
	private :_ami_trans_actions_wi, :_ami_trans_actions_wi=
end
self._ami_trans_actions_wi = [
	0, 0, 0, 0, 0, 0, 0, 27, 
	69, 0, 69, 0, 69, 55, 69, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 83, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 9, 9, 0, 11, 
	0, 0, 0, 99, 0, 0, 11, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 15, 17, 
	13, 13, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 95, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 13, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	103, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 107, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 91, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 87, 0, 
	0, 35, 0, 41, 0, 0, 3, 0, 
	0, 0, 0, 3, 0, 0, 0, 0, 
	0, 74, 5, 7, 0, 39, 7, 0, 
	47, 0, 47, 0, 47, 0, 0, 47, 
	0, 0, 47, 0, 0, 47, 0, 0, 
	47, 0, 0, 47, 0, 0, 47, 0, 
	0, 47, 0, 0, 47, 0, 0, 47, 
	0, 0, 47, 0, 0, 47, 0, 0, 
	47, 0, 0, 47, 0, 0, 47, 0, 
	0, 33, 0, 49, 53, 47, 0, 0, 
	47, 0, 0, 47, 0, 0, 47, 0, 
	0, 47, 0, 0, 47, 0, 0, 47, 
	0, 0, 47, 3, 0, 47, 0, 0, 
	80, 74, 5, 33, 7, 0, 7, 0, 
	45, 7, 0, 45, 7, 0, 47, 0, 
	0, 47, 0, 0, 47, 0, 0, 47, 
	0, 0, 47, 0, 0, 47, 0, 0, 
	47, 0, 0, 47, 0, 0, 47, 3, 
	0, 47, 0, 0, 80, 74, 5, 33, 
	7, 0, 7, 0, 43, 7, 0, 43, 
	7, 0, 25, 25, 25, 25, 25, 0, 
	0, 27, 63, 27, 61, 27, 65, 27, 
	67, 27, 59, 27, 57, 21, 19, 0, 
	0, 37, 0, 37, 0, 1, 1, 1, 
	0, 0, 23, 71, 71, 23, 0, 51, 
	7, 0, 7, 0, 0
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	77, 0, 0, 0, 0, 0, 0, 0, 
	29, 0, 0, 29, 29, 0, 0, 0
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	31, 0, 0, 0, 0, 0, 0, 0, 
	31, 0, 0, 31, 31, 0, 0, 0
]

class << self
	attr_accessor :ami_start
end
self.ami_start = 144;
class << self
	attr_accessor :ami_error
end
self.ami_error = 0;

class << self
	attr_accessor :ami_en_prompt
end
self.ami_en_prompt = 152;
class << self
	attr_accessor :ami_en_response_normal
end
self.ami_en_response_normal = 155;
class << self
	attr_accessor :ami_en_response_follows
end
self.ami_en_response_follows = 156;
class << self
	attr_accessor :ami_en_main
end
self.ami_en_main = 144;

# line 92 "lib/adhearsion/voip/asterisk/ami/machine.rl"

							end			
						end
					end

					private					
					def ragel_init
						
# line 413 "lib/adhearsion/voip/asterisk/ami/machine.rb"
begin
	 @__ragel_p ||= 0
	 @__ragel_pe ||=  @__ragel_data.length
	 @__ragel_cs = ami_start
	 @__ragel_tokstart = nil
	 @__ragel_tokend = nil
	 @__ragel_act = 0
end
# line 100 "lib/adhearsion/voip/asterisk/ami/machine.rl"
					end
					
					def ragel_exec
						
# line 427 "lib/adhearsion/voip/asterisk/ami/machine.rb"
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
			when 23:
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokstart =  @__ragel_p
		end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
# line 449 "lib/adhearsion/voip/asterisk/ami/machine.rb"
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
# line 13 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark("key") 			end
# line 13 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 1:
# line 14 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 set("key");				end
# line 14 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 2:
# line 15 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark("value") 		end
# line 15 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 3:
# line 16 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 set("value"); 		end
# line 16 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 4:
# line 21 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark("event") 		end
# line 21 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 5:
# line 22 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 set("event"); @current_packet = EventPacket.new(@__ragel_event) 		end
# line 22 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 6:
# line 25 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @current_packet = Packet.new; 		end
# line 25 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 7:
# line 26 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @current_packet = ErrorPacket.new; 		end
# line 26 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 8:
# line 33 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @current_packet = FollowsPacket.new; 		end
# line 33 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 9:
# line 40 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark("version"); 		end
# line 40 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 10:
# line 41 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 set("version"); @signal.signal			end
# line 41 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 11:
# line 51 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark_array("raw"); 		end
# line 51 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 12:
# line 54 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 mark_array("raw") 		end
# line 54 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 13:
# line 54 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 insert("raw") 		end
# line 54 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 14:
# line 65 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 152
		_break_again = true
		break
	end
 								end
# line 65 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 15:
# line 66 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 155
		_break_again = true
		break
	end
 			end
# line 66 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 16:
# line 67 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 155
		_break_again = true
		break
	end
 			end
# line 67 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 17:
# line 68 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 155
		_break_again = true
		break
	end
 			end
# line 68 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 18:
# line 69 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 155
		_break_again = true
		break
	end
 			end
# line 69 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 19:
# line 70 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 155
		_break_again = true
		break
	end
 			end
# line 70 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 20:
# line 71 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 	begin
		 @__ragel_cs = 156
		_break_again = true
		break
	end
 			end
# line 71 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 24:
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
		end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 25:
# line 41 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  	begin
		 @__ragel_cs = 144
		_break_again = true
		break
	end
  end
		end
# line 41 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 26:
# line 40 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 40 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 27:
# line 46 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  pair;  end
		end
# line 46 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 28:
# line 47 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  packet; 	begin
		 @__ragel_cs = 144
		_break_again = true
		break
	end
  end
		end
# line 47 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 29:
# line 58 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  pair;  end
		end
# line 58 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 30:
# line 59 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  pair;  end
		end
# line 59 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 31:
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  insert("raw")  end
		end
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 32:
# line 61 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  packet; 	begin
		 @__ragel_cs = 144
		_break_again = true
		break
	end
  end
		end
# line 61 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 33:
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1; begin  insert("raw")  end
		end
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 34:
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 begin  @__ragel_p = (( @__ragel_tokend))-1; end
 begin  insert("raw")  end
		end
# line 60 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 35:
# line 65 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 9;		end
# line 65 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 36:
# line 66 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 10;		end
# line 66 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 37:
# line 67 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 11;		end
# line 67 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 38:
# line 68 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 12;		end
# line 68 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 39:
# line 69 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 13;		end
# line 69 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 40:
# line 70 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 14;		end
# line 70 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 41:
# line 71 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 15;		end
# line 71 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 42:
# line 74 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p+1
 begin  @current_packet = ImmediatePacket.new; packet;  end
		end
# line 74 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 43:
# line 66 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 66 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 44:
# line 67 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 67 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 45:
# line 68 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 68 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 46:
# line 69 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 69 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 47:
# line 70 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 70 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 48:
# line 71 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokend =  @__ragel_p
 @__ragel_p =  @__ragel_p - 1;		end
# line 71 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 49:
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
# line 833 "lib/adhearsion/voip/asterisk/ami/machine.rb"
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
when 21
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_tokstart = nil;		end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
when 22
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
		begin
 @__ragel_act = 0
		end
# line 1 "lib/adhearsion/voip/asterisk/ami/machine.rl"
# line 856 "lib/adhearsion/voip/asterisk/ami/machine.rb"
		end # to state action switch
	end
	break if  @__ragel_cs == 0
	 @__ragel_p += 1
	break if  @__ragel_p ==  @__ragel_pe
	end
	end
	end
	end
# line 104 "lib/adhearsion/voip/asterisk/ami/machine.rl"
					end
				end
			end
		end
	end
end
