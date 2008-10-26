# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
require File.join(File.dirname(__FILE__), 'packets.rb')

module Adhearsion
  module VoIP
    module Asterisk
      module Manager
        class AbstractAsteriskManagerInterfaceStreamParser

          BUFFER_SIZE = 8.kilobytes unless defined? BUFFER_SIZE

          CAPTURED_VARIABLES = {} unless defined? CAPTURED_VARIABLES
          CAPTURE_CALLBACKS  = {} unless defined? CAPTURE_CALLBACKS
          
          # line 50 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
##

          attr_accessor(:ami_version)
          def initialize
    
            @data = ""
            @current_pointer = 0
            
            
# line 26 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
class << self
	attr_accessor :_ami_protocol_parser_actions
	private :_ami_protocol_parser_actions, :_ami_protocol_parser_actions=
end
self._ami_protocol_parser_actions = [
	0, 1, 0, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 11, 1, 15, 1, 16, 1, 
	17, 1, 18, 1, 27, 1, 29, 1, 
	30, 1, 34, 1, 35, 1, 36, 1, 
	37, 1, 38, 1, 39, 1, 40, 1, 
	43, 1, 44, 1, 45, 1, 46, 1, 
	47, 1, 50, 1, 51, 1, 52, 1, 
	53, 1, 54, 2, 1, 22, 2, 2, 
	25, 2, 5, 15, 2, 6, 7, 2, 
	7, 8, 2, 10, 42, 2, 12, 24, 
	2, 12, 33, 2, 13, 11, 2, 17, 
	18, 2, 19, 41, 2, 20, 41, 2, 
	21, 41, 2, 27, 28, 2, 30, 48, 
	3, 14, 23, 32, 3, 30, 26, 49, 
	4, 14, 23, 32, 12, 4, 30, 14, 
	23, 31
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
	205, 206, 207, 208, 209, 211, 212, 214, 
	229, 230, 245, 260, 275, 292, 293, 295, 
	310, 325, 342, 358, 374, 391, 392, 394, 
	396, 398, 400, 402, 404, 406, 408, 410, 
	412, 414, 416, 418, 420, 422, 424, 425, 
	426, 428, 444, 460, 476, 493, 494, 496, 
	512, 528, 544, 561, 562, 564, 581, 598, 
	615, 632, 649, 666, 683, 700, 717, 734, 
	751, 768, 785, 802, 818, 833, 848, 865, 
	866, 868, 883, 898, 915, 931, 947, 964, 
	980, 997, 1013, 1029, 1046, 1063, 1079, 1095, 
	1112, 1128, 1129, 1130, 1133, 1134, 1140, 1141, 
	1142, 1144, 1146, 1147, 1147, 1162, 1164, 1180, 
	1196
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
	13, 10, 13, 13, 10, 13, 13, 32, 
	47, 48, 57, 58, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 10, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 10, 13, 13, 
	32, 47, 48, 57, 58, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 32, 
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
	10, 13, 13, 45, 13, 45, 13, 69, 
	13, 78, 13, 68, 13, 32, 13, 67, 
	13, 79, 13, 77, 13, 77, 13, 65, 
	13, 78, 13, 68, 13, 45, 13, 45, 
	13, 10, 10, 13, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 58, 33, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 10, 13, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 32, 58, 33, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 10, 13, 13, 45, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 69, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	78, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 68, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 32, 58, 33, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 67, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 79, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 77, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 77, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 65, 
	32, 47, 48, 57, 59, 64, 66, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	78, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 68, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 45, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 45, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 32, 58, 33, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 10, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 58, 33, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 58, 33, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	65, 115, 10, 13, 58, 13, 13, 65, 
	69, 82, 101, 114, 10, 115, 86, 118, 
	69, 101, 13, 13, 32, 47, 48, 57, 
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
	1, 1, 1, 1, 2, 1, 2, 1, 
	1, 1, 1, 1, 3, 1, 2, 1, 
	1, 3, 2, 2, 3, 1, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 1, 1, 
	2, 2, 2, 2, 3, 1, 2, 2, 
	2, 2, 3, 1, 2, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 2, 1, 1, 3, 1, 
	2, 1, 1, 3, 2, 2, 3, 2, 
	3, 2, 2, 3, 3, 2, 2, 3, 
	2, 1, 1, 3, 1, 6, 1, 1, 
	2, 2, 1, 0, 1, 2, 2, 2, 
	0
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
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 7, 7, 7, 7, 0, 0, 7, 
	7, 7, 7, 7, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 7, 7, 7, 0, 0, 7, 
	7, 7, 7, 0, 0, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 0, 
	0, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 7, 7, 
	7
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
	312, 314, 316, 318, 320, 323, 325, 328, 
	337, 339, 348, 357, 366, 377, 379, 382, 
	391, 400, 411, 421, 431, 442, 444, 447, 
	450, 453, 456, 459, 462, 465, 468, 471, 
	474, 477, 480, 483, 486, 489, 492, 494, 
	496, 499, 509, 519, 529, 540, 542, 545, 
	555, 565, 575, 586, 588, 591, 602, 613, 
	624, 635, 646, 657, 668, 679, 690, 701, 
	712, 723, 734, 745, 755, 764, 773, 784, 
	786, 789, 798, 807, 818, 828, 838, 849, 
	859, 870, 880, 890, 901, 912, 922, 932, 
	943, 953, 955, 957, 961, 963, 970, 972, 
	974, 977, 980, 982, 983, 992, 995, 1005, 
	1015
]

