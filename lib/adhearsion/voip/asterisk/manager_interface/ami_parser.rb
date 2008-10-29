# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
require File.join(File.dirname(__FILE__), 'packets.rb')

module Adhearsion
  module VoIP
    module Asterisk
      module Manager
        class AbstractAsteriskManagerInterfaceStreamParser

          BUFFER_SIZE = 8.kilobytes unless defined? BUFFER_SIZE

          # line 49 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
##

          attr_accessor(:ami_version)
          def initialize
    
            @data = ""
            @current_pointer = 0
            @ragel_stack = []
            
            
# line 24 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
class << self
	attr_accessor :_ami_protocol_parser_actions
	private :_ami_protocol_parser_actions, :_ami_protocol_parser_actions=
end
self._ami_protocol_parser_actions = [
	0, 1, 0, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 11, 1, 15, 1, 16, 1, 
	17, 1, 18, 1, 26, 1, 28, 1, 
	29, 1, 33, 1, 34, 1, 35, 1, 
	36, 1, 37, 1, 38, 1, 39, 1, 
	42, 1, 43, 1, 44, 1, 45, 1, 
	46, 1, 49, 1, 50, 1, 51, 1, 
	52, 1, 53, 2, 1, 22, 2, 2, 
	24, 2, 5, 15, 2, 6, 7, 2, 
	7, 8, 2, 10, 41, 2, 12, 32, 
	2, 13, 11, 2, 17, 18, 2, 19, 
	40, 2, 20, 40, 2, 21, 40, 2, 
	26, 27, 2, 29, 47, 3, 14, 23, 
	31, 3, 29, 25, 48, 4, 14, 23, 
	31, 12, 4, 29, 14, 23, 30
]

class << self
	attr_accessor :_ami_protocol_parser_key_offsets
	private :_ami_protocol_parser_key_offsets, :_ami_protocol_parser_key_offsets=
end
self._ami_protocol_parser_key_offsets = [
	0, 0, 1, 2, 3, 4, 5, 6, 
	7, 8, 9, 10, 11, 12, 13, 14, 
	15, 16, 17, 18, 19, 20, 22, 25, 
	27, 30, 31, 34, 37, 40, 43, 44, 
	46, 49, 50, 53, 54, 55, 56, 57, 
	58, 59, 60, 61, 62, 63, 64, 65, 
	66, 67, 68, 69, 70, 71, 72, 73, 
	75, 78, 80, 83, 84, 87, 90, 92, 
	94, 96, 97, 99, 100, 102, 104, 106, 
	108, 110, 112, 114, 116, 117, 126, 135, 
	137, 139, 141, 143, 144, 145, 147, 149, 
	151, 153, 155, 157, 159, 160, 162, 163, 
	165, 166, 167, 169, 171, 173, 175, 177, 
	179, 181, 182, 183, 184, 185, 187, 189, 
	191, 192, 193, 195, 197, 199, 201, 203, 
	205, 206, 207, 222, 223, 238, 253, 268, 
	285, 286, 288, 303, 318, 335, 351, 367, 
	384, 385, 387, 389, 391, 393, 395, 397, 
	399, 401, 403, 405, 407, 409, 411, 413, 
	415, 417, 418, 419, 421, 437, 453, 469, 
	486, 487, 489, 505, 521, 537, 554, 555, 
	557, 574, 591, 608, 625, 642, 659, 676, 
	693, 710, 727, 744, 761, 778, 795, 811, 
	826, 841, 858, 859, 861, 876, 891, 908, 
	924, 940, 957, 973, 990, 1006, 1022, 1039, 
	1056, 1072, 1088, 1105, 1121, 1122, 1123, 1126, 
	1127, 1133, 1134, 1135, 1137, 1139, 1139, 1154, 
	1156, 1172, 1188
]

class << self
	attr_accessor :_ami_protocol_parser_trans_keys
	private :_ami_protocol_parser_trans_keys, :_ami_protocol_parser_trans_keys=
end
self._ami_protocol_parser_trans_keys = [
	116, 101, 114, 105, 115, 107, 32, 67, 
	97, 108, 108, 32, 77, 97, 110, 97, 
	103, 101, 114, 47, 48, 57, 46, 48, 
	57, 48, 57, 13, 48, 57, 10, 13, 
	48, 57, 46, 48, 57, 10, 13, 58, 
	10, 13, 58, 13, 10, 13, 10, 13, 
	58, 13, 10, 13, 58, 116, 101, 114, 
	105, 115, 107, 32, 67, 97, 108, 108, 
	32, 77, 97, 110, 97, 103, 101, 114, 
	47, 48, 57, 46, 48, 57, 48, 57, 
	13, 48, 57, 10, 13, 48, 57, 46, 
	48, 57, 69, 101, 78, 110, 84, 116, 
	58, 13, 32, 13, 10, 13, 13, 32, 
	83, 115, 80, 112, 79, 111, 78, 110, 
	83, 115, 69, 101, 58, 32, 69, 70, 
	80, 83, 101, 102, 112, 115, 32, 69, 
	70, 80, 83, 101, 102, 112, 115, 82, 
	114, 82, 114, 79, 111, 82, 114, 13, 
	10, 77, 109, 69, 101, 83, 115, 83, 
	115, 65, 97, 71, 103, 69, 101, 58, 
	13, 32, 13, 10, 13, 13, 10, 13, 
	32, 79, 111, 76, 108, 76, 108, 79, 
	111, 87, 119, 83, 115, 13, 10, 13, 
	10, 79, 111, 78, 110, 71, 103, 13, 
	10, 85, 117, 67, 99, 67, 99, 69, 
	101, 83, 115, 83, 115, 13, 10, 13, 
	32, 47, 48, 57, 58, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 10, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 58, 33, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 10, 13, 
	13, 32, 47, 48, 57, 58, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 10, 13, 13, 45, 13, 45, 13, 
	69, 13, 78, 13, 68, 13, 32, 13, 
	67, 13, 79, 13, 77, 13, 77, 13, 
	65, 13, 78, 13, 68, 13, 45, 13, 
	45, 13, 10, 10, 13, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 10, 
	13, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 10, 13, 13, 45, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	69, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 78, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 68, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 67, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 79, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 77, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 77, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	65, 32, 47, 48, 57, 59, 64, 66, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 78, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 68, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 45, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 45, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 10, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 58, 33, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 32, 58, 33, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 65, 115, 10, 13, 58, 13, 13, 
	65, 69, 82, 101, 114, 10, 115, 86, 
	118, 69, 101, 13, 32, 47, 48, 57, 
	58, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 45, 13, 45, 32, 47, 
	48, 57, 58, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 45, 32, 47, 
	48, 57, 58, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 32, 47, 48, 57, 
	58, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 0
]

