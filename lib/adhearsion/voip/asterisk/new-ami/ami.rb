# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# -*- ruby -*-
require File.join(File.dirname(__FILE__), 'packets.rb')

module Adhearsion
  module VoIP
    module Asterisk
      class AbstractAsteriskManagerInterfaceStreamParser

        BUFFER_SIZE = 8.kilobytes unless defined? BUFFER_SIZE

        CAPTURED_VARIABLES = {} unless defined? CAPTURED_VARIABLES
        CAPTURE_CALLBACKS  = {} unless defined? CAPTURE_CALLBACKS

        # line 67 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
 # %

        attr_accessor :ami_version
        def initialize
    
          @data = ""
          @current_pointer = 0
          
# line 25 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
class << self
	attr_accessor :_ami_protocol_parser_actions
	private :_ami_protocol_parser_actions, :_ami_protocol_parser_actions=
end
self._ami_protocol_parser_actions = [
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 6, 1, 
	9, 1, 10, 1, 11, 1, 12, 1, 
	13, 1, 14, 1, 15, 1, 16, 1, 
	17, 1, 18, 1, 21, 1, 24, 1, 
	26, 1, 27, 1, 28, 1, 29, 1, 
	30, 1, 31, 1, 32, 1, 33, 1, 
	35, 1, 36, 1, 37, 1, 38, 1, 
	39, 1, 42, 1, 43, 1, 44, 1, 
	45, 1, 46, 2, 2, 14, 2, 3, 
	4, 2, 4, 5, 2, 7, 34, 2, 
	8, 22, 2, 16, 17, 2, 19, 33, 
	2, 20, 33, 2, 24, 25, 2, 27, 
	40, 3, 27, 23, 41
]

class << self
	attr_accessor :_ami_protocol_parser_key_offsets
	private :_ami_protocol_parser_key_offsets, :_ami_protocol_parser_key_offsets=
end
self._ami_protocol_parser_key_offsets = [
	0, 0, 1, 2, 3, 4, 5, 6, 
	7, 8, 9, 10, 11, 12, 13, 14, 
	15, 16, 17, 18, 19, 20, 22, 25, 
	27, 30, 31, 34, 37, 39, 41, 43, 
	45, 47, 48, 49, 50, 51, 52, 53, 
	54, 55, 56, 57, 58, 59, 60, 61, 
	62, 63, 64, 65, 66, 67, 69, 72, 
	74, 77, 78, 81, 84, 86, 88, 90, 
	91, 93, 94, 96, 98, 100, 102, 104, 
	106, 108, 110, 111, 119, 127, 129, 131, 
	133, 135, 136, 137, 139, 141, 143, 145, 
	147, 149, 151, 152, 154, 155, 157, 158, 
	159, 161, 162, 163, 164, 165, 166, 167, 
	168, 169, 170, 171, 173, 175, 177, 178, 
	179, 181, 183, 185, 187, 189, 191, 192, 
	193, 194, 195, 197, 198, 200, 215, 216, 
	231, 246, 261, 278, 279, 281, 296, 311, 
	328, 344, 360, 377, 378, 380, 382, 384, 
	386, 388, 390, 392, 394, 396, 398, 400, 
	402, 404, 406, 408, 410, 411, 412, 414, 
	430, 446, 462, 479, 480, 482, 498, 514, 
	530, 547, 548, 550, 567, 584, 601, 618, 
	635, 652, 669, 686, 703, 720, 737, 754, 
	771, 788, 804, 819, 834, 851, 852, 854, 
	869, 884, 901, 917, 933, 950, 966, 983, 
	999, 1015, 1032, 1049, 1065, 1081, 1098, 1114, 
	1115, 1116, 1116, 1122, 1123, 1124, 1126, 1128, 
	1129, 1129, 1144, 1146, 1162, 1178
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
	48, 57, 46, 48, 57, 10, 13, 10, 
	13, 10, 13, 10, 13, 10, 13, 116, 
	101, 114, 105, 115, 107, 32, 67, 97, 
	108, 108, 32, 77, 97, 110, 97, 103, 
	101, 114, 47, 48, 57, 46, 48, 57, 
	48, 57, 13, 48, 57, 10, 13, 48, 
	57, 46, 48, 57, 69, 101, 78, 110, 
	84, 116, 58, 13, 32, 13, 10, 13, 
	13, 32, 83, 115, 80, 112, 79, 111, 
	78, 110, 83, 115, 69, 101, 58, 32, 
	69, 70, 80, 83, 101, 112, 115, 32, 
	69, 70, 80, 83, 101, 112, 115, 82, 
	114, 82, 114, 79, 111, 82, 114, 13, 
	10, 77, 109, 69, 101, 83, 115, 83, 
	115, 65, 97, 71, 103, 69, 101, 58, 
	13, 32, 13, 10, 13, 13, 10, 13, 
	32, 111, 108, 108, 111, 119, 115, 13, 
	10, 13, 10, 79, 111, 78, 110, 71, 
	103, 13, 10, 85, 117, 67, 99, 67, 
	99, 69, 101, 83, 115, 83, 115, 13, 
	10, 13, 13, 10, 13, 13, 10, 13, 
	13, 32, 47, 48, 57, 58, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 10, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 10, 
	13, 13, 32, 47, 48, 57, 58, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 32, 58, 33, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 10, 13, 13, 45, 13, 45, 
	13, 69, 13, 78, 13, 68, 13, 32, 
	13, 67, 13, 79, 13, 77, 13, 77, 
	13, 65, 13, 78, 13, 68, 13, 45, 
	13, 45, 13, 10, 10, 13, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	10, 13, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 58, 33, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 10, 13, 13, 45, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 69, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 78, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 68, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 58, 33, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 67, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 79, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 77, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	77, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 65, 32, 47, 48, 57, 59, 64, 
	66, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 78, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 68, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 45, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 45, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 58, 33, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 10, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 58, 33, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
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
	13, 32, 58, 33, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 65, 115, 13, 65, 69, 82, 
	101, 114, 10, 115, 86, 118, 69, 101, 
	13, 13, 32, 47, 48, 57, 58, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 45, 13, 45, 32, 47, 48, 57, 
	58, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 45, 32, 47, 48, 57, 
	58, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 32, 47, 48, 57, 58, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	0
]