class << self
	attr_accessor :_ami_protocol_parser_trans_targs
	private :_ami_protocol_parser_trans_targs, :_ami_protocol_parser_trans_targs=
end
self._ami_protocol_parser_trans_targs = [
	2, 209, 3, 209, 4, 209, 5, 209, 
	6, 209, 7, 209, 8, 209, 9, 209, 
	10, 209, 11, 209, 12, 209, 13, 209, 
	14, 209, 15, 209, 16, 209, 17, 209, 
	18, 209, 19, 209, 20, 209, 21, 209, 
	22, 209, 23, 27, 209, 24, 209, 25, 
	26, 209, 209, 209, 25, 26, 209, 23, 
	27, 209, 212, 32, 30, 29, 212, 32, 
	30, 29, 31, 30, 211, 31, 30, 211, 
	32, 30, 29, 31, 30, 211, 32, 30, 
	29, 36, 213, 37, 213, 38, 213, 39, 
	213, 40, 213, 41, 213, 42, 213, 43, 
	213, 44, 213, 45, 213, 46, 213, 47, 
	213, 48, 213, 49, 213, 50, 213, 51, 
	213, 52, 213, 53, 213, 54, 213, 55, 
	213, 56, 213, 57, 61, 213, 58, 213, 
	59, 60, 213, 213, 213, 59, 60, 213, 
	57, 61, 213, 63, 63, 213, 64, 64, 
	213, 65, 65, 213, 66, 213, 68, 69, 
	67, 68, 67, 213, 68, 67, 68, 69, 
	67, 71, 71, 213, 72, 72, 213, 73, 
	73, 213, 74, 74, 213, 75, 75, 213, 
	76, 76, 213, 77, 213, 78, 79, 99, 
	109, 114, 79, 99, 109, 114, 213, 78, 
	79, 99, 109, 114, 79, 99, 109, 114, 
	213, 80, 80, 213, 81, 81, 213, 82, 
	82, 213, 83, 83, 213, 84, 213, 85, 
	213, 86, 86, 213, 87, 87, 213, 88, 
	88, 213, 89, 89, 213, 90, 90, 213, 
	91, 91, 213, 92, 92, 213, 93, 213, 
	95, 98, 94, 95, 94, 96, 95, 94, 
	97, 213, 213, 213, 95, 98, 94, 100, 
	100, 213, 101, 101, 213, 102, 102, 213, 
	103, 103, 213, 104, 104, 213, 105, 105, 
	213, 106, 213, 107, 213, 108, 213, 213, 
	213, 110, 110, 213, 111, 111, 213, 112, 
	112, 213, 113, 213, 213, 213, 115, 115, 
	213, 116, 116, 213, 117, 117, 213, 118, 
	118, 213, 119, 119, 213, 120, 120, 213, 
	121, 213, 213, 213, 124, 123, 124, 123, 
	125, 124, 123, 126, 123, 218, 124, 123, 
	128, 129, 136, 129, 136, 129, 136, 129, 
	0, 219, 0, 132, 130, 131, 130, 131, 
	130, 131, 130, 0, 132, 130, 131, 130, 
	131, 130, 131, 130, 0, 132, 130, 131, 
	130, 131, 130, 131, 130, 0, 134, 137, 
	140, 138, 139, 138, 139, 138, 139, 138, 
	133, 134, 133, 135, 134, 133, 128, 129, 
	136, 129, 136, 129, 136, 129, 0, 132, 
	130, 131, 130, 131, 130, 131, 130, 0, 
	134, 137, 140, 138, 139, 138, 139, 138, 
	139, 138, 133, 134, 140, 138, 139, 138, 
	139, 138, 139, 138, 133, 134, 140, 138, 
	139, 138, 139, 138, 139, 138, 133, 134, 
	137, 140, 138, 139, 138, 139, 138, 139, 
	138, 133, 142, 141, 143, 142, 141, 142, 
	144, 141, 142, 145, 141, 142, 146, 141, 
	142, 147, 141, 142, 148, 141, 142, 149, 
	141, 142, 150, 141, 142, 151, 141, 142, 
	152, 141, 142, 153, 141, 142, 154, 141, 
	142, 155, 141, 142, 156, 141, 142, 157, 
	141, 142, 158, 141, 159, 220, 220, 220, 
	221, 142, 141, 142, 164, 162, 163, 162, 
	163, 162, 163, 162, 141, 142, 164, 162, 
	163, 162, 163, 162, 163, 162, 141, 142, 
	164, 162, 163, 162, 163, 162, 163, 162, 
	141, 166, 204, 207, 205, 206, 205, 206, 
	205, 206, 205, 165, 166, 165, 222, 166, 
	165, 142, 170, 168, 169, 168, 169, 168, 
	169, 168, 141, 142, 170, 168, 169, 168, 
	169, 168, 169, 168, 141, 142, 170, 168, 
	169, 168, 169, 168, 169, 168, 141, 172, 
	200, 203, 201, 202, 201, 202, 201, 202, 
	201, 171, 172, 171, 223, 172, 171, 142, 
	174, 170, 168, 169, 168, 169, 168, 169, 
	168, 141, 142, 170, 175, 168, 169, 168, 
	169, 168, 169, 168, 141, 142, 170, 176, 
	168, 169, 168, 169, 168, 169, 168, 141, 
	142, 170, 177, 168, 169, 168, 169, 168, 
	169, 168, 141, 142, 178, 170, 168, 169, 
	168, 169, 168, 169, 168, 141, 142, 170, 
	179, 168, 169, 168, 169, 168, 169, 168, 
	141, 142, 170, 180, 168, 169, 168, 169, 
	168, 169, 168, 141, 142, 170, 181, 168, 
	169, 168, 169, 168, 169, 168, 141, 142, 
	170, 182, 168, 169, 168, 169, 168, 169, 
	168, 141, 142, 170, 183, 168, 169, 168, 
	169, 168, 169, 168, 141, 142, 170, 184, 
	168, 169, 168, 169, 168, 169, 168, 141, 
	142, 170, 185, 168, 169, 168, 169, 168, 
	169, 168, 141, 142, 186, 170, 168, 169, 
	168, 169, 168, 169, 168, 141, 142, 187, 
	170, 168, 169, 168, 169, 168, 169, 168, 
	141, 159, 190, 188, 189, 188, 189, 188, 
	189, 188, 220, 190, 188, 189, 188, 189, 
	188, 189, 188, 220, 190, 188, 189, 188, 
	189, 188, 189, 188, 220, 192, 195, 198, 
	196, 197, 196, 197, 196, 197, 196, 191, 
	192, 191, 224, 192, 191, 190, 188, 189, 
	188, 189, 188, 189, 188, 220, 190, 188, 
	189, 188, 189, 188, 189, 188, 220, 192, 
	195, 198, 196, 197, 196, 197, 196, 197, 
	196, 191, 192, 198, 196, 197, 196, 197, 
	196, 197, 196, 191, 192, 198, 196, 197, 
	196, 197, 196, 197, 196, 191, 192, 195, 
	198, 196, 197, 196, 197, 196, 197, 196, 
	191, 142, 170, 168, 169, 168, 169, 168, 
	169, 168, 141, 172, 200, 203, 201, 202, 
	201, 202, 201, 202, 201, 171, 172, 203, 
	201, 202, 201, 202, 201, 202, 201, 171, 
	172, 203, 201, 202, 201, 202, 201, 202, 
	201, 171, 172, 200, 203, 201, 202, 201, 
	202, 201, 202, 201, 171, 166, 204, 207, 
	205, 206, 205, 206, 205, 206, 205, 165, 
	166, 207, 205, 206, 205, 206, 205, 206, 
	205, 165, 166, 207, 205, 206, 205, 206, 
	205, 206, 205, 165, 166, 204, 207, 205, 
	206, 205, 206, 205, 206, 205, 165, 142, 
	164, 162, 163, 162, 163, 162, 163, 162, 
	141, 210, 209, 1, 209, 33, 34, 33, 
	28, 31, 30, 214, 215, 216, 217, 216, 
	217, 213, 213, 213, 35, 213, 62, 62, 
	213, 70, 70, 213, 126, 123, 0, 160, 
	161, 208, 161, 208, 161, 208, 161, 141, 
	142, 144, 141, 142, 173, 167, 199, 167, 
	199, 167, 199, 167, 141, 142, 173, 167, 
	199, 167, 199, 167, 199, 167, 141, 193, 
	194, 193, 194, 193, 194, 193, 220, 209, 
	209, 209, 209, 209, 209, 209, 209, 209, 
	209, 209, 209, 209, 209, 209, 209, 209, 
	209, 209, 209, 209, 209, 209, 209, 209, 
	209, 209, 211, 211, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 213, 213, 213, 213, 213, 
	213, 213, 213, 220, 220, 220, 220, 220, 
	220, 220, 220, 220, 220, 220, 220, 220, 
	220, 220, 220, 220, 220, 220, 220, 220, 
	220, 220, 220, 220, 220, 220, 220, 220, 
	220, 220, 220, 220, 220, 220, 220, 220, 
	220, 220, 220, 220, 220, 220, 220, 220, 
	220, 220, 220, 220, 220, 220, 220, 220, 
	220, 220, 220, 209, 211, 213, 213, 213, 
	213, 220, 220, 220, 220, 0
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
	0, 43, 125, 0, 0, 0, 125, 0, 
	0, 0, 0, 0, 88, 0, 0, 120, 
	0, 0, 0, 0, 0, 112, 0, 0, 
	0, 0, 55, 0, 55, 0, 55, 0, 
	55, 0, 55, 0, 55, 0, 55, 0, 
	55, 0, 55, 0, 55, 0, 55, 0, 
	55, 0, 55, 0, 55, 0, 55, 0, 
	55, 0, 55, 0, 55, 0, 55, 0, 
	55, 3, 55, 0, 0, 55, 0, 55, 
	5, 0, 55, 45, 55, 5, 0, 55, 
	0, 0, 55, 0, 0, 55, 0, 0, 
	55, 0, 0, 55, 0, 55, 94, 23, 
	23, 25, 0, 103, 25, 0, 94, 23, 
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
	0, 55, 1, 55, 100, 55, 0, 0, 
	55, 0, 0, 55, 0, 0, 55, 0, 
	0, 55, 0, 0, 55, 0, 0, 55, 
	1, 55, 97, 55, 17, 17, 0, 0, 
	0, 0, 0, 0, 0, 85, 0, 0, 
	0, 7, 7, 7, 7, 7, 7, 7, 
	0, 70, 0, 9, 0, 0, 0, 0, 
	0, 0, 0, 0, 9, 0, 0, 0, 
	0, 0, 0, 0, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 79, 11, 
	76, 11, 11, 11, 11, 11, 11, 11, 
	11, 13, 0, 0, 13, 0, 0, 7, 
	7, 7, 7, 7, 7, 7, 0, 9, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	79, 11, 76, 11, 11, 11, 11, 11, 
	11, 11, 11, 13, 9, 0, 0, 0, 
	0, 0, 0, 0, 0, 13, 9, 0, 
	0, 0, 0, 0, 0, 0, 0, 79, 
	11, 76, 11, 11, 11, 11, 11, 11, 
	11, 11, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 21, 0, 0, 65, 57, 65, 
	116, 0, 0, 0, 9, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 9, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	0, 79, 11, 76, 11, 11, 11, 11, 
	11, 11, 11, 11, 13, 0, 109, 13, 
	0, 0, 9, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 9, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 9, 0, 
	0, 0, 0, 0, 0, 0, 0, 79, 
	11, 76, 11, 11, 11, 11, 11, 11, 
	11, 11, 13, 0, 109, 13, 0, 0, 
	0, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 9, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 9, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 9, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 9, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 9, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 9, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 21, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 9, 0, 0, 0, 0, 0, 
	0, 0, 63, 9, 0, 0, 0, 0, 
	0, 0, 0, 63, 9, 0, 0, 0, 
	0, 0, 0, 0, 63, 79, 11, 76, 
	11, 11, 11, 11, 11, 11, 11, 11, 
	13, 0, 31, 13, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 63, 9, 0, 
	0, 0, 0, 0, 0, 0, 63, 79, 
	11, 76, 11, 11, 11, 11, 11, 11, 
	11, 11, 13, 9, 0, 0, 0, 0, 
	0, 0, 0, 0, 13, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 79, 11, 
	76, 11, 11, 11, 11, 11, 11, 11, 
	11, 0, 9, 0, 0, 0, 0, 0, 
	0, 0, 0, 79, 11, 76, 11, 11, 
	11, 11, 11, 11, 11, 11, 13, 9, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	13, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 79, 11, 76, 11, 11, 11, 
	11, 11, 11, 11, 11, 79, 11, 76, 
	11, 11, 11, 11, 11, 11, 11, 11, 
	13, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 13, 9, 0, 0, 0, 0, 
	0, 0, 0, 0, 79, 11, 76, 11, 
	11, 11, 11, 11, 11, 11, 11, 0, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	0, 31, 39, 0, 41, 17, 91, 17, 
	91, 0, 0, 0, 31, 31, 31, 31, 
	31, 51, 49, 53, 0, 53, 0, 0, 
	53, 0, 0, 53, 0, 0, 0, 19, 
	73, 73, 73, 73, 73, 73, 73, 19, 
	0, 0, 0, 0, 7, 7, 7, 7, 
	7, 7, 7, 7, 0, 0, 7, 7, 
	7, 7, 7, 7, 7, 7, 0, 7, 
	7, 7, 7, 7, 7, 7, 59, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 35, 35, 55, 55, 55, 55, 
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
	55, 55, 55, 65, 65, 65, 65, 65, 
	65, 65, 65, 65, 65, 65, 65, 65, 
	65, 65, 65, 65, 65, 65, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 41, 33, 53, 53, 53, 
	53, 61, 59, 59, 59, 0
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
	0, 0, 27, 0, 0, 0, 0, 27, 
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
	0, 27, 0, 106, 0, 27, 0, 0, 
	0, 0, 0, 0, 106, 0, 0, 0, 
	0
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 29, 0, 29, 0, 29, 0, 0, 
	0, 0, 0, 0, 29, 0, 0, 0, 
	0
]