class << self
	attr_accessor :_ami_protocol_parser_single_lengths
	private :_ami_protocol_parser_single_lengths, :_ami_protocol_parser_single_lengths=
end
self._ami_protocol_parser_single_lengths = [
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 0, 1, 0, 
	1, 1, 1, 1, 3, 3, 1, 2, 
	3, 1, 3, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 0, 
	1, 0, 1, 1, 1, 1, 2, 2, 
	2, 1, 2, 1, 2, 2, 2, 2, 
	2, 2, 2, 2, 1, 9, 9, 2, 
	2, 2, 2, 1, 1, 2, 2, 2, 
	2, 2, 2, 2, 1, 2, 1, 2, 
	1, 1, 2, 2, 2, 2, 2, 2, 
	2, 1, 1, 1, 1, 2, 2, 2, 
	1, 1, 2, 2, 2, 2, 2, 2, 
	1, 1, 1, 1, 1, 1, 1, 3, 
	1, 2, 1, 1, 3, 2, 2, 3, 
	1, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 1, 1, 2, 2, 2, 2, 3, 
	1, 2, 2, 2, 2, 3, 1, 2, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 2, 1, 
	1, 3, 1, 2, 1, 1, 3, 2, 
	2, 3, 2, 3, 2, 2, 3, 3, 
	2, 2, 3, 2, 1, 1, 3, 1, 
	6, 1, 1, 2, 2, 0, 1, 2, 
	2, 2, 0
]

class << self
	attr_accessor :_ami_protocol_parser_range_lengths
	private :_ami_protocol_parser_range_lengths, :_ami_protocol_parser_range_lengths=
end
self._ami_protocol_parser_range_lengths = [
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 1, 1, 1, 
	1, 0, 1, 1, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 1, 
	1, 1, 1, 0, 1, 1, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 7, 7, 7, 7, 
	0, 0, 7, 7, 7, 7, 7, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 7, 7, 7, 
	0, 0, 7, 7, 7, 7, 0, 0, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 0, 0, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	7, 7, 7
]

class << self
	attr_accessor :_ami_protocol_parser_index_offsets
	private :_ami_protocol_parser_index_offsets, :_ami_protocol_parser_index_offsets=
end
self._ami_protocol_parser_index_offsets = [
	0, 0, 2, 4, 6, 8, 10, 12, 
	14, 16, 18, 20, 22, 24, 26, 28, 
	30, 32, 34, 36, 38, 40, 42, 45, 
	47, 50, 52, 55, 58, 62, 66, 68, 
	71, 75, 77, 81, 83, 85, 87, 89, 
	91, 93, 95, 97, 99, 101, 103, 105, 
	107, 109, 111, 113, 115, 117, 119, 121, 
	123, 126, 128, 131, 133, 136, 139, 142, 
	145, 148, 150, 153, 155, 158, 161, 164, 
	167, 170, 173, 176, 179, 181, 191, 201, 
	204, 207, 210, 213, 215, 217, 220, 223, 
	226, 229, 232, 235, 238, 240, 243, 245, 
	248, 250, 252, 255, 258, 261, 264, 267, 
	270, 273, 275, 277, 279, 281, 284, 287, 
	290, 292, 294, 297, 300, 303, 306, 309, 
	312, 314, 316, 325, 327, 336, 345, 354, 
	365, 367, 370, 379, 388, 399, 409, 419, 
	430, 432, 435, 438, 441, 444, 447, 450, 
	453, 456, 459, 462, 465, 468, 471, 474, 
	477, 480, 482, 484, 487, 497, 507, 517, 
	528, 530, 533, 543, 553, 563, 574, 576, 
	579, 590, 601, 612, 623, 634, 645, 656, 
	667, 678, 689, 700, 711, 722, 733, 743, 
	752, 761, 772, 774, 777, 786, 795, 806, 
	816, 826, 837, 847, 858, 868, 878, 889, 
	900, 910, 920, 931, 941, 943, 945, 949, 
	951, 958, 960, 962, 965, 968, 969, 978, 
	981, 991, 1001
]

