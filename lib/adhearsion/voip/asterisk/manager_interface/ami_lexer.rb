# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
require File.join(File.dirname(__FILE__), 'ami_messages.rb')

module Adhearsion
  module VoIP
    module Asterisk
      module Manager
        class AbstractAsteriskManagerInterfaceStreamLexer

          BUFFER_SIZE = 8.kilobytes unless defined? BUFFER_SIZE

          # line 52 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
##

          attr_accessor(:ami_version)
          def initialize
    
            @data = ""
            @current_pointer = 0
            @ragel_stack = []
            
            
# line 24 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rb"
class << self
	attr_accessor :_ami_protocol_parser_actions
	private :_ami_protocol_parser_actions, :_ami_protocol_parser_actions=
end
self._ami_protocol_parser_actions = [
	0, 1, 0, 1, 2, 1, 5, 1, 
	6, 1, 7, 1, 8, 1, 9, 1, 
	10, 1, 13, 1, 17, 1, 18, 1, 
	19, 1, 20, 1, 28, 1, 30, 1, 
	31, 1, 35, 1, 36, 1, 37, 1, 
	38, 1, 39, 1, 40, 1, 41, 1, 
	46, 1, 47, 1, 48, 1, 49, 1, 
	50, 1, 53, 1, 54, 1, 55, 1, 
	56, 1, 57, 2, 1, 24, 2, 3, 
	26, 2, 4, 45, 2, 7, 17, 2, 
	9, 10, 2, 11, 9, 2, 12, 10, 
	2, 14, 34, 2, 15, 13, 2, 19, 
	20, 2, 21, 42, 2, 22, 43, 2, 
	23, 44, 2, 28, 29, 2, 31, 51, 
	3, 16, 25, 33, 3, 31, 27, 52, 
	4, 11, 12, 9, 10, 4, 16, 25, 
	33, 14, 4, 31, 16, 25, 32
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
	137, 139, 141, 143, 144, 145, 161, 176, 
	191, 206, 208, 209, 211, 228, 229, 244, 
	259, 274, 276, 277, 279, 296, 311, 328, 
	345, 362, 379, 396, 413, 428, 430, 431, 
	433, 450, 452, 454, 456, 471, 488, 505, 
	522, 539, 556, 573, 588, 590, 591, 593, 
	610, 612, 614, 616, 618, 620, 622, 624, 
	625, 626, 627, 628, 630, 632, 634, 635, 
	636, 638, 640, 642, 644, 646, 648, 649, 
	650, 665, 666, 681, 696, 711, 713, 714, 
	716, 731, 746, 748, 749, 751, 753, 755, 
	757, 759, 761, 763, 765, 767, 769, 771, 
	773, 775, 777, 779, 781, 782, 783, 785, 
	801, 817, 833, 835, 836, 838, 854, 870, 
	886, 888, 889, 891, 908, 925, 942, 959, 
	976, 993, 1010, 1027, 1044, 1061, 1078, 1095, 
	1112, 1129, 1145, 1160, 1175, 1177, 1178, 1180, 
	1195, 1210, 1212, 1228, 1230, 1232, 1248, 1249, 
	1250, 1253, 1254, 1260, 1261, 1262, 1264, 1266, 
	1266, 1281, 1283, 1299, 1315
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
	10, 77, 109, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 32, 
	13, 10, 13, 13, 77, 109, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 10, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 13, 10, 13, 13, 
	77, 109, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	69, 101, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 83, 115, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 83, 115, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 58, 65, 97, 32, 47, 48, 
	57, 59, 64, 66, 90, 91, 96, 98, 
	122, 123, 126, 58, 71, 103, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 69, 101, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 13, 10, 
	13, 13, 77, 109, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 13, 32, 13, 32, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	69, 101, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 83, 115, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 83, 115, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 58, 65, 97, 32, 47, 48, 
	57, 59, 64, 66, 90, 91, 96, 98, 
	122, 123, 126, 58, 71, 103, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 69, 101, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 13, 10, 
	13, 13, 77, 109, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 79, 111, 76, 108, 
	76, 108, 79, 111, 87, 119, 83, 115, 
	13, 10, 13, 10, 79, 111, 78, 110, 
	71, 103, 13, 10, 85, 117, 67, 99, 
	67, 99, 69, 101, 83, 115, 83, 115, 
	13, 10, 13, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 10, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	32, 13, 10, 13, 13, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 13, 10, 13, 13, 
	45, 13, 45, 13, 69, 13, 78, 13, 
	68, 13, 32, 13, 67, 13, 79, 13, 
	77, 13, 77, 13, 65, 13, 78, 13, 
	68, 13, 45, 13, 45, 13, 10, 10, 
	13, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 32, 13, 10, 13, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 32, 
	13, 10, 13, 13, 45, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 69, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 78, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	68, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 67, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 79, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 77, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 77, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 65, 32, 
	47, 48, 57, 59, 64, 66, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 78, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	68, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	45, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 45, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	32, 13, 10, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 13, 32, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	65, 115, 10, 13, 58, 13, 13, 65, 
	69, 82, 101, 114, 10, 115, 86, 118, 
	69, 101, 13, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 45, 13, 45, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 45, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 0
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
	2, 2, 2, 1, 1, 2, 1, 1, 
	1, 2, 1, 2, 3, 1, 1, 1, 
	1, 2, 1, 2, 3, 1, 3, 3, 
	3, 3, 3, 3, 1, 2, 1, 2, 
	3, 2, 2, 2, 1, 3, 3, 3, 
	3, 3, 3, 1, 2, 1, 2, 3, 
	2, 2, 2, 2, 2, 2, 2, 1, 
	1, 1, 1, 2, 2, 2, 1, 1, 
	2, 2, 2, 2, 2, 2, 1, 1, 
	1, 1, 1, 1, 1, 2, 1, 2, 
	1, 1, 2, 1, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 1, 1, 2, 2, 
	2, 2, 2, 1, 2, 2, 2, 2, 
	2, 1, 2, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 2, 1, 1, 2, 1, 2, 1, 
	1, 2, 2, 2, 2, 2, 1, 1, 
	3, 1, 6, 1, 1, 2, 2, 0, 
	1, 2, 2, 2, 0
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
	0, 0, 0, 0, 0, 7, 7, 7, 
	7, 0, 0, 0, 7, 0, 7, 7, 
	7, 0, 0, 0, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 0, 0, 0, 
	7, 0, 0, 0, 7, 7, 7, 7, 
	7, 7, 7, 7, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 7, 7, 7, 0, 0, 0, 
	7, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	7, 7, 0, 0, 0, 7, 7, 7, 
	0, 0, 0, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 0, 0, 0, 7, 
	7, 0, 7, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 7, 7, 7
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
	204, 207, 210, 213, 215, 217, 227, 236, 
	245, 254, 257, 259, 262, 273, 275, 284, 
	293, 302, 305, 307, 310, 321, 330, 341, 
	352, 363, 374, 385, 396, 405, 408, 410, 
	413, 424, 427, 430, 433, 442, 453, 464, 
	475, 486, 497, 508, 517, 520, 522, 525, 
	536, 539, 542, 545, 548, 551, 554, 557, 
	559, 561, 563, 565, 568, 571, 574, 576, 
	578, 581, 584, 587, 590, 593, 596, 598, 
	600, 609, 611, 620, 629, 638, 641, 643, 
	646, 655, 664, 667, 669, 672, 675, 678, 
	681, 684, 687, 690, 693, 696, 699, 702, 
	705, 708, 711, 714, 717, 719, 721, 724, 
	734, 744, 754, 757, 759, 762, 772, 782, 
	792, 795, 797, 800, 811, 822, 833, 844, 
	855, 866, 877, 888, 899, 910, 921, 932, 
	943, 954, 964, 973, 982, 985, 987, 990, 
	999, 1008, 1011, 1021, 1024, 1027, 1037, 1039, 
	1041, 1045, 1047, 1054, 1056, 1058, 1061, 1064, 
	1065, 1074, 1077, 1087, 1097
]