class << self
	attr_accessor :_ami_protocol_parser_eof_trans
	private :_ami_protocol_parser_eof_trans, :_ami_protocol_parser_eof_trans=
end
self._ami_protocol_parser_eof_trans = [
	0, 1050, 1050, 1050, 1050, 1050, 1050, 1050, 
	1050, 1050, 1050, 1050, 1050, 1050, 1050, 1050, 
	1050, 1050, 1050, 1050, 1050, 1050, 1050, 1050, 
	1050, 1050, 1050, 1050, 0, 0, 1052, 1052, 
	0, 0, 0, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 1139, 1139, 1139, 1139, 1139, 1139, 
	1139, 1139, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 1158, 1158, 1158, 
	1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 
	1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 
	0, 0, 0, 0, 0, 0, 0, 1195, 
	1195, 1195, 1195, 1195, 1195, 1195, 1195, 1195, 
	1195, 1195, 1195, 1195, 1195, 1195, 1195, 1195, 
	1195, 1195, 1195, 1195, 1195, 1195, 1195, 1195, 
	1195, 1195, 1195, 1195, 1195, 1195, 1195, 1195, 
	1195, 1195, 1195, 1195, 0, 0, 0, 0, 
	0, 0, 1196, 0, 1197, 0, 1201, 1201, 
	1201, 1201, 0, 0, 0, 1202, 1205, 1205, 
	1205
]