class << self
	attr_accessor :_ami_protocol_parser_trans_targs
	private :_ami_protocol_parser_trans_targs, :_ami_protocol_parser_trans_targs=
end
self._ami_protocol_parser_trans_targs = [
	2, 204, 3, 204, 4, 204, 5, 204, 
	6, 204, 7, 204, 8, 204, 9, 204, 
	10, 204, 11, 204, 12, 204, 13, 204, 
	14, 204, 15, 204, 16, 204, 17, 204, 
	18, 204, 19, 204, 20, 204, 21, 204, 
	22, 204, 23, 27, 204, 24, 204, 25, 
	26, 204, 204, 204, 25, 26, 204, 23, 
	27, 204, 207, 32, 30, 29, 207, 32, 
	30, 29, 31, 30, 206, 31, 30, 206, 
	32, 30, 29, 31, 30, 206, 32, 30, 
	29, 36, 208, 37, 208, 38, 208, 39, 
	208, 40, 208, 41, 208, 42, 208, 43, 
	208, 44, 208, 45, 208, 46, 208, 47, 
	208, 48, 208, 49, 208, 50, 208, 51, 
	208, 52, 208, 53, 208, 54, 208, 55, 
	208, 56, 208, 57, 61, 208, 58, 208, 
	59, 60, 208, 208, 208, 59, 60, 208, 
	57, 61, 208, 63, 63, 208, 64, 64, 
	208, 65, 65, 208, 66, 208, 68, 69, 
	67, 68, 67, 208, 68, 67, 68, 69, 
	67, 71, 71, 208, 72, 72, 208, 73, 
	73, 208, 74, 74, 208, 75, 75, 208, 
	76, 76, 208, 77, 208, 78, 79, 99, 
	109, 114, 79, 99, 109, 114, 208, 78, 
	79, 99, 109, 114, 79, 99, 109, 114, 
	208, 80, 80, 208, 81, 81, 208, 82, 
	82, 208, 83, 83, 208, 84, 208, 85, 
	208, 86, 86, 208, 87, 87, 208, 88, 
	88, 208, 89, 89, 208, 90, 90, 208, 
	91, 91, 208, 92, 92, 208, 93, 208, 
	95, 98, 94, 95, 94, 96, 95, 94, 
	97, 208, 208, 208, 95, 98, 94, 100, 
	100, 208, 101, 101, 208, 102, 102, 208, 
	103, 103, 208, 104, 104, 208, 105, 105, 
	208, 106, 208, 107, 208, 108, 208, 208, 
	208, 110, 110, 208, 111, 111, 208, 112, 
	112, 208, 113, 208, 208, 208, 115, 115, 
	208, 116, 116, 208, 117, 117, 208, 118, 
	118, 208, 119, 119, 208, 120, 120, 208, 
	121, 208, 208, 208, 123, 124, 131, 124, 
	131, 124, 131, 124, 0, 213, 0, 127, 
	125, 126, 125, 126, 125, 126, 125, 0, 
	127, 125, 126, 125, 126, 125, 126, 125, 
	0, 127, 125, 126, 125, 126, 125, 126, 
	125, 0, 129, 132, 135, 133, 134, 133, 
	134, 133, 134, 133, 128, 129, 128, 130, 
	129, 128, 123, 124, 131, 124, 131, 124, 
	131, 124, 0, 127, 125, 126, 125, 126, 
	125, 126, 125, 0, 129, 132, 135, 133, 
	134, 133, 134, 133, 134, 133, 128, 129, 
	135, 133, 134, 133, 134, 133, 134, 133, 
	128, 129, 135, 133, 134, 133, 134, 133, 
	134, 133, 128, 129, 132, 135, 133, 134, 
	133, 134, 133, 134, 133, 128, 137, 136, 
	138, 137, 136, 137, 139, 136, 137, 140, 
	136, 137, 141, 136, 137, 142, 136, 137, 
	143, 136, 137, 144, 136, 137, 145, 136, 
	137, 146, 136, 137, 147, 136, 137, 148, 
	136, 137, 149, 136, 137, 150, 136, 137, 
	151, 136, 137, 152, 136, 137, 153, 136, 
	154, 214, 214, 214, 215, 137, 136, 137, 
	159, 157, 158, 157, 158, 157, 158, 157, 
	136, 137, 159, 157, 158, 157, 158, 157, 
	158, 157, 136, 137, 159, 157, 158, 157, 
	158, 157, 158, 157, 136, 161, 199, 202, 
	200, 201, 200, 201, 200, 201, 200, 160, 
	161, 160, 216, 161, 160, 137, 165, 163, 
	164, 163, 164, 163, 164, 163, 136, 137, 
	165, 163, 164, 163, 164, 163, 164, 163, 
	136, 137, 165, 163, 164, 163, 164, 163, 
	164, 163, 136, 167, 195, 198, 196, 197, 
	196, 197, 196, 197, 196, 166, 167, 166, 
	217, 167, 166, 137, 169, 165, 163, 164, 
	163, 164, 163, 164, 163, 136, 137, 165, 
	170, 163, 164, 163, 164, 163, 164, 163, 
	136, 137, 165, 171, 163, 164, 163, 164, 
	163, 164, 163, 136, 137, 165, 172, 163, 
	164, 163, 164, 163, 164, 163, 136, 137, 
	173, 165, 163, 164, 163, 164, 163, 164, 
	163, 136, 137, 165, 174, 163, 164, 163, 
	164, 163, 164, 163, 136, 137, 165, 175, 
	163, 164, 163, 164, 163, 164, 163, 136, 
	137, 165, 176, 163, 164, 163, 164, 163, 
	164, 163, 136, 137, 165, 177, 163, 164, 
	163, 164, 163, 164, 163, 136, 137, 165, 
	178, 163, 164, 163, 164, 163, 164, 163, 
	136, 137, 165, 179, 163, 164, 163, 164, 
	163, 164, 163, 136, 137, 165, 180, 163, 
	164, 163, 164, 163, 164, 163, 136, 137, 
	181, 165, 163, 164, 163, 164, 163, 164, 
	163, 136, 137, 182, 165, 163, 164, 163, 
	164, 163, 164, 163, 136, 154, 185, 183, 
	184, 183, 184, 183, 184, 183, 214, 185, 
	183, 184, 183, 184, 183, 184, 183, 214, 
	185, 183, 184, 183, 184, 183, 184, 183, 
	214, 187, 190, 193, 191, 192, 191, 192, 
	191, 192, 191, 186, 187, 186, 218, 187, 
	186, 185, 183, 184, 183, 184, 183, 184, 
	183, 214, 185, 183, 184, 183, 184, 183, 
	184, 183, 214, 187, 190, 193, 191, 192, 
	191, 192, 191, 192, 191, 186, 187, 193, 
	191, 192, 191, 192, 191, 192, 191, 186, 
	187, 193, 191, 192, 191, 192, 191, 192, 
	191, 186, 187, 190, 193, 191, 192, 191, 
	192, 191, 192, 191, 186, 137, 165, 163, 
	164, 163, 164, 163, 164, 163, 136, 167, 
	195, 198, 196, 197, 196, 197, 196, 197, 
	196, 166, 167, 198, 196, 197, 196, 197, 
	196, 197, 196, 166, 167, 198, 196, 197, 
	196, 197, 196, 197, 196, 166, 167, 195, 
	198, 196, 197, 196, 197, 196, 197, 196, 
	166, 161, 199, 202, 200, 201, 200, 201, 
	200, 201, 200, 160, 161, 202, 200, 201, 
	200, 201, 200, 201, 200, 160, 161, 202, 
	200, 201, 200, 201, 200, 201, 200, 160, 
	161, 199, 202, 200, 201, 200, 201, 200, 
	201, 200, 160, 137, 159, 157, 158, 157, 
	158, 157, 158, 157, 136, 205, 204, 1, 
	204, 33, 34, 33, 28, 31, 30, 209, 
	210, 211, 212, 211, 212, 208, 208, 208, 
	35, 208, 62, 62, 208, 70, 70, 208, 
	0, 155, 156, 203, 156, 203, 156, 203, 
	156, 136, 137, 139, 136, 137, 168, 162, 
	194, 162, 194, 162, 194, 162, 136, 137, 
	168, 162, 194, 162, 194, 162, 194, 162, 
	136, 188, 189, 188, 189, 188, 189, 188, 
	214, 204, 204, 204, 204, 204, 204, 204, 
	204, 204, 204, 204, 204, 204, 204, 204, 
	204, 204, 204, 204, 204, 204, 204, 204, 
	204, 204, 204, 204, 206, 206, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 208, 208, 208, 
	208, 208, 208, 208, 208, 214, 214, 214, 
	214, 214, 214, 214, 214, 214, 214, 214, 
	214, 214, 214, 214, 214, 214, 214, 214, 
	214, 214, 214, 214, 214, 214, 214, 214, 
	214, 214, 214, 214, 214, 214, 214, 214, 
	214, 214, 214, 214, 214, 214, 214, 214, 
	214, 214, 214, 214, 214, 214, 214, 214, 
	214, 214, 214, 214, 214, 204, 206, 208, 
	208, 208, 208, 214, 214, 214, 214, 0
]