class << self
	attr_accessor :_ami_protocol_parser_indicies
	private :_ami_protocol_parser_indicies, :_ami_protocol_parser_indicies=
end
self._ami_protocol_parser_indicies = [
	1, 0, 2, 0, 3, 0, 4, 0, 
	5, 0, 6, 0, 7, 0, 8, 0, 
	9, 0, 10, 0, 11, 0, 12, 0, 
	13, 0, 14, 0, 15, 0, 16, 0, 
	17, 0, 18, 0, 19, 0, 20, 0, 
	21, 0, 22, 23, 0, 24, 0, 25, 
	26, 0, 27, 0, 25, 26, 0, 22, 
	23, 0, 29, 30, 31, 28, 29, 30, 
	31, 28, 33, 31, 34, 33, 31, 35, 
	30, 31, 28, 33, 31, 36, 30, 31, 
	28, 38, 37, 39, 37, 40, 37, 41, 
	37, 42, 37, 43, 37, 44, 37, 45, 
	37, 46, 37, 47, 37, 48, 37, 49, 
	37, 50, 37, 51, 37, 52, 37, 53, 
	37, 54, 37, 55, 37, 56, 37, 57, 
	37, 58, 37, 59, 60, 37, 61, 37, 
	62, 63, 37, 64, 37, 62, 63, 37, 
	59, 60, 37, 65, 65, 37, 66, 66, 
	37, 67, 67, 37, 68, 37, 70, 71, 
	69, 73, 72, 74, 73, 72, 70, 71, 
	69, 75, 75, 37, 76, 76, 37, 77, 
	77, 37, 78, 78, 37, 79, 79, 37, 
	80, 80, 37, 81, 37, 82, 83, 84, 
	85, 86, 83, 84, 85, 86, 37, 82, 
	83, 84, 85, 86, 83, 84, 85, 86, 
	37, 87, 87, 37, 88, 88, 37, 89, 
	89, 37, 90, 90, 37, 91, 37, 92, 
	37, 95, 95, 93, 94, 93, 94, 93, 
	94, 93, 37, 98, 96, 97, 96, 97, 
	96, 97, 96, 37, 98, 96, 97, 96, 
	97, 96, 97, 96, 37, 98, 96, 97, 
	96, 97, 96, 97, 96, 37, 100, 101, 
	99, 103, 102, 104, 103, 102, 105, 108, 
	108, 106, 107, 106, 107, 106, 107, 106, 
	37, 109, 37, 112, 110, 111, 110, 111, 
	110, 111, 110, 37, 112, 110, 111, 110, 
	111, 110, 111, 110, 37, 112, 110, 111, 
	110, 111, 110, 111, 110, 37, 114, 115, 
	113, 117, 116, 118, 117, 116, 105, 108, 
	108, 106, 107, 106, 107, 106, 107, 106, 
	37, 112, 110, 111, 110, 111, 110, 111, 
	110, 37, 112, 119, 119, 110, 111, 110, 
	111, 110, 111, 110, 37, 112, 120, 120, 
	110, 111, 110, 111, 110, 111, 110, 37, 
	112, 121, 121, 110, 111, 110, 111, 110, 
	111, 110, 37, 112, 122, 122, 110, 111, 
	110, 111, 110, 111, 110, 37, 112, 123, 
	123, 110, 111, 110, 111, 110, 111, 110, 
	37, 112, 124, 124, 110, 111, 110, 111, 
	110, 111, 110, 37, 125, 110, 111, 110, 
	111, 110, 111, 110, 37, 127, 128, 126, 
	130, 129, 131, 130, 129, 105, 108, 108, 
	106, 107, 106, 107, 106, 107, 106, 37, 
	127, 128, 126, 114, 115, 113, 100, 101, 
	99, 98, 96, 97, 96, 97, 96, 97, 
	96, 37, 98, 132, 132, 96, 97, 96, 
	97, 96, 97, 96, 37, 98, 133, 133, 
	96, 97, 96, 97, 96, 97, 96, 37, 
	98, 134, 134, 96, 97, 96, 97, 96, 
	97, 96, 37, 98, 135, 135, 96, 97, 
	96, 97, 96, 97, 96, 37, 98, 136, 
	136, 96, 97, 96, 97, 96, 97, 96, 
	37, 98, 137, 137, 96, 97, 96, 97, 
	96, 97, 96, 37, 138, 96, 97, 96, 
	97, 96, 97, 96, 37, 140, 141, 139, 
	143, 142, 144, 143, 142, 105, 108, 108, 
	106, 107, 106, 107, 106, 107, 106, 37, 
	140, 141, 139, 145, 145, 37, 146, 146, 
	37, 147, 147, 37, 148, 148, 37, 149, 
	149, 37, 150, 150, 37, 151, 37, 152, 
	37, 153, 37, 154, 37, 155, 155, 37, 
	156, 156, 37, 157, 157, 37, 158, 37, 
	159, 37, 160, 160, 37, 161, 161, 37, 
	162, 162, 37, 163, 163, 37, 164, 164, 
	37, 165, 165, 37, 166, 37, 167, 37, 
	168, 170, 171, 170, 171, 170, 171, 170, 
	169, 172, 169, 175, 173, 174, 173, 174, 
	173, 174, 173, 169, 175, 173, 174, 173, 
	174, 173, 174, 173, 169, 175, 173, 174, 
	173, 174, 173, 174, 173, 169, 177, 178, 
	176, 180, 179, 181, 180, 179, 168, 170, 
	171, 170, 171, 170, 171, 170, 169, 175, 
	173, 174, 173, 174, 173, 174, 173, 169, 
	177, 178, 176, 184, 183, 185, 184, 183, 
	184, 186, 183, 184, 187, 183, 184, 188, 
	183, 184, 189, 183, 184, 190, 183, 184, 
	191, 183, 184, 192, 183, 184, 193, 183, 
	184, 194, 183, 184, 195, 183, 184, 196, 
	183, 184, 197, 183, 184, 198, 183, 184, 
	199, 183, 184, 200, 183, 201, 182, 202, 
	182, 203, 184, 183, 184, 206, 204, 205, 
	204, 205, 204, 205, 204, 183, 184, 206, 
	204, 205, 204, 205, 204, 205, 204, 183, 
	184, 206, 204, 205, 204, 205, 204, 205, 
	204, 183, 208, 209, 207, 211, 210, 212, 
	211, 210, 184, 216, 214, 215, 214, 215, 
	214, 215, 214, 183, 184, 216, 214, 215, 
	214, 215, 214, 215, 214, 183, 184, 216, 
	214, 215, 214, 215, 214, 215, 214, 183, 
	218, 219, 217, 221, 220, 222, 221, 220, 
	184, 223, 216, 214, 215, 214, 215, 214, 
	215, 214, 183, 184, 216, 224, 214, 215, 
	214, 215, 214, 215, 214, 183, 184, 216, 
	225, 214, 215, 214, 215, 214, 215, 214, 
	183, 184, 216, 226, 214, 215, 214, 215, 
	214, 215, 214, 183, 184, 227, 216, 214, 
	215, 214, 215, 214, 215, 214, 183, 184, 
	216, 228, 214, 215, 214, 215, 214, 215, 
	214, 183, 184, 216, 229, 214, 215, 214, 
	215, 214, 215, 214, 183, 184, 216, 230, 
	214, 215, 214, 215, 214, 215, 214, 183, 
	184, 216, 231, 214, 215, 214, 215, 214, 
	215, 214, 183, 184, 216, 232, 214, 215, 
	214, 215, 214, 215, 214, 183, 184, 216, 
	233, 214, 215, 214, 215, 214, 215, 214, 
	183, 184, 216, 234, 214, 215, 214, 215, 
	214, 215, 214, 183, 184, 235, 216, 214, 
	215, 214, 215, 214, 215, 214, 183, 184, 
	236, 216, 214, 215, 214, 215, 214, 215, 
	214, 183, 201, 239, 237, 238, 237, 238, 
	237, 238, 237, 213, 239, 237, 238, 237, 
	238, 237, 238, 237, 213, 239, 237, 238, 
	237, 238, 237, 238, 237, 213, 241, 242, 
	240, 244, 243, 245, 244, 243, 239, 237, 
	238, 237, 238, 237, 238, 237, 213, 239, 
	237, 238, 237, 238, 237, 238, 237, 213, 
	241, 242, 240, 184, 216, 214, 215, 214, 
	215, 214, 215, 214, 183, 218, 219, 217, 
	208, 209, 207, 184, 206, 204, 205, 204, 
	205, 204, 205, 204, 183, 247, 246, 249, 
	248, 251, 252, 251, 250, 33, 31, 255, 
	256, 257, 258, 257, 258, 254, 260, 259, 
	261, 259, 262, 262, 259, 263, 263, 259, 
	169, 265, 266, 267, 266, 267, 266, 267, 
	266, 264, 184, 186, 183, 184, 271, 270, 
	272, 270, 272, 270, 272, 270, 183, 184, 
	271, 270, 272, 270, 272, 270, 272, 270, 
	183, 273, 274, 273, 274, 273, 274, 273, 
	269, 0
]