class << self
	attr_accessor :_ami_protocol_parser_single_lengths
	private :_ami_protocol_parser_single_lengths, :_ami_protocol_parser_single_lengths=
end
self._ami_protocol_parser_single_lengths = [
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 0, 1, 0, 
	1, 1, 1, 1, 2, 2, 2, 2, 
	2, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 0, 1, 0, 
	1, 1, 1, 1, 2, 2, 2, 1, 
	2, 1, 2, 2, 2, 2, 2, 2, 
	2, 2, 1, 8, 8, 2, 2, 2, 
	2, 1, 1, 2, 2, 2, 2, 2, 
	2, 2, 1, 2, 1, 2, 1, 1, 
	2, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 2, 2, 2, 1, 1, 
	2, 2, 2, 2, 2, 2, 1, 1, 
	1, 1, 2, 1, 2, 1, 1, 1, 
	1, 1, 3, 1, 2, 1, 1, 3, 
	2, 2, 3, 1, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 1, 1, 2, 2, 
	2, 2, 3, 1, 2, 2, 2, 2, 
	3, 1, 2, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 2, 1, 1, 3, 1, 2, 1, 
	1, 3, 2, 2, 3, 2, 3, 2, 
	2, 3, 3, 2, 2, 3, 2, 1, 
	1, 0, 6, 1, 1, 2, 2, 1, 
	0, 1, 2, 2, 2, 0
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
	0, 0, 0, 0, 0, 1, 1, 1, 
	1, 0, 1, 1, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 7, 
	7, 7, 7, 0, 0, 7, 7, 7, 
	7, 7, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	7, 7, 7, 0, 0, 7, 7, 7, 
	7, 0, 0, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 0, 0, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 7, 7, 7
]

class << self
	attr_accessor :_ami_protocol_parser_index_offsets
	private :_ami_protocol_parser_index_offsets, :_ami_protocol_parser_index_offsets=