class << self
	attr_accessor :_ami_protocol_parser_trans_actions
	private :_ami_protocol_parser_trans_actions, :_ami_protocol_parser_trans_actions=
end
self._ami_protocol_parser_trans_actions = [
	0, 43, 0, 43, 0, 43, 0, 43, 
	0, 43, 0, 43, 0, 43, 0, 43, 
	0, 43, 0, 43, 0, 43, 0, 43, 
	0, 43, 0, 43, 0, 43, 0, 43, 
	0, 43, 0, 43, 0, 43, 0, 43, 
	3, 43, 0, 0, 43, 0, 43, 5, 
	0, 43, 37, 43, 5, 0, 43, 0, 
	0, 43, 122, 0, 0, 0, 122, 0, 
	0, 0, 0, 0, 85, 0, 0, 117, 
	0, 0, 0, 0, 0, 109, 0, 0, 
	0, 0, 55, 0, 55, 0, 55, 0, 
	55, 0, 55, 0, 55, 0, 55, 0, 
	55, 0, 55, 0, 55, 0, 55, 0, 
	55, 0, 55, 0, 55, 0, 55, 0, 
	55, 0, 55, 0, 55, 0, 55, 0, 
	55, 3, 55, 0, 0, 55, 0, 55, 
	5, 0, 55, 45, 55, 5, 0, 55, 
	0, 0, 55, 0, 0, 55, 0, 0, 
	55, 0, 0, 55, 0, 55, 91, 23, 
	23, 25, 0, 100, 25, 0, 91, 23, 
	23, 0, 0, 55, 0, 0, 55, 0, 
	0, 55, 0, 0, 55, 0, 0, 55, 
	0, 0, 55, 0, 55, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 55, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	55, 0, 0, 55, 0, 0, 55, 0, 
	0, 55, 0, 0, 55, 0, 55, 0, 
	55, 0, 0, 55, 0, 0, 55, 0, 
	0, 55, 0, 0, 55, 0, 0, 55, 
	0, 0, 55, 0, 0, 55, 0, 55, 
	15, 15, 15, 0, 0, 0, 0, 0, 
	0, 55, 82, 55, 15, 15, 15, 0, 
	0, 55, 0, 0, 55, 0, 0, 55, 
	0, 0, 55, 0, 0, 55, 0, 0, 
	55, 0, 55, 67, 55, 0, 55, 47, 
	55, 0, 0, 55, 0, 0, 55, 0, 
	0, 55, 1, 55, 97, 55, 0, 0, 
	55, 0, 0, 55, 0, 0, 55, 0, 
	0, 55, 0, 0, 55, 0, 0, 55, 
	1, 55, 94, 55, 0, 7, 7, 7, 
	7, 7, 7, 7, 0, 70, 0, 9, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	0, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 79, 11, 76, 11, 11, 11, 
	11, 11, 11, 11, 11, 13, 0, 0, 
	13, 0, 0, 7, 7, 7, 7, 7, 
	7, 7, 0, 9, 0, 0, 0, 0, 
	0, 0, 0, 0, 79, 11, 76, 11, 
	11, 11, 11, 11, 11, 11, 11, 13, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	0, 13, 9, 0, 0, 0, 0, 0, 
	0, 0, 0, 79, 11, 76, 11, 11, 
	11, 11, 11, 11, 11, 11, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 21, 0, 
	0, 65, 57, 65, 113, 0, 0, 0, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 9, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 9, 0, 0, 0, 
	0, 0, 0, 0, 0, 79, 11, 76, 
	11, 11, 11, 11, 11, 11, 11, 11, 
	13, 0, 106, 13, 0, 0, 9, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 9, 0, 0, 0, 0, 0, 
	0, 0, 0, 79, 11, 76, 11, 11, 
	11, 11, 11, 11, 11, 11, 13, 0, 
	106, 13, 0, 0, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 9, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 9, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 9, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 9, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 9, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 9, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 9, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 21, 9, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 9, 0, 
	0, 0, 0, 0, 0, 0, 63, 9, 
	0, 0, 0, 0, 0, 0, 0, 63, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	63, 79, 11, 76, 11, 11, 11, 11, 
	11, 11, 11, 11, 13, 0, 31, 13, 
	0, 9, 0, 0, 0, 0, 0, 0, 
	0, 63, 9, 0, 0, 0, 0, 0, 
	0, 0, 63, 79, 11, 76, 11, 11, 
	11, 11, 11, 11, 11, 11, 13, 9, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	13, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 79, 11, 76, 11, 11, 11, 
	11, 11, 11, 11, 11, 0, 9, 0, 
	0, 0, 0, 0, 0, 0, 0, 79, 
	11, 76, 11, 11, 11, 11, 11, 11, 
	11, 11, 13, 9, 0, 0, 0, 0, 
	0, 0, 0, 0, 13, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 79, 11, 
	76, 11, 11, 11, 11, 11, 11, 11, 
	11, 79, 11, 76, 11, 11, 11, 11, 
	11, 11, 11, 11, 13, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 13, 9, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	79, 11, 76, 11, 11, 11, 11, 11, 
	11, 11, 11, 0, 9, 0, 0, 0, 
	0, 0, 0, 0, 0, 31, 39, 0, 
	41, 17, 88, 17, 88, 0, 0, 0, 
	31, 31, 31, 31, 31, 51, 49, 53, 
	0, 53, 0, 0, 53, 0, 0, 53, 
	0, 19, 73, 73, 73, 73, 73, 73, 
	73, 19, 0, 0, 0, 0, 7, 7, 
	7, 7, 7, 7, 7, 7, 0, 0, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	0, 7, 7, 7, 7, 7, 7, 7, 
	59, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 35, 35, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 65, 65, 65, 
	65, 65, 65, 65, 65, 65, 65, 65, 
	65, 65, 65, 65, 65, 65, 65, 65, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 41, 33, 53, 
	53, 53, 53, 61, 59, 59, 59, 0
]