class << self
	attr_accessor :_ami_protocol_parser_trans_targs
	private :_ami_protocol_parser_trans_targs, :_ami_protocol_parser_trans_targs=
end
self._ami_protocol_parser_trans_targs = [
	222, 2, 3, 4, 5, 6, 7, 8, 
	9, 10, 11, 12, 13, 14, 15, 16, 
	17, 18, 19, 20, 21, 22, 23, 27, 
	24, 25, 26, 222, 29, 225, 32, 30, 
	224, 31, 224, 224, 224, 226, 36, 37, 
	38, 39, 40, 41, 42, 43, 44, 45, 
	46, 47, 48, 49, 50, 51, 52, 53, 
	54, 55, 56, 57, 61, 58, 59, 60, 
	226, 63, 64, 65, 66, 67, 68, 69, 
	67, 68, 226, 71, 72, 73, 74, 75, 
	76, 77, 78, 79, 129, 139, 144, 80, 
	81, 82, 83, 84, 85, 86, 116, 117, 
	87, 88, 89, 90, 91, 115, 90, 91, 
	92, 93, 94, 101, 102, 226, 95, 96, 
	97, 98, 99, 114, 98, 99, 100, 103, 
	104, 105, 106, 107, 108, 109, 110, 111, 
	113, 110, 111, 112, 118, 119, 120, 121, 
	122, 123, 124, 125, 126, 128, 125, 126, 
	127, 130, 131, 132, 133, 134, 135, 136, 
	137, 138, 226, 140, 141, 142, 143, 226, 
	145, 146, 147, 148, 149, 150, 151, 226, 
	153, 0, 154, 161, 231, 155, 156, 157, 
	158, 159, 162, 158, 159, 160, 232, 163, 
	164, 165, 166, 167, 168, 169, 170, 171, 
	172, 173, 174, 175, 176, 177, 178, 179, 
	180, 181, 232, 233, 184, 185, 186, 187, 
	188, 220, 187, 188, 234, 232, 190, 191, 
	192, 193, 194, 219, 193, 194, 235, 196, 
	197, 198, 199, 200, 201, 202, 203, 204, 
	205, 206, 207, 208, 209, 210, 211, 212, 
	213, 214, 217, 213, 214, 236, 222, 223, 
	222, 1, 28, 33, 34, 224, 226, 227, 
	228, 229, 230, 226, 226, 35, 62, 70, 
	163, 182, 183, 221, 232, 232, 189, 195, 
	218, 215, 216
]