end
self._ami_protocol_parser_index_offsets = [
	0, 0, 2, 4, 6, 8, 10, 12, 
	14, 16, 18, 20, 22, 24, 26, 28, 
	30, 32, 34, 36, 38, 40, 42, 45, 
	47, 50, 52, 55, 58, 61, 64, 67, 
	70, 73, 75, 77, 79, 81, 83, 85, 
	87, 89, 91, 93, 95, 97, 99, 101, 
	103, 105, 107, 109, 111, 113, 115, 118, 
	120, 123, 125, 128, 131, 134, 137, 140, 
	142, 145, 147, 150, 153, 156, 159, 162, 
	165, 168, 171, 173, 182, 191, 194, 197, 
	200, 203, 205, 207, 210, 213, 216, 219, 
	222, 225, 228, 230, 233, 235, 238, 240, 
	242, 245, 247, 249, 251, 253, 255, 257, 
	259, 261, 263, 265, 268, 271, 274, 276, 
	278, 281, 284, 287, 290, 293, 296, 298, 
	300, 302, 304, 307, 309, 312, 321, 323, 
	332, 341, 350, 361, 363, 366, 375, 384, 
	395, 405, 415, 426, 428, 431, 434, 437, 
	440, 443, 446, 449, 452, 455, 458, 461, 
	464, 467, 470, 473, 476, 478, 480, 483, 
	493, 503, 513, 524, 526, 529, 539, 549, 
	559, 570, 572, 575, 586, 597, 608, 619, 
	630, 641, 652, 663, 674, 685, 696, 707, 
	718, 729, 739, 748, 757, 768, 770, 773, 
	782, 791, 802, 812, 822, 833, 843, 854, 
	864, 874, 885, 896, 906, 916, 927, 937, 
	939, 941, 942, 949, 951, 953, 956, 959, 
	961, 962, 971, 974, 984, 994
]

class << self
	attr_accessor :_ami_protocol_parser_trans_targs
	private :_ami_protocol_parser_trans_targs, :_ami_protocol_parser_trans_targs=