class << self
	attr_accessor :_ami_protocol_parser_to_state_actions
	private :_ami_protocol_parser_to_state_actions, :_ami_protocol_parser_to_state_actions=
end
self._ami_protocol_parser_to_state_actions = [
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
	0, 0, 27, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 27, 0, 103, 0, 
	27, 0, 0, 0, 0, 0, 103, 0, 
	0, 0, 0
]

class << self
	attr_accessor :_ami_protocol_parser_from_state_actions
	private :_ami_protocol_parser_from_state_actions, :_ami_protocol_parser_from_state_actions=
end
self._ami_protocol_parser_from_state_actions = [
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 29, 0, 29, 0, 
	29, 0, 0, 0, 0, 0, 29, 0, 
	0, 0, 0
]

class << self
	attr_accessor :_ami_protocol_parser_eof_trans
	private :_ami_protocol_parser_eof_trans, :_ami_protocol_parser_eof_trans=
end
self._ami_protocol_parser_eof_trans = [
	0, 1036, 1036, 1036, 1036, 1036, 1036, 1036, 
	1036, 1036, 1036, 1036, 1036, 1036, 1036, 1036, 
	1036, 1036, 1036, 1036, 1036, 1036, 1036, 1036, 
	1036, 1036, 1036, 1036, 0, 0, 1038, 1038, 
	0, 0, 0, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 
	1125, 1125, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	1144, 1144, 1144, 1144, 1144, 1144, 1144, 1144, 
	1144, 1144, 1144, 1144, 1144, 1144, 1144, 1144, 
	1144, 1144, 1144, 0, 0, 0, 0, 0, 
	0, 0, 1181, 1181, 1181, 1181, 1181, 1181, 
	1181, 1181, 1181, 1181, 1181, 1181, 1181, 1181, 
	1181, 1181, 1181, 1181, 1181, 1181, 1181, 1181, 
	1181, 1181, 1181, 1181, 1181, 1181, 1181, 1181, 
	1181, 1181, 1181, 1181, 1181, 1181, 1181, 0, 
	0, 0, 0, 0, 0, 1182, 0, 1183, 
	0, 1187, 1187, 1187, 1187, 0, 0, 1188, 
	1191, 1191, 1191
]