class << self
	attr_accessor :_ami_protocol_parser_trans_actions
	private :_ami_protocol_parser_trans_actions, :_ami_protocol_parser_trans_actions=
end
self._ami_protocol_parser_trans_actions = [
	43, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 5, 0, 0, 
	0, 7, 0, 37, 0, 130, 0, 0, 
	35, 0, 88, 125, 112, 55, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 5, 0, 0, 0, 7, 0, 
	45, 0, 0, 0, 0, 23, 94, 23, 
	0, 25, 103, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 3, 0, 9, 9, 9, 
	0, 0, 11, 13, 79, 13, 0, 15, 
	0, 0, 9, 9, 9, 73, 0, 0, 
	11, 13, 79, 13, 0, 15, 0, 0, 
	0, 0, 0, 0, 0, 11, 82, 120, 
	82, 0, 85, 0, 0, 0, 0, 0, 
	0, 0, 11, 82, 120, 82, 0, 85, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	67, 0, 47, 0, 0, 0, 1, 100, 
	0, 0, 0, 0, 0, 0, 1, 97, 
	0, 0, 9, 9, 70, 0, 0, 11, 
	13, 79, 13, 0, 15, 0, 65, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	21, 0, 57, 116, 0, 0, 11, 13, 
	79, 13, 0, 15, 109, 63, 0, 0, 
	11, 13, 79, 13, 0, 15, 109, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 21, 0, 0, 11, 
	13, 79, 13, 0, 15, 31, 39, 31, 
	41, 0, 91, 17, 91, 33, 51, 0, 
	31, 31, 31, 53, 49, 0, 0, 0, 
	19, 19, 76, 76, 61, 59, 9, 9, 
	9, 9, 9
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	27, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 27, 0, 
	106, 0, 27, 0, 0, 0, 0, 0, 
	106, 0, 0, 0, 0
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 29, 0, 
	29, 0, 29, 0, 0, 0, 0, 0, 
	29, 0, 0, 0, 0
]