end
self._ami_protocol_parser_trans_targs = [
	2, 207, 3, 207, 4, 207, 5, 207, 
	6, 207, 7, 207, 8, 207, 9, 207, 
	10, 207, 11, 207, 12, 207, 13, 207, 
	14, 207, 15, 207, 16, 207, 17, 207, 
	18, 207, 19, 207, 20, 207, 21, 207, 
	22, 207, 23, 27, 207, 24, 207, 25, 
	26, 207, 207, 207, 25, 26, 207, 23, 
	27, 207, 0, 32, 29, 0, 31, 30, 
	0, 31, 30, 209, 31, 30, 0, 31, 
	30, 34, 210, 35, 210, 36, 210, 37, 
	210, 38, 210, 39, 210, 40, 210, 41, 
	210, 42, 210, 43, 210, 44, 210, 45, 
	210, 46, 210, 47, 210, 48, 210, 49, 
	210, 50, 210, 51, 210, 52, 210, 53, 
	210, 54, 210, 55, 59, 210, 56, 210, 
	57, 58, 210, 210, 210, 57, 58, 210, 
	55, 59, 210, 61, 61, 210, 62, 62, 
	210, 63, 63, 210, 64, 210, 66, 67, 
	65, 66, 65, 210, 66, 65, 66, 67, 
	65, 69, 69, 210, 70, 70, 210, 71, 
	71, 210, 72, 72, 210, 73, 73, 210, 
	74, 74, 210, 75, 210, 76, 77, 97, 
	107, 112, 77, 107, 112, 210, 76, 77, 
	97, 107, 112, 77, 107, 112, 210, 78, 
	78, 210, 79, 79, 210, 80, 80, 210, 
	81, 81, 210, 82, 210, 83, 210, 84, 
	84, 210, 85, 85, 210, 86, 86, 210, 
	87, 87, 210, 88, 88, 210, 89, 89, 
	210, 90, 90, 210, 91, 210, 93, 96, 
	92, 93, 92, 94, 93, 92, 95, 210, 
	210, 210, 93, 96, 92, 98, 210, 99, 
	210, 100, 210, 101, 210, 102, 210, 103, 
	210, 104, 210, 105, 210, 106, 210, 210, 
	210, 108, 108, 210, 109, 109, 210, 110, 
	110, 210, 111, 210, 210, 210, 113, 113, 
	210, 114, 114, 210, 115, 115, 210, 116, 
	116, 210, 117, 117, 210, 118, 118, 210, 
	119, 210, 210, 210, 122, 121, 122, 121, 
	123, 122, 121, 124, 121, 215, 122, 121, 
	126, 127, 134, 127, 134, 127, 134, 127, 
	0, 216, 0, 130, 128, 129, 128, 129, 
	128, 129, 128, 0, 130, 128, 129, 128, 
	129, 128, 129, 128, 0, 130, 128, 129, 
	128, 129, 128, 129, 128, 0, 132, 135, 
	138, 136, 137, 136, 137, 136, 137, 136, 
	131, 132, 131, 133, 132, 131, 126, 127, 
	134, 127, 134, 127, 134, 127, 0, 130, 
	128, 129, 128, 129, 128, 129, 128, 0, 
	132, 135, 138, 136, 137, 136, 137, 136, 
	137, 136, 131, 132, 138, 136, 137, 136, 
	137, 136, 137, 136, 131, 132, 138, 136, 
	137, 136, 137, 136, 137, 136, 131, 132, 
	135, 138, 136, 137, 136, 137, 136, 137, 
	136, 131, 140, 139, 141, 140, 139, 140, 
	142, 139, 140, 143, 139, 140, 144, 139, 
	140, 145, 139, 140, 146, 139, 140, 147, 
	139, 140, 148, 139, 140, 149, 139, 140, 
	150, 139, 140, 151, 139, 140, 152, 139, 
	140, 153, 139, 140, 154, 139, 140, 155, 
	139, 140, 156, 139, 157, 217, 217, 217, 
	218, 140, 139, 140, 162, 160, 161, 160, 
	161, 160, 161, 160, 139, 140, 162, 160, 
	161, 160, 161, 160, 161, 160, 139, 140, 
	162, 160, 161, 160, 161, 160, 161, 160, 
	139, 164, 202, 205, 203, 204, 203, 204, 
	203, 204, 203, 163, 164, 163, 219, 164, 
	163, 140, 168, 166, 167, 166, 167, 166, 
	167, 166, 139, 140, 168, 166, 167, 166, 
	167, 166, 167, 166, 139, 140, 168, 166, 
	167, 166, 167, 166, 167, 166, 139, 170, 
	198, 201, 199, 200, 199, 200, 199, 200, 
	199, 169, 170, 169, 220, 170, 169, 140, 
	172, 168, 166, 167, 166, 167, 166, 167, 
	166, 139, 140, 168, 173, 166, 167, 166, 
	167, 166, 167, 166, 139, 140, 168, 174, 
	166, 167, 166, 167, 166, 167, 166, 139, 
	140, 168, 175, 166, 167, 166, 167, 166, 
	167, 166, 139, 140, 176, 168, 166, 167, 
	166, 167, 166, 167, 166, 139, 140, 168, 
	177, 166, 167, 166, 167, 166, 167, 166, 
	139, 140, 168, 178, 166, 167, 166, 167, 
	166, 167, 166, 139, 140, 168, 179, 166, 
	167, 166, 167, 166, 167, 166, 139, 140, 
	168, 180, 166, 167, 166, 167, 166, 167, 
	166, 139, 140, 168, 181, 166, 167, 166, 
	167, 166, 167, 166, 139, 140, 168, 182, 
	166, 167, 166, 167, 166, 167, 166, 139, 
	140, 168, 183, 166, 167, 166, 167, 166, 
	167, 166, 139, 140, 184, 168, 166, 167, 
	166, 167, 166, 167, 166, 139, 140, 185, 
	168, 166, 167, 166, 167, 166, 167, 166, 
	139, 157, 188, 186, 187, 186, 187, 186, 
	187, 186, 217, 188, 186, 187, 186, 187, 
	186, 187, 186, 217, 188, 186, 187, 186, 
	187, 186, 187, 186, 217, 190, 193, 196, 
	194, 195, 194, 195, 194, 195, 194, 189, 
	190, 189, 221, 190, 189, 188, 186, 187, 
	186, 187, 186, 187, 186, 217, 188, 186, 
	187, 186, 187, 186, 187, 186, 217, 190, 
	193, 196, 194, 195, 194, 195, 194, 195, 
	194, 189, 190, 196, 194, 195, 194, 195, 
	194, 195, 194, 189, 190, 196, 194, 195, 
	194, 195, 194, 195, 194, 189, 190, 193, 
	196, 194, 195, 194, 195, 194, 195, 194, 
	189, 140, 168, 166, 167, 166, 167, 166, 
	167, 166, 139, 170, 198, 201, 199, 200, 
	199, 200, 199, 200, 199, 169, 170, 201, 
	199, 200, 199, 200, 199, 200, 199, 169, 
	170, 201, 199, 200, 199, 200, 199, 200, 
	199, 169, 170, 198, 201, 199, 200, 199, 
	200, 199, 200, 199, 169, 164, 202, 205, 
	203, 204, 203, 204, 203, 204, 203, 163, 
	164, 205, 203, 204, 203, 204, 203, 204, 
	203, 163, 164, 205, 203, 204, 203, 204, 
	203, 204, 203, 163, 164, 202, 205, 203, 
	204, 203, 204, 203, 204, 203, 163, 140, 
	162, 160, 161, 160, 161, 160, 161, 160, 
	139, 208, 207, 1, 207, 0, 211, 212, 
	213, 214, 213, 214, 210, 210, 210, 33, 
	210, 60, 60, 210, 68, 68, 210, 124, 
	121, 0, 158, 159, 206, 159, 206, 159, 
	206, 159, 139, 140, 142, 139, 140, 171, 
	165, 197, 165, 197, 165, 197, 165, 139, 
	140, 171, 165, 197, 165, 197, 165, 197, 
	165, 139, 191, 192, 191, 192, 191, 192, 
	191, 217, 207, 207, 207, 207, 207, 207, 
	207, 207, 207, 207, 207, 207, 207, 207, 
	207, 207, 207, 207, 207, 207, 207, 207, 
	207, 207, 207, 207, 207, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 210, 210, 210, 210, 
	210, 210, 210, 210, 217, 217, 217, 217, 
	217, 217, 217, 217, 217, 217, 217, 217, 
	217, 217, 217, 217, 217, 217, 217, 217, 
	217, 217, 217, 217, 217, 217, 217, 217, 
	217, 217, 217, 217, 217, 217, 217, 217, 
	217, 217, 217, 217, 217, 217, 217, 217, 
	217, 217, 217, 217, 217, 217, 217, 217, 
	217, 217, 217, 217, 207, 210, 210, 210, 
	210, 217, 217, 217, 217, 0
]