class << self
	attr_accessor :ami_protocol_parser_start
end
self.ami_protocol_parser_start = 209;
class << self
	attr_accessor :ami_protocol_parser_error
end
self.ami_protocol_parser_error = 0;

class << self
	attr_accessor :ami_protocol_parser_en_irregularity
end
self.ami_protocol_parser_en_irregularity = 211;
class << self
	attr_accessor :ami_protocol_parser_en_main
end
self.ami_protocol_parser_en_main = 209;
class << self
	attr_accessor :ami_protocol_parser_en_protocol
end
self.ami_protocol_parser_en_protocol = 213;
class << self
	attr_accessor :ami_protocol_parser_en_error_recovery
end
self.ami_protocol_parser_en_error_recovery = 122;
class << self
	attr_accessor :ami_protocol_parser_en_success
end
self.ami_protocol_parser_en_success = 127;
class << self
	attr_accessor :ami_protocol_parser_en_response_follows
end
self.ami_protocol_parser_en_response_follows = 220;


# line 813 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
begin
	 @current_pointer ||= 0
	 @data_ending_pointer ||=  @data.length
	 @current_state = ami_protocol_parser_start
	 @token_start = nil
	 @token_end = nil
	 @ragel_act = 0
end
# line 74 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
##
          end
  
          def <<(new_data)
            extend_buffer_with new_data
            resume!
          end
        
          def resume!
            