class << self
	attr_accessor :_ami_protocol_parser_eof_trans
	private :_ami_protocol_parser_eof_trans, :_ami_protocol_parser_eof_trans=
end
self._ami_protocol_parser_eof_trans = [
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 0, 0, 33, 33, 
	0, 0, 0, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	38, 38, 38, 38, 38, 38, 38, 38, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 183, 183, 183, 183, 183, 
	183, 183, 183, 183, 183, 183, 183, 183, 
	183, 183, 183, 183, 183, 183, 0, 0, 
	0, 0, 0, 0, 0, 214, 214, 214, 
	214, 214, 214, 214, 214, 214, 214, 214, 
	214, 214, 214, 214, 214, 214, 214, 214, 
	214, 214, 214, 214, 214, 214, 214, 214, 
	214, 214, 214, 214, 0, 0, 0, 249, 
	0, 254, 0, 260, 260, 260, 260, 0, 
	0, 269, 270, 270, 270
]

class << self
	attr_accessor :ami_protocol_parser_start
end
self.ami_protocol_parser_start = 222;
class << self
	attr_accessor :ami_protocol_parser_first_final
end
self.ami_protocol_parser_first_final = 222;
class << self
	attr_accessor :ami_protocol_parser_error
end
self.ami_protocol_parser_error = 0;