class << self
	attr_accessor :ami_protocol_parser_start
end
self.ami_protocol_parser_start = 204;
class << self
	attr_accessor :ami_protocol_parser_first_final
end
self.ami_protocol_parser_first_final = 204;
class << self
	attr_accessor :ami_protocol_parser_error
end
self.ami_protocol_parser_error = 0;

class << self
	attr_accessor :ami_protocol_parser_en_irregularity
end
self.ami_protocol_parser_en_irregularity = 206;
class << self
	attr_accessor :ami_protocol_parser_en_main
end
self.ami_protocol_parser_en_main = 204;
class << self
	attr_accessor :ami_protocol_parser_en_protocol
end
self.ami_protocol_parser_en_protocol = 208;
class << self
	attr_accessor :ami_protocol_parser_en_success
end
self.ami_protocol_parser_en_success = 122;
class << self
	attr_accessor :ami_protocol_parser_en_response_follows
end
self.ami_protocol_parser_en_response_follows = 214;


# line 798 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
begin
	     @current_pointer ||= 0
	    @data_ending_pointer ||=   @data.length
	    @current_state = ami_protocol_parser_start
	   @ragel_stack_top = 0
	    @token_start = nil
	    @token_end = nil
	   @ragel_act = 0
end
# line 76 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
##
            
          end
  
          def <<(new_data)
            extend_buffer_with new_data
            resume!
          end
        
          def resume!
            
# line 820 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
begin
	_klen, _trans, _keys, _acts, _nacts = nil
	_goto_level = 0
	_resume = 10
	_eof_trans = 15
	_again = 20
	_test_eof = 30
	_out = 40
	while true
	_trigger_goto = false
	if _goto_level <= 0
	if      @current_pointer ==     @data_ending_pointer
		_goto_level = _test_eof
		next
	end
	if     @current_state == 0
		_goto_level = _out
		next
	end
	end
	if _goto_level <= _resume
	_acts = _ami_protocol_parser_from_state_actions[    @current_state]
	_nacts = _ami_protocol_parser_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _ami_protocol_parser_actions[_acts - 1]
			when 28 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_start =      @current_pointer
		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
# line 855 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
		end # from state action switch
	end
	if _trigger_goto
		next
	end
	_keys = _ami_protocol_parser_key_offsets[    @current_state]
	_trans = _ami_protocol_parser_index_offsets[    @current_state]
	_klen = _ami_protocol_parser_single_lengths[    @current_state]
	_break_match = false
	
	begin
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + _klen - 1

	     loop do
	        break if _upper < _lower
	        _mid = _lower + ( (_upper - _lower) >> 1 )

	        if   @data[     @current_pointer] < _ami_protocol_parser_trans_keys[_mid]
	           _upper = _mid - 1
	        elsif   @data[     @current_pointer] > _ami_protocol_parser_trans_keys[_mid]
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
	  _klen = _ami_protocol_parser_range_lengths[    @current_state]
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + (_klen << 1) - 2
	     loop do
	        break if _upper < _lower
	        _mid = _lower + (((_upper-_lower) >> 1) & ~1)
	        if   @data[     @current_pointer] < _ami_protocol_parser_trans_keys[_mid]
	          _upper = _mid - 2
	        elsif   @data[     @current_pointer] > _ami_protocol_parser_trans_keys[_mid+1]
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
	end
	if _goto_level <= _eof_trans
	    @current_state = _ami_protocol_parser_trans_targs[_trans]
	if _ami_protocol_parser_trans_actions[_trans] != 0
		_acts = _ami_protocol_parser_trans_actions[_trans]
		_nacts = _ami_protocol_parser_actions[_acts]
		_acts += 1
		while _nacts > 0
			_nacts -= 1
			_acts += 1
			case _ami_protocol_parser_actions[_acts - 1]