class << self
	attr_accessor :_ami_protocol_parser_trans_actions
	private :_ami_protocol_parser_trans_actions, :_ami_protocol_parser_trans_actions=
end
self._ami_protocol_parser_trans_actions = [
	0, 49, 0, 49, 0, 49, 0, 49, 
	0, 49, 0, 49, 0, 49, 0, 49, 
	0, 49, 0, 49, 0, 49, 0, 49, 
	0, 49, 0, 49, 0, 49, 0, 49, 
	0, 49, 0, 49, 0, 49, 0, 49, 
	1, 49, 0, 0, 49, 0, 49, 3, 
	0, 49, 43, 49, 3, 0, 49, 0, 
	0, 49, 0, 19, 19, 0, 21, 0, 
	0, 21, 0, 35, 21, 0, 0, 21, 
	0, 0, 63, 0, 63, 0, 63, 0, 
	63, 0, 63, 0, 63, 0, 63, 0, 
	63, 0, 63, 0, 63, 0, 63, 0, 
	63, 0, 63, 0, 63, 0, 63, 0, 
	63, 0, 63, 0, 63, 0, 63, 0, 
	63, 1, 63, 0, 0, 63, 0, 63, 
	3, 0, 63, 51, 63, 3, 0, 63, 
	0, 0, 63, 0, 0, 63, 0, 0, 
	63, 0, 0, 63, 0, 63, 90, 29, 
	29, 31, 0, 53, 31, 0, 90, 29, 
	29, 0, 0, 63, 0, 0, 63, 0, 
	0, 63, 0, 0, 63, 0, 0, 63, 
	0, 0, 63, 0, 63, 0, 0, 0, 
	0, 0, 0, 0, 0, 63, 0, 0, 
	0, 0, 0, 0, 0, 0, 63, 0, 
	0, 63, 0, 0, 63, 0, 0, 63, 
	0, 0, 63, 0, 63, 0, 63, 0, 
	0, 63, 0, 0, 63, 0, 0, 63, 
	0, 0, 63, 0, 0, 63, 0, 0, 
	63, 0, 0, 63, 0, 63, 13, 13, 
	13, 0, 0, 0, 0, 0, 0, 63, 
	84, 63, 13, 13, 13, 0, 63, 0, 
	63, 0, 63, 0, 63, 0, 63, 0, 
	63, 0, 63, 33, 63, 0, 63, 55, 
	63, 0, 0, 63, 0, 0, 63, 0, 
	0, 63, 23, 63, 96, 63, 0, 0, 
	63, 0, 0, 63, 0, 0, 63, 0, 
	0, 63, 0, 0, 63, 0, 0, 63, 
	23, 63, 93, 63, 15, 15, 0, 0, 
	0, 0, 0, 0, 0, 17, 0, 0, 
	0, 5, 5, 5, 5, 5, 5, 5, 
	0, 87, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 81, 9, 
	78, 9, 9, 9, 9, 9, 9, 9, 
	9, 11, 0, 0, 11, 0, 0, 5, 
	5, 5, 5, 5, 5, 5, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	81, 9, 78, 9, 9, 9, 9, 9, 
	9, 9, 9, 11, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 11, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 81, 
	9, 78, 9, 9, 9, 9, 9, 9, 
	9, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 27, 0, 0, 73, 65, 73, 
	105, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 81, 9, 78, 9, 9, 9, 9, 
	9, 9, 9, 9, 11, 0, 102, 11, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 81, 
	9, 78, 9, 9, 9, 9, 9, 9, 
	9, 9, 11, 0, 102, 11, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 27, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 71, 7, 0, 0, 0, 0, 
	0, 0, 0, 71, 7, 0, 0, 0, 
	0, 0, 0, 0, 71, 81, 9, 78, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	11, 0, 41, 11, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 71, 7, 0, 
	0, 0, 0, 0, 0, 0, 71, 81, 
	9, 78, 9, 9, 9, 9, 9, 9, 
	9, 9, 11, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 11, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 81, 9, 
	78, 9, 9, 9, 9, 9, 9, 9, 
	9, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 81, 9, 78, 9, 9, 
	9, 9, 9, 9, 9, 9, 11, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	11, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 81, 9, 78, 9, 9, 9, 
	9, 9, 9, 9, 9, 81, 9, 78, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	11, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 11, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 81, 9, 78, 9, 
	9, 9, 9, 9, 9, 9, 9, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 41, 45, 0, 47, 0, 0, 41, 
	41, 41, 41, 41, 59, 57, 61, 0, 
	61, 0, 0, 61, 0, 0, 61, 0, 
	0, 0, 25, 75, 75, 75, 75, 75, 
	75, 75, 25, 0, 0, 0, 0, 5, 
	5, 5, 5, 5, 5, 5, 5, 0, 
	0, 5, 5, 5, 5, 5, 5, 5, 
	5, 0, 5, 5, 5, 5, 5, 5, 
	5, 67, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 63, 63, 63, 63, 
	63, 63, 63, 63, 73, 73, 73, 73, 
	73, 73, 73, 73, 73, 73, 73, 73, 
	73, 73, 73, 73, 73, 73, 73, 71, 
	71, 71, 71, 71, 71, 71, 71, 71, 
	71, 71, 71, 71, 71, 71, 71, 71, 
	71, 71, 71, 71, 71, 71, 71, 71, 
	71, 71, 71, 71, 71, 71, 71, 71, 
	71, 71, 71, 71, 47, 61, 61, 61, 
	61, 69, 67, 67, 67, 0
]