class << self
	attr_accessor :ami_protocol_parser_en_irregularity
end
self.ami_protocol_parser_en_irregularity = 224;
class << self
	attr_accessor :ami_protocol_parser_en_main
end
self.ami_protocol_parser_en_main = 222;
class << self
	attr_accessor :ami_protocol_parser_en_protocol
end
self.ami_protocol_parser_en_protocol = 226;
class << self
	attr_accessor :ami_protocol_parser_en_success
end
self.ami_protocol_parser_en_success = 152;
class << self
	attr_accessor :ami_protocol_parser_en_response_follows
end
self.ami_protocol_parser_en_response_follows = 232;


# line 747 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rb"
begin
	     @current_pointer ||= 0
	    @data_ending_pointer ||=   @data.length
	    @current_state = ami_protocol_parser_start
	   @ragel_stack_top = 0
	    @token_start = nil
	    @token_end = nil
	   @ragel_act = 0
end
# line 79 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
##
            
          end
  
          def <<(new_data)
            extend_buffer_with new_data
            resume!
          end
        
          def resume!
            
# line 769 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rb"
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
			when 30 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_start =      @current_pointer
		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
# line 804 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rb"
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
	_trans = _ami_protocol_parser_indicies[_trans]
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
# line 17 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 init_success 		end
# line 17 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 1 then
# line 19 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 init_response_follows 		end
# line 19 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 2 then
# line 21 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 init_error 		end
# line 21 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 3 then
# line 23 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 message_received @current_message 		end
# line 23 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 4 then
# line 24 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
   error_received @current_message 		end