# line 833 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
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
	if  @current_pointer ==  @data_ending_pointer
		_goto_level = _test_eof
		next
	end
	if  @current_state == 0
		_goto_level = _out
		next
	end
	end
	if _goto_level <= _resume
	_acts = _ami_protocol_parser_from_state_actions[ @current_state]
	_nacts = _ami_protocol_parser_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _ami_protocol_parser_actions[_acts - 1]
			when 29 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_start =  @current_pointer
		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
# line 868 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
		end # from state action switch
	end
	if _trigger_goto
		next
	end
	_keys = _ami_protocol_parser_key_offsets[ @current_state]
	_trans = _ami_protocol_parser_index_offsets[ @current_state]
	_klen = _ami_protocol_parser_single_lengths[ @current_state]
	_break_match = false
	
	begin
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + _klen - 1

	     loop do
	        break if _upper < _lower
	        _mid = _lower + ( (_upper - _lower) >> 1 )

	        if  @data[ @current_pointer] < _ami_protocol_parser_trans_keys[_mid]
	           _upper = _mid - 1
	        elsif  @data[ @current_pointer] > _ami_protocol_parser_trans_keys[_mid]
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
	  _klen = _ami_protocol_parser_range_lengths[ @current_state]
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + (_klen << 1) - 2
	     loop do
	        break if _upper < _lower
	        _mid = _lower + (((_upper-_lower) >> 1) & ~1)
	        if  @data[ @current_pointer] < _ami_protocol_parser_trans_keys[_mid]
	          _upper = _mid - 2
	        elsif  @data[ @current_pointer] > _ami_protocol_parser_trans_keys[_mid+1]
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
# line 18 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 init_success 		end
# line 18 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 1 then
# line 20 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 init_response_follows 		end
# line 20 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 2 then
# line 22 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 message_received @current_message 		end
# line 22 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 3 then
# line 24 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 version_starts 		end
# line 24 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 4 then
# line 25 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 version_stops  		end
# line 25 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 5 then
# line 27 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 key_starts 		end
# line 27 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 6 then
# line 28 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 key_stops  		end
# line 28 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 7 then
# line 30 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 value_starts 		end
# line 30 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 8 then
# line 31 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 value_stops  		end
# line 31 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 9 then
# line 33 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 error_reason_starts 		end
# line 33 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 10 then
# line 34 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 error_reason_stops 		end
# line 34 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 11 then
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 syntax_error_starts 		end
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 12 then
# line 37 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 syntax_error_stops  		end
# line 37 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 13 then
# line 39 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 immediate_response_starts 		end
# line 39 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 14 then
# line 40 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 immediate_response_stops  		end
# line 40 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 15 then
# line 42 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 follows_text_starts 		end
# line 42 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 16 then
# line 43 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 follows_text_stops  		end
# line 43 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 17 then
# line 45 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 event_name_starts 		end
# line 45 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 18 then
# line 46 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 event_name_stops  		end
# line 46 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 19 then
# line 31 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 	begin
		 @current_state = 127
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 31 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 20 then
# line 32 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 	begin
		 @current_state = 127
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 32 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 21 then
# line 33 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 	begin
		 @current_state = 127
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 33 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 22 then
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 	begin
		 @current_state = 220
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 23 then
# line 40 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
		end