class << self
	attr_accessor :_ami_protocol_parser_to_state_actions
	private :_ami_protocol_parser_to_state_actions, :_ami_protocol_parser_to_state_actions=
end
self._ami_protocol_parser_to_state_actions = [
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 37, 0, 0, 0, 
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
	37, 0, 0, 0, 0, 37, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 37, 
	0, 0, 37, 0, 0, 0, 0, 0, 
	0, 99, 0, 0, 0, 0
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
	0, 0, 0, 0, 0, 0, 0, 39, 
	0, 0, 39, 0, 0, 0, 0, 0, 
	0, 39, 0, 0, 0, 0
]

class << self
	attr_accessor :_ami_protocol_parser_eof_trans
	private :_ami_protocol_parser_eof_trans, :_ami_protocol_parser_eof_trans=
end
self._ami_protocol_parser_eof_trans = [
	0, 1029, 1029, 1029, 1029, 1029, 1029, 1029, 
	1029, 1029, 1029, 1029, 1029, 1029, 1029, 1029, 
	1029, 1029, 1029, 1029, 1029, 1029, 1029, 1029, 
	1029, 1029, 1029, 1029, 0, 0, 0, 0, 
	0, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 1135, 1135, 1135, 1135, 1135, 
	1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 
	1135, 1135, 1135, 1135, 1135, 1135, 0, 0, 
	0, 0, 0, 0, 0, 1172, 1172, 1172, 
	1172, 1172, 1172, 1172, 1172, 1172, 1172, 1172, 
	1172, 1172, 1172, 1172, 1172, 1172, 1172, 1172, 
	1172, 1172, 1172, 1172, 1172, 1172, 1172, 1172, 
	1172, 1172, 1172, 1172, 1172, 1172, 1172, 1172, 
	1172, 1172, 0, 0, 0, 0, 0, 0, 
	1173, 0, 0, 1177, 1177, 1177, 1177, 0, 
	0, 0, 1178, 1181, 1181, 1181
]