# line 24 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 5 then
# line 26 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 version_starts 		end
# line 26 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 6 then
# line 27 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 version_stops  		end
# line 27 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 7 then
# line 29 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 key_starts 		end
# line 29 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 8 then
# line 30 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 key_stops  		end
# line 30 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 9 then
# line 32 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 value_starts 		end
# line 32 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 10 then
# line 33 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 value_stops  		end
# line 33 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 11 then
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 error_reason_starts 		end
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 12 then
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 error_reason_stops  		end
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 13 then
# line 38 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 syntax_error_starts 		end
# line 38 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 14 then
# line 39 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 syntax_error_stops  		end
# line 39 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 15 then
# line 41 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 immediate_response_starts 		end
# line 41 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 16 then
# line 42 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 immediate_response_stops  		end
# line 42 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 17 then
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 follows_text_starts 		end
# line 44 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 18 then
# line 45 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 follows_text_stops  		end
# line 45 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 19 then
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 event_name_starts 		end
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 20 then
# line 48 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 event_name_stops  		end
# line 48 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 21 then
# line 34 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 	begin
		    @current_state = 152
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 34 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 22 then
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 	begin
		    @current_state = 152
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 35 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 23 then
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 	begin
		    @current_state = 152
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 36 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 24 then
# line 38 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 	begin
		    @current_state = 232
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 38 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 25 then
# line 43 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
	begin
		   @ragel_stack_top -= 1
		    @current_state =  @ragel_stack[   @ragel_stack_top]
		_trigger_goto = true
		_goto_level = _again
		break
	end
		end
# line 43 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 26 then
# line 78 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
	begin
		    @current_state = 226
		_trigger_goto = true
		_goto_level = _again
		break
	end
		end