# line 40 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 24 then
# line 73 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
		end
# line 73 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 25 then
# line 75 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
		end
# line 75 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 26 then
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 message_received; 	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 30 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 31 then
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @ragel_act = 1;		end
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 32 then
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
 begin  	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 33 then
# line 45 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
 begin  	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 45 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 34 then
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1; begin  	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 35 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
	case  @ragel_act
	when 0 then
	begin	begin
		 @current_state = 0
		_trigger_goto = true
		_goto_level = _again
		break
	end
end
	when 1 then
	begin begin  @current_pointer = (( @token_end))-1; end
 	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
 end
end 
			end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 36 then
# line 52 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
 begin  	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 52 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 37 then
# line 53 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
 begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 53 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 38 then
# line 53 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1; begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 53 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 39 then
# line 53 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 begin  @current_pointer = (( @token_end))-1; end
 begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 53 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 40 then
# line 61 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
		end
# line 61 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 41 then
# line 22 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
 begin  message_received @current_message  end
		end
# line 22 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 42 then
# line 63 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
		end
# line 63 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 43 then
# line 64 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
		end
# line 64 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 44 then
# line 65 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
 begin  	begin
		 @current_state = 213
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 65 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 45 then
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
 begin 
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 211
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 46 then
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1; begin 
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 211
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 47 then
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 begin  @current_pointer = (( @token_end))-1; end
 begin 
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 211
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 48 then
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @ragel_act = 11;		end
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 49 then
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @ragel_act = 13;		end
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 50 then
# line 80 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer+1
		end