class << self
	attr_accessor :ami_protocol_parser_start
end
self.ami_protocol_parser_start = 207;
class << self
	attr_accessor :ami_protocol_parser_error
end
self.ami_protocol_parser_error = 0;

class << self
	attr_accessor :ami_protocol_parser_en_immediate_response
end
self.ami_protocol_parser_en_immediate_response = 28;
class << self
	attr_accessor :ami_protocol_parser_en_main
end
self.ami_protocol_parser_en_main = 207;
class << self
	attr_accessor :ami_protocol_parser_en_protocol
end
self.ami_protocol_parser_en_protocol = 210;
class << self
	attr_accessor :ami_protocol_parser_en_error_recovery
end
self.ami_protocol_parser_en_error_recovery = 120;
class << self
	attr_accessor :ami_protocol_parser_en_success
end
self.ami_protocol_parser_en_success = 125;
class << self
	attr_accessor :ami_protocol_parser_en_response_follows
end
self.ami_protocol_parser_en_response_follows = 217;


# line 794 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
begin
	 @current_pointer ||= 0
	 @data_ending_pointer ||=  @data.length
	 @current_state = ami_protocol_parser_start
	 @token_start = nil
	 @token_end = nil
	 @ragel_act = 0
end
# line 90 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"

        end
  
        def <<(new_data)
          if new_data.size + @data.size > BUFFER_SIZE
            @data.slice! 0...new_data.size
            @current_pointer = @data.size
          end
          @data << new_data
          @data_ending_pointer = @data.size
          resume!
        end
  
        def resume!
          
# line 819 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
			when 26 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_start =  @current_pointer
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 854 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
# line 19 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 open_version 		end
# line 19 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 1 then
# line 20 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 close_version 		end
# line 20 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 2 then
# line 22 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin_capturing_key  		end
# line 22 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 3 then
# line 23 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 finish_capturing_key 		end
# line 23 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 4 then
# line 25 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin_capturing_value  		end
# line 25 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 5 then
# line 26 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 finish_capturing_value 		end
# line 26 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 6 then
# line 28 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 error_reason_start 		end
# line 28 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 7 then
# line 29 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 error_reason_end; 	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 29 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 8 then
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 message_received @current_message 		end
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 9 then
# line 33 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 start_ignoring_syntax_error; 		end
# line 33 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 10 then
# line 34 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

            end_ignoring_syntax_error;
            	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end

          		end
# line 34 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 11 then
# line 39 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

            start_capturing_immediate_response;
          		end
# line 39 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 12 then
# line 43 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

            finish_capturing_immediate_response;
          		end
# line 43 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 13 then
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

            @current_message = NormalAmiResponse.new
          		end
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 14 then
# line 52 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 start_capturing_follows_text 		end
# line 52 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 15 then
# line 53 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

            end_capturing_follows_text;
          		end