when 0 then
# line 17 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 init_success 		end
# line 17 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 1 then
# line 19 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 init_response_follows 		end
# line 19 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 2 then
# line 21 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 message_received 		end
# line 21 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 3 then
# line 23 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 version_starts 		end
# line 23 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 4 then
# line 24 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 version_stops  		end
# line 24 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 5 then
# line 26 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 key_starts 		end
# line 26 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 6 then
# line 27 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 key_stops  		end
# line 27 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 7 then
# line 29 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 value_starts 		end
# line 29 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 8 then
# line 30 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 value_stops  		end
# line 30 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 9 then
# line 32 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 error_reason_starts 		end
# line 32 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 10 then
# line 33 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 error_reason_stops 		end
# line 33 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 11 then
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 syntax_error_starts 		end
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 12 then
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 syntax_error_stops  		end
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 13 then
# line 38 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 immediate_response_starts 		end
# line 38 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 14 then
# line 39 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 immediate_response_stops  		end
# line 39 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 15 then
# line 41 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 follows_text_starts 		end
# line 41 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 16 then
# line 42 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 follows_text_stops  		end
# line 42 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 17 then
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 event_name_starts 		end
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 18 then
# line 45 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 event_name_stops  		end
# line 45 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 19 then
# line 34 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 	begin
		    @current_state = 122
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 34 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 20 then
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 	begin
		    @current_state = 122
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 21 then
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 	begin
		    @current_state = 122
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 22 then
# line 38 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 	begin
		    @current_state = 214
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 38 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 23 then
# line 43 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
	begin
		   @ragel_stack_top -= 1
		    @current_state =  @ragel_stack[   @ragel_stack_top]
		_trigger_goto = true
		_goto_level = _again
		break
	end
		end
# line 43 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 24 then
# line 75 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
	begin
		    @current_state = 208
		_trigger_goto = true
		_goto_level = _again
		break
	end
		end
# line 75 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 25 then
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 message_received; 	begin
		    @current_state = 208
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 29 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 30 then
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
   @ragel_act = 1;		end
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 31 then
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 32 then
# line 48 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
 begin  	begin
		   @ragel_stack_top -= 1
		    @current_state =  @ragel_stack[   @ragel_stack_top]
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 48 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 33 then
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1;		end
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 34 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
	case    @ragel_act
	when 0 then
	begin	begin
		    @current_state = 0
		_trigger_goto = true
		_goto_level = _again
		break
	end
end
	else
	begin begin      @current_pointer = ((    @token_end))-1; end
end
end 
			end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 35 then
# line 55 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
 begin  	begin
		    @current_state = 208
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 55 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 36 then
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
 begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
         @current_pointer =      @current_pointer - 1;
    	begin
		    @current_state = 208
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 37 then
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1; begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
         @current_pointer =      @current_pointer - 1;
    	begin
		    @current_state = 208
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 38 then
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 begin      @current_pointer = ((    @token_end))-1; end
 begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
         @current_pointer =      @current_pointer - 1;
    	begin
		    @current_state = 208
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 39 then
# line 64 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 64 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 40 then
# line 65 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 65 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 41 then
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 42 then
# line 67 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 67 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 43 then
# line 68 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
 begin  	begin
		    @current_state = 208
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 68 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 44 then
# line 69 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
 begin 
         @current_pointer =      @current_pointer - 1;
    	begin
		 @ragel_stack[   @ragel_stack_top] =     @current_state
		   @ragel_stack_top+= 1
		    @current_state = 206
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 69 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 45 then
# line 69 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1; begin 
         @current_pointer =      @current_pointer - 1;
    	begin
		 @ragel_stack[   @ragel_stack_top] =     @current_state
		   @ragel_stack_top+= 1
		    @current_state = 206
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 69 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 46 then
# line 69 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 begin      @current_pointer = ((    @token_end))-1; end
 begin 
         @current_pointer =      @current_pointer - 1;
    	begin
		 @ragel_stack[   @ragel_stack_top] =     @current_state
		   @ragel_stack_top+= 1
		    @current_state = 206
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 69 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 47 then
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
   @ragel_act = 11;		end
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 48 then
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
   @ragel_act = 13;		end
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 49 then
# line 80 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 80 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 50 then
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1;		end
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 51 then
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1;		end
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 52 then
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 begin      @current_pointer = ((    @token_end))-1; end
		end
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 53 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
	case    @ragel_act
	when 0 then
	begin	begin
		    @current_state = 0
		_trigger_goto = true
		_goto_level = _again
		break
	end
end
	else
	begin begin      @current_pointer = ((    @token_end))-1; end
end
end 
			end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
# line 1356 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
			end # action switch
		end
	end
	if _trigger_goto
		next
	end
	end
	if _goto_level <= _again
	_acts = _ami_protocol_parser_to_state_actions[    @current_state]
	_nacts = _ami_protocol_parser_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _ami_protocol_parser_actions[_acts - 1]
when 26 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
    @token_start = nil;		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 27 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
   @ragel_act = 0
		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
# line 1383 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
		end # to state action switch
	end
	if _trigger_goto
		next
	end
	if     @current_state == 0
		_goto_level = _out
		next
	end
	     @current_pointer += 1
	if      @current_pointer !=     @data_ending_pointer
		_goto_level = _resume
		next
	end
	end
	if _goto_level <= _test_eof
	if      @current_pointer ==    @eof
	if _ami_protocol_parser_eof_trans[    @current_state] > 0
		_trans = _ami_protocol_parser_eof_trans[    @current_state] - 1;
		_goto_level = _eof_trans
		next;
	end