# line 78 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 27 then
# line 84 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 message_received; 	begin
		    @current_state = 226
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 84 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 31 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 32 then
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
   @ragel_act = 1;		end
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 33 then
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 34 then
# line 48 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
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
# line 48 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 35 then
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1;		end
# line 47 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 36 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
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
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 37 then
# line 55 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
 begin  	begin
		    @current_state = 226
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 55 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 38 then
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
 begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
         @current_pointer =      @current_pointer - 1;
    	begin
		    @current_state = 226
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 39 then
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1; begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
         @current_pointer =      @current_pointer - 1;
    	begin
		    @current_state = 226
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 40 then
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 begin      @current_pointer = ((    @token_end))-1; end
 begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
         @current_pointer =      @current_pointer - 1;
    	begin
		    @current_state = 226
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 56 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 41 then
# line 64 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 64 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 42 then
# line 65 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 65 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 43 then
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 66 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 44 then
# line 67 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 67 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 45 then
# line 68 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 68 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 46 then
# line 69 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 69 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 47 then
# line 70 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
 begin  	begin
		    @current_state = 226
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 70 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 48 then
# line 71 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
 begin 
    # If NONE of the above patterns match, we consider this a syntax error. The irregularity machine can recover gracefully.
         @current_pointer =      @current_pointer - 1;
    	begin
		 @ragel_stack[   @ragel_stack_top] =     @current_state
		   @ragel_stack_top+= 1
		    @current_state = 224
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 71 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 49 then
# line 71 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1; begin 
    # If NONE of the above patterns match, we consider this a syntax error. The irregularity machine can recover gracefully.
         @current_pointer =      @current_pointer - 1;
    	begin
		 @ragel_stack[   @ragel_stack_top] =     @current_state
		   @ragel_stack_top+= 1
		    @current_state = 224
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 71 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 50 then
# line 71 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 begin      @current_pointer = ((    @token_end))-1; end
 begin 
    # If NONE of the above patterns match, we consider this a syntax error. The irregularity machine can recover gracefully.
         @current_pointer =      @current_pointer - 1;
    	begin
		 @ragel_stack[   @ragel_stack_top] =     @current_state
		   @ragel_stack_top+= 1
		    @current_state = 224
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 71 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 51 then
# line 82 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
   @ragel_act = 13;		end
# line 82 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 52 then
# line 84 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
   @ragel_act = 15;		end
# line 84 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 53 then
# line 83 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer+1
		end
# line 83 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 54 then
# line 82 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1;		end
# line 82 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 55 then
# line 84 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_end =      @current_pointer
     @current_pointer =      @current_pointer - 1;		end
# line 84 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 56 then
# line 82 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
 begin      @current_pointer = ((    @token_end))-1; end
		end
# line 82 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 57 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
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
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
# line 1331 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rb"
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
when 28 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
    @token_start = nil;		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
when 29 then
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
		begin
   @ragel_act = 0
		end
# line 1 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
# line 1358 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rb"
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
# line 89 "lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb"
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
          # @param [ManagerInterfaceResponse, ManagerInterfaceEvent] message The message just received
          #
          def message_received(message)
            raise NotImplementedError, "Must be implemented in subclass!"
          end

          ##
          # Called when there is an Error: stanza on the socket. Could be caused by executing an unrecognized command, trying
          # to originate into an invalid priority, etc. Note: many errors' responses are actually tightly coupled to a
          # ManagerInterfaceEvent which comes directly after it. Often the message will say something like "Channel status
          # will follow".
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
            @current_message = ManagerInterfaceResponse.new
          end
        
          def init_response_follows
            @current_message = ManagerInterfaceResponse.new
          end
          
          def init_error
            @current_message = ManagerInterfaceError.new()
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
            @current_message = ManagerInterfaceEvent.new(event_name)
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
            @current_message.message = @data[@error_reason_start...@current_pointer]
          end
          
          def follows_text_starts
            @follows_text_start = @current_pointer
          end
  
          def follows_text_stops
            text = @data[@last_seen_value_end..(@current_pointer - "\r\n--END COMMAND--".size)]
            @current_message.text_body = text
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
            message_received ManagerInterfaceResponse.from_immediate_response(message)
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
        class DelegatingAsteriskManagerInterfaceLexer < AbstractAsteriskManagerInterfaceStreamLexer
          
          def initialize(delegate, method_delegation_map=nil)
            super()
            @delegate = delegate
            
            @message_received_method = method_delegation_map && method_delegation_map.has_key?(:message_received) ?
                method_delegation_map[:message_received] : :message_received
            
            @error_received_method = method_delegation_map && method_delegation_map.has_key?(:error_received) ?
                method_delegation_map[:error_received] : :error_received
            
            @syntax_error_method = method_delegation_map && method_delegation_map.has_key?(:syntax_error_encountered) ?
                method_delegation_map[:syntax_error_encountered] : :syntax_error_encountered
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