# line 53 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 16 then
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin_capturing_event_name 		end
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 17 then
# line 58 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 init_event 		end
# line 58 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 18 then
# line 60 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

            @current_message = NormalAmiResponse.new(true)
            	begin
		 @current_state = 217
		_trigger_goto = true
		_goto_level = _again
		break
	end

          		end
# line 60 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 19 then
# line 30 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 	begin
		 @current_state = 125
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 30 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 20 then
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 	begin
		 @current_state = 125
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 21 then
# line 40 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 40 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 22 then
# line 69 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 69 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 23 then
# line 75 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 message_received; 	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 75 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 27 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 28 then
# line 46 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
 begin  	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 46 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 29 then
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
 begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 30 then
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1; begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 31 then
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin  @current_pointer = (( @token_end))-1; end
 begin 
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 32 then
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 33 then
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
 begin  message_received @current_message  end
		end
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 34 then
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 35 then
# line 58 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 58 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 36 then
# line 59 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
 begin  	begin
		 @current_state = 210
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 59 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 37 then
# line 60 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
 begin 
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 28
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 60 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 38 then
# line 60 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1; begin 
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 28
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 60 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 39 then
# line 60 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin  @current_pointer = (( @token_end))-1; end
 begin 
     @current_pointer =  @current_pointer - 1;
    	begin
		 @current_state = 28
		_trigger_goto = true
		_goto_level = _again
		break
	end

   end
		end
# line 60 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 40 then
# line 73 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 9;		end
# line 73 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 41 then
# line 75 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 11;		end
# line 75 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 42 then
# line 74 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 74 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 43 then
# line 73 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 73 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 44 then
# line 75 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 75 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 45 then
# line 73 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin  @current_pointer = (( @token_end))-1; end
		end
# line 73 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 46 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
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
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 1310 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
when 24 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_start = nil;		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 25 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 0
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 1337 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
# line 104 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"

        end
  
        protected
  
        def open_version
          @start_of_version = @current_pointer
        end
  
        def close_version
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
  
        def begin_capturing_event_name
          @event_name_start = @current_pointer
        end
  
        def init_event
          event_name = @data[@event_name_start]
          @event_name_start = nil
          @current_message = Event.new(event_name)
        end
  
        ##
        # Called after a message has been successfully parsed.
        #
        # @param [NormalAmiResponse, ImmediateResponse] message The message just received
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
        def ami_error!(reason)
          raise NotImplementedError, "Must be implemented in subclass!"
        end
        
        ##
        # Called when there's a syntax error on the socket. This doesn't happen as often as it should because, in many cases,
        # it's impossible to distinguish between a syntax error and an immediate packet.
        #
        # @param [String] ignored_chunk The offending text which caused the syntax error.
        def syntax_error!(ignored_chunk)
          raise NotImplementedError, "Must be implemented in subclass!"
        end

        def begin_capturing_key
          @current_key_position = @current_pointer
        end
  
        def finish_capturing_key
          @current_key = @data[@current_key_position...@current_pointer]
        end
  
        def begin_capturing_value
          @current_value_position = @current_pointer
        end
  
        def finish_capturing_value
          @current_value = @data[@current_value_position...@current_pointer]
          @last_seen_value_end = @current_pointer + 2 # 2 for \r\n
          add_pair_to_current_message
        end
  
        def error_reason_start
          @error_reason_start = @current_pointer
        end
  
        def error_reason_end
          ami_error! @data[@error_reason_start...@current_pointer - 3]
          @error_reason_start = nil
        end
  
        def start_capturing_follows_text
          @follows_text_start = @current_pointer
        end
  
        def end_capturing_follows_text
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
  
        def start_ignoring_syntax_error
          @current_syntax_error_start = @current_pointer # Adding 1 since the pointer is still set to the last successful match
        end
  
        def end_ignoring_syntax_error
          # Subtracting 3 from @current_pointer below for "\r\n\r" which separates a stanza
          offending_data = @data[@current_syntax_error_start...@current_pointer - 3]
          syntax_error! offending_data
          @current_syntax_error_start = nil
        end
  
        def start_capturing_immediate_response
          @immediate_response_start = @current_pointer
        end
  
        def finish_capturing_immediate_response
          message = @data[@immediate_response_start...@current_pointer]
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