end
	end
	if _goto_level <= _out
		break
	end
	end
	end
# line 86 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
##
          end
        
          def extend_buffer_with(new_data)
            if new_data.size + @data.size > BUFFER_SIZE
              @data.slice! 0...new_data.size
              # TODO: What if the current_pointer wasn't at the end of the data for some reason?
              @current_pointer = @data.size
            end
            @data << new_data
            @data_ending_pointer = @data.size
          end
        
          protected
                
          ##
          # Called after a response or event has been successfully parsed.
          #
          # @param [NormalAmiResponse, ImmediateResponse, Event] message The message just received
          #
          def message_received(message)
            raise NotImplementedError, "Must be implemented in subclass!"
          end

          ##
          # Called when there is an Error: stanza on the socket. Could be caused by executing an unrecognized command, trying
          # to originate into an invalid priority, etc. Note: many errors' responses are actually tightly coupled to an Event
          # which comes directly after it. Often the message will say something like "Channel status will follow".
          #
          # @param [String] reason The reason given in the Message: header for the error stanza.
          #
          def error_received(reason)
            raise NotImplementedError, "Must be implemented in subclass!"
          end

          ##
          # Called when there's a syntax error on the socket. This doesn't happen as often as it should because, in many cases,
          # it's impossible to distinguish between a syntax error and an immediate packet.
          #
          # @param [String] ignored_chunk The offending text which caused the syntax error.
          def syntax_error_encountered(ignored_chunk)
            raise NotImplementedError, "Must be implemented in subclass!"
          end
        
          def init_success
            @current_message = NormalAmiResponse.new
          end
        
          def init_response_follows
            @current_message = NormalAmiResponse.new(true)
          end
  
          def version_starts
            @start_of_version = @current_pointer
          end
  
          def version_stops
            self.ami_version = @data[@start_of_version...@current_pointer].to_f
            @start_of_version = nil
          end
  
          def event_name_starts
            @event_name_start = @current_pointer
          end
  
          def event_name_stops
            event_name = @data[@event_name_start...@current_pointer]
            @event_name_start = nil
            @current_message = Event.new(event_name)
          end
  
          def key_starts
            @current_key_position = @current_pointer
          end
  
          def key_stops
            @current_key = @data[@current_key_position...@current_pointer]
          end
  
          def value_starts
            @current_value_position = @current_pointer
          end
  
          def value_stops
            @current_value = @data[@current_value_position...@current_pointer]
            @last_seen_value_end = @current_pointer + 2 # 2 for \r\n
            add_pair_to_current_message
          end
  
          def error_reason_starts
            @error_reason_start = @current_pointer
          end
  
          def error_reason_stops
            error_received @data[@error_reason_start...@current_pointer - 3]
            @error_reason_start = nil
          end
  
          def follows_text_starts
            @follows_text_start = @current_pointer
          end
  
          def follows_text_stops
            text = @data[@last_seen_value_end..(@current_pointer - "\r\n--END COMMAND--".size)]
            @current_message.text = text
            @follows_text_start = nil
          end
  
          def add_pair_to_current_message
            @current_message[@current_key] = @current_value
            reset_key_and_value_positions
          end
  
          def reset_key_and_value_positions
            @current_key, @current_value, @current_key_position, @current_value_position = nil
          end
  
          def syntax_error_starts
            @current_syntax_error_start = @current_pointer # Adding 1 since the pointer is still set to the last successful match
          end
  
          def syntax_error_stops
            # Subtracting 3 from @current_pointer below for "\r\n" which separates a stanza
            offending_data = @data[@current_syntax_error_start...@current_pointer - 1]
            syntax_error_encountered offending_data
            @current_syntax_error_start = nil
          end
  
          def immediate_response_starts
            @immediate_response_start = @current_pointer
          end
  
          def immediate_response_stops
            message = @data[@immediate_response_start...(@current_pointer -1)]
            message_received ImmediateResponse.new(message)
          end
  
          ##
          # This method is used primarily in debugging.
          #
          def view_buffer(message=nil)
    
            message ||= "Viewing the buffer"
    
            buffer = @data.clone
            buffer.insert(@current_pointer, "\033[0;31m\033[1;31m^\033[0m")
    
            buffer.gsub!("\r", "\\\\r")
            buffer.gsub!("\n", "\\n\n")
    
            puts <<-INSPECTION
VVVVVVVVVVVVVVVVVVVVVVVVVVVVV
####  #{message}
#############################
#{buffer}
#############################
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            INSPECTION
    
          end
        end
        class DelegatingAsteriskManagerInterfaceParser < AbstractAsteriskManagerInterfaceStreamParser
          
          def initialize(delegate, method_delegation_map=nil)
            super()
            @delegate = delegate
            
            @message_received_method = method_delegation_map ? method_delegation_map[:message_received] : :message_received
            @error_received_method = method_delegation_map   ? method_delegation_map[:error_received]   : :error_received
            @syntax_error_method = method_delegation_map ? method_delegation_map[:syntax_error_encountered] :
                :syntax_error_encountered
          end
          
          def message_received(message)
            @delegate.send(@message_received_method, message)
          end
          
          def error_received(message)
            @delegate.send(@error_received_method, message)
          end
          
          def syntax_error_encountered(ignored_chunk)
            @delegate.send(@syntax_error_method, ignored_chunk)
          end
          
        end
      end
    end
  end
end