# line 80 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 51 then
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 52 then
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 81 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 53 then
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 begin  @current_pointer = (( @token_end))-1; end
		end
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 54 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
	case  @ragel_act
	when 0 then
	begin	begin
		 @current_state = 0
		_trigger_goto = true
		_goto_level = _again
		break
	end
end
	else
	begin begin  @current_pointer = (( @token_end))-1; end
end
end 
			end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
# line 1393 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
			end # action switch
		end
	end
	if _trigger_goto
		next
	end
	end
	if _goto_level <= _again
	_acts = _ami_protocol_parser_to_state_actions[ @current_state]
	_nacts = _ami_protocol_parser_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _ami_protocol_parser_actions[_acts - 1]
when 27 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @token_start = nil;		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
when 28 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
		begin
 @ragel_act = 0
		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
# line 1420 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rb"
		end # to state action switch
	end
	if _trigger_goto
		next
	end
	if  @current_state == 0
		_goto_level = _out
		next
	end
	 @current_pointer += 1
	if  @current_pointer !=  @data_ending_pointer
		_goto_level = _resume
		next
	end
	end
	if _goto_level <= _test_eof
	if  @current_pointer ==  @eof
	if _ami_protocol_parser_eof_trans[ @current_state] > 0
		_trans = _ami_protocol_parser_eof_trans[ @current_state] - 1;
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
# line 83 "lib/adhearsion/voip/asterisk/manager_interface/ami_parser.rl.rb"
##
          end
        
          def extend_buffer_with(new_data)
            if new_data.size + @data.size > BUFFER_SIZE
              @data.slice! 0...new_data.size
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
  
          def begin_capturing_variable(variable_name)
            @start_of_current_capture = @current_pointer
          end
  
          def finish_capturing_variable(variable_name)
            start, stop = @start_of_current_capture, @current_pointer
            return :failed if !start || start > stop
            capture = @data[start...stop]
            CAPTURED_VARIABLES[variable_name] = capture
            capture
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
      end
    end
  end
end