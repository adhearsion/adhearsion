# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# -*- ruby -*-
require 'rubygems'
require 'active_support'

require File.join(File.dirname(__FILE__), 'packets.rb')

class AmiStreamParser

  BUFFER_SIZE = 8.kilobytes unless defined? BUFFER_SIZE

  CAPTURED_VARIABLES = {} unless defined? CAPTURED_VARIABLES
  CAPTURE_CALLBACKS  = {} unless defined? CAPTURE_CALLBACKS

  # line 61 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
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
	8, 1, 9, 1, 10, 1, 11, 1, 
	12, 1, 13, 1, 14, 1, 15, 1, 
	16, 1, 19, 1, 21, 1, 22, 1, 
	23, 1, 24, 1, 26, 1, 27, 1, 
	28, 1, 29, 1, 32, 1, 33, 1, 
	34, 1, 35, 1, 36, 2, 2, 12, 
	2, 3, 4, 2, 4, 5, 2, 7, 
	25, 2, 14, 15, 2, 17, 24, 2, 
	19, 20, 2, 22, 30, 3, 22, 18, 
	31
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
	44, 46, 47, 49, 51, 53, 55, 57, 
	59, 61, 63, 64, 72, 80, 82, 84, 
	86, 88, 89, 90, 92, 94, 96, 98, 
	100, 102, 104, 105, 107, 108, 110, 111, 
	112, 114, 115, 116, 117, 118, 119, 120, 
	121, 122, 123, 124, 126, 128, 130, 131, 
	132, 134, 136, 138, 140, 142, 144, 145, 
	146, 147, 148, 150, 151, 153, 167, 182, 
	197, 212, 229, 230, 232, 247, 248, 263, 
	278, 293, 310, 311, 313, 328, 343, 360, 
	376, 392, 409, 426, 442, 458, 475, 490, 
	491, 493, 495, 497, 499, 501, 503, 505, 
	507, 509, 511, 513, 515, 517, 519, 521, 
	523, 524, 525, 527, 543, 559, 575, 592, 
	593, 595, 611, 627, 643, 660, 661, 663, 
	680, 697, 714, 731, 748, 765, 782, 799, 
	816, 833, 850, 867, 884, 901, 917, 932, 
	947, 964, 965, 967, 982, 997, 1014, 1030, 
	1046, 1063, 1079, 1096, 1112, 1128, 1145, 1162, 
	1178, 1194, 1211, 1227, 1232, 1233, 1235, 1237, 
	1238, 1238, 1253, 1255, 1271, 1287
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
	48, 57, 46, 48, 57, 69, 101, 78, 
	110, 84, 116, 58, 13, 32, 13, 10, 
	13, 13, 32, 83, 115, 80, 112, 79, 
	111, 78, 110, 83, 115, 69, 101, 58, 
	32, 69, 70, 80, 83, 101, 112, 115, 
	32, 69, 70, 80, 83, 101, 112, 115, 
	82, 114, 82, 114, 79, 111, 82, 114, 
	13, 10, 77, 109, 69, 101, 83, 115, 
	83, 115, 65, 97, 71, 103, 69, 101, 
	58, 13, 32, 13, 10, 13, 13, 10, 
	13, 32, 111, 108, 108, 111, 119, 115, 
	13, 10, 13, 10, 79, 111, 78, 110, 
	71, 103, 13, 10, 85, 117, 67, 99, 
	67, 99, 69, 101, 83, 115, 83, 115, 
	13, 10, 13, 13, 10, 13, 13, 10, 
	13, 32, 47, 48, 57, 58, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 58, 33, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 10, 13, 
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
	126, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 58, 33, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 10, 13, 13, 45, 13, 
	45, 13, 69, 13, 78, 13, 68, 13, 
	32, 13, 67, 13, 79, 13, 77, 13, 
	77, 13, 65, 13, 78, 13, 68, 13, 
	45, 13, 45, 13, 10, 10, 13, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 10, 13, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 10, 13, 13, 
	45, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 69, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 78, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 68, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 67, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 79, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	77, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 77, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 65, 32, 47, 48, 57, 59, 
	64, 66, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 78, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 68, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 45, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 45, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 10, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
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
	126, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 58, 33, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 65, 69, 82, 101, 114, 
	115, 86, 118, 69, 101, 13, 13, 32, 
	47, 48, 57, 58, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 45, 13, 
	45, 32, 47, 48, 57, 58, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	45, 32, 47, 48, 57, 58, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 32, 
	47, 48, 57, 58, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 0
]

class << self
	attr_accessor :_ami_protocol_parser_single_lengths
	private :_ami_protocol_parser_single_lengths, :_ami_protocol_parser_single_lengths=
end
self._ami_protocol_parser_single_lengths = [
	0, 1, 1, 1, 1, 1, 1, 1, 
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
	1, 1, 2, 1, 2, 0, 1, 1, 
	1, 3, 1, 2, 1, 1, 1, 1, 
	1, 3, 1, 2, 1, 1, 3, 2, 
	2, 3, 3, 2, 2, 3, 1, 1, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	1, 1, 2, 2, 2, 2, 3, 1, 
	2, 2, 2, 2, 3, 1, 2, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 2, 1, 1, 
	3, 1, 2, 1, 1, 3, 2, 2, 
	3, 2, 3, 2, 2, 3, 3, 2, 
	2, 3, 2, 5, 1, 2, 2, 1, 
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 7, 7, 
	7, 7, 0, 0, 7, 0, 7, 7, 
	7, 7, 0, 0, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 7, 7, 7, 0, 
	0, 7, 7, 7, 7, 0, 0, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 0, 0, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 0, 0, 0, 0, 0, 
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
	69, 72, 74, 77, 80, 83, 86, 89, 
	92, 95, 98, 100, 109, 118, 121, 124, 
	127, 130, 132, 134, 137, 140, 143, 146, 
	149, 152, 155, 157, 160, 162, 165, 167, 
	169, 172, 174, 176, 178, 180, 182, 184, 
	186, 188, 190, 192, 195, 198, 201, 203, 
	205, 208, 211, 214, 217, 220, 223, 225, 
	227, 229, 231, 234, 236, 239, 247, 256, 
	265, 274, 285, 287, 290, 299, 301, 310, 
	319, 328, 339, 341, 344, 353, 362, 373, 
	383, 393, 404, 415, 425, 435, 446, 455, 
	457, 460, 463, 466, 469, 472, 475, 478, 
	481, 484, 487, 490, 493, 496, 499, 502, 
	505, 507, 509, 512, 522, 532, 542, 553, 
	555, 558, 568, 578, 588, 599, 601, 604, 
	615, 626, 637, 648, 659, 670, 681, 692, 
	703, 714, 725, 736, 747, 758, 768, 777, 
	786, 797, 799, 802, 811, 820, 831, 841, 
	851, 862, 872, 883, 893, 903, 914, 925, 
	935, 945, 956, 966, 972, 974, 977, 980, 
	982, 983, 992, 995, 1005, 1015
]

class << self
	attr_accessor :_ami_protocol_parser_trans_targs
	private :_ami_protocol_parser_trans_targs, :_ami_protocol_parser_trans_targs=
end
self._ami_protocol_parser_trans_targs = [
	2, 187, 3, 187, 4, 187, 5, 187, 
	6, 187, 7, 187, 8, 187, 9, 187, 
	10, 187, 11, 187, 12, 187, 13, 187, 
	14, 187, 15, 187, 16, 187, 17, 187, 
	18, 187, 19, 187, 20, 187, 21, 187, 
	22, 187, 23, 27, 187, 24, 187, 25, 
	26, 187, 187, 187, 25, 26, 187, 23, 
	27, 187, 29, 29, 187, 30, 30, 187, 
	31, 31, 187, 32, 187, 34, 35, 33, 
	34, 33, 187, 34, 33, 34, 35, 33, 
	37, 37, 187, 38, 38, 187, 39, 39, 
	187, 40, 40, 187, 41, 41, 187, 42, 
	42, 187, 43, 187, 44, 45, 65, 75, 
	80, 45, 75, 80, 187, 44, 45, 65, 
	75, 80, 45, 75, 80, 187, 46, 46, 
	187, 47, 47, 187, 48, 48, 187, 49, 
	49, 187, 50, 187, 51, 187, 52, 52, 
	187, 53, 53, 187, 54, 54, 187, 55, 
	55, 187, 56, 56, 187, 57, 57, 187, 
	58, 58, 187, 59, 187, 61, 64, 60, 
	61, 60, 62, 61, 60, 63, 187, 187, 
	187, 61, 64, 60, 66, 187, 67, 187, 
	68, 187, 69, 187, 70, 187, 71, 187, 
	72, 187, 73, 187, 74, 187, 187, 187, 
	76, 76, 187, 77, 77, 187, 78, 78, 
	187, 79, 187, 187, 187, 81, 81, 187, 
	82, 82, 187, 83, 83, 187, 84, 84, 
	187, 85, 85, 187, 86, 86, 187, 87, 
	187, 187, 187, 90, 89, 90, 89, 91, 
	90, 89, 92, 89, 191, 90, 89, 94, 
	118, 94, 118, 94, 118, 94, 0, 97, 
	95, 96, 95, 96, 95, 96, 95, 0, 
	97, 95, 96, 95, 96, 95, 96, 95, 
	0, 97, 95, 96, 95, 96, 95, 96, 
	95, 0, 99, 114, 117, 115, 116, 115, 
	116, 115, 116, 115, 98, 99, 98, 100, 
	99, 98, 101, 102, 109, 102, 109, 102, 
	109, 102, 0, 192, 0, 105, 103, 104, 
	103, 104, 103, 104, 103, 0, 105, 103, 
	104, 103, 104, 103, 104, 103, 0, 105, 
	103, 104, 103, 104, 103, 104, 103, 0, 
	107, 110, 113, 111, 112, 111, 112, 111, 
	112, 111, 106, 107, 106, 108, 107, 106, 
	101, 102, 109, 102, 109, 102, 109, 102, 
	0, 105, 103, 104, 103, 104, 103, 104, 
	103, 0, 107, 110, 113, 111, 112, 111, 
	112, 111, 112, 111, 106, 107, 113, 111, 
	112, 111, 112, 111, 112, 111, 106, 107, 
	113, 111, 112, 111, 112, 111, 112, 111, 
	106, 107, 110, 113, 111, 112, 111, 112, 
	111, 112, 111, 106, 99, 114, 117, 115, 
	116, 115, 116, 115, 116, 115, 98, 99, 
	117, 115, 116, 115, 116, 115, 116, 115, 
	98, 99, 117, 115, 116, 115, 116, 115, 
	116, 115, 98, 99, 114, 117, 115, 116, 
	115, 116, 115, 116, 115, 98, 97, 95, 
	96, 95, 96, 95, 96, 95, 0, 120, 
	119, 121, 120, 119, 120, 122, 119, 120, 
	123, 119, 120, 124, 119, 120, 125, 119, 
	120, 126, 119, 120, 127, 119, 120, 128, 
	119, 120, 129, 119, 120, 130, 119, 120, 
	131, 119, 120, 132, 119, 120, 133, 119, 
	120, 134, 119, 120, 135, 119, 120, 136, 
	119, 137, 193, 193, 193, 194, 120, 119, 
	120, 142, 140, 141, 140, 141, 140, 141, 
	140, 119, 120, 142, 140, 141, 140, 141, 
	140, 141, 140, 119, 120, 142, 140, 141, 
	140, 141, 140, 141, 140, 119, 144, 182, 
	185, 183, 184, 183, 184, 183, 184, 183, 
	143, 144, 143, 195, 144, 143, 120, 148, 
	146, 147, 146, 147, 146, 147, 146, 119, 
	120, 148, 146, 147, 146, 147, 146, 147, 
	146, 119, 120, 148, 146, 147, 146, 147, 
	146, 147, 146, 119, 150, 178, 181, 179, 
	180, 179, 180, 179, 180, 179, 149, 150, 
	149, 196, 150, 149, 120, 152, 148, 146, 
	147, 146, 147, 146, 147, 146, 119, 120, 
	148, 153, 146, 147, 146, 147, 146, 147, 
	146, 119, 120, 148, 154, 146, 147, 146, 
	147, 146, 147, 146, 119, 120, 148, 155, 
	146, 147, 146, 147, 146, 147, 146, 119, 
	120, 156, 148, 146, 147, 146, 147, 146, 
	147, 146, 119, 120, 148, 157, 146, 147, 
	146, 147, 146, 147, 146, 119, 120, 148, 
	158, 146, 147, 146, 147, 146, 147, 146, 
	119, 120, 148, 159, 146, 147, 146, 147, 
	146, 147, 146, 119, 120, 148, 160, 146, 
	147, 146, 147, 146, 147, 146, 119, 120, 
	148, 161, 146, 147, 146, 147, 146, 147, 
	146, 119, 120, 148, 162, 146, 147, 146, 
	147, 146, 147, 146, 119, 120, 148, 163, 
	146, 147, 146, 147, 146, 147, 146, 119, 
	120, 164, 148, 146, 147, 146, 147, 146, 
	147, 146, 119, 120, 165, 148, 146, 147, 
	146, 147, 146, 147, 146, 119, 137, 168, 
	166, 167, 166, 167, 166, 167, 166, 193, 
	168, 166, 167, 166, 167, 166, 167, 166, 
	193, 168, 166, 167, 166, 167, 166, 167, 
	166, 193, 170, 173, 176, 174, 175, 174, 
	175, 174, 175, 174, 169, 170, 169, 197, 
	170, 169, 168, 166, 167, 166, 167, 166, 
	167, 166, 193, 168, 166, 167, 166, 167, 
	166, 167, 166, 193, 170, 173, 176, 174, 
	175, 174, 175, 174, 175, 174, 169, 170, 
	176, 174, 175, 174, 175, 174, 175, 174, 
	169, 170, 176, 174, 175, 174, 175, 174, 
	175, 174, 169, 170, 173, 176, 174, 175, 
	174, 175, 174, 175, 174, 169, 120, 148, 
	146, 147, 146, 147, 146, 147, 146, 119, 
	150, 178, 181, 179, 180, 179, 180, 179, 
	180, 179, 149, 150, 181, 179, 180, 179, 
	180, 179, 180, 179, 149, 150, 181, 179, 
	180, 179, 180, 179, 180, 179, 149, 150, 
	178, 181, 179, 180, 179, 180, 179, 180, 
	179, 149, 144, 182, 185, 183, 184, 183, 
	184, 183, 184, 183, 143, 144, 185, 183, 
	184, 183, 184, 183, 184, 183, 143, 144, 
	185, 183, 184, 183, 184, 183, 184, 183, 
	143, 144, 182, 185, 183, 184, 183, 184, 
	183, 184, 183, 143, 120, 142, 140, 141, 
	140, 141, 140, 141, 140, 119, 188, 189, 
	190, 189, 190, 187, 1, 187, 28, 28, 
	187, 36, 36, 187, 92, 89, 0, 138, 
	139, 186, 139, 186, 139, 186, 139, 119, 
	120, 122, 119, 120, 151, 145, 177, 145, 
	177, 145, 177, 145, 119, 120, 151, 145, 
	177, 145, 177, 145, 177, 145, 119, 171, 
	172, 171, 172, 171, 172, 171, 193, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 187, 187, 
	187, 187, 187, 187, 187, 187, 193, 193, 
	193, 193, 193, 193, 193, 193, 193, 193, 
	193, 193, 193, 193, 193, 193, 193, 193, 
	193, 193, 193, 193, 193, 193, 193, 193, 
	193, 193, 193, 193, 193, 193, 193, 193, 
	193, 193, 193, 193, 193, 193, 193, 193, 
	193, 193, 193, 193, 193, 193, 193, 193, 
	193, 193, 193, 193, 193, 193, 187, 187, 
	187, 193, 193, 193, 193, 0
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
	0, 49, 39, 49, 3, 0, 49, 0, 
	0, 49, 0, 0, 49, 0, 0, 49, 
	0, 0, 49, 0, 49, 73, 27, 27, 
	29, 0, 41, 29, 0, 73, 27, 27, 
	0, 0, 49, 0, 0, 49, 0, 0, 
	49, 0, 0, 49, 0, 0, 49, 0, 
	0, 49, 0, 49, 0, 0, 0, 0, 
	0, 0, 0, 0, 49, 0, 0, 0, 
	0, 0, 0, 0, 0, 49, 0, 0, 
	49, 0, 0, 49, 0, 0, 49, 0, 
	0, 49, 0, 49, 0, 49, 0, 0, 
	49, 0, 0, 49, 0, 0, 49, 0, 
	0, 49, 0, 0, 49, 0, 0, 49, 
	0, 0, 49, 13, 49, 0, 13, 0, 
	0, 0, 0, 0, 0, 0, 49, 70, 
	49, 0, 13, 0, 0, 49, 0, 49, 
	0, 49, 0, 49, 0, 49, 0, 49, 
	0, 49, 31, 49, 0, 49, 43, 49, 
	0, 0, 49, 0, 0, 49, 0, 0, 
	49, 21, 49, 41, 49, 0, 0, 49, 
	0, 0, 49, 0, 0, 49, 0, 0, 
	49, 0, 0, 49, 0, 0, 49, 21, 
	49, 76, 49, 17, 17, 0, 0, 0, 
	0, 0, 0, 0, 19, 0, 0, 5, 
	5, 5, 5, 5, 5, 5, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 67, 9, 64, 9, 9, 9, 
	9, 9, 9, 9, 9, 11, 0, 0, 
	11, 0, 0, 5, 5, 5, 5, 5, 
	5, 5, 0, 15, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	67, 9, 64, 9, 9, 9, 9, 9, 
	9, 9, 9, 11, 0, 0, 11, 0, 
	0, 5, 5, 5, 5, 5, 5, 5, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 67, 9, 64, 9, 9, 9, 
	9, 9, 9, 9, 9, 11, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 11, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 67, 9, 64, 9, 9, 9, 9, 
	9, 9, 9, 9, 67, 9, 64, 9, 
	9, 9, 9, 9, 9, 9, 9, 11, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 11, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 67, 9, 64, 9, 9, 
	9, 9, 9, 9, 9, 9, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 25, 
	0, 0, 59, 51, 59, 85, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 67, 9, 
	64, 9, 9, 9, 9, 9, 9, 9, 
	9, 11, 0, 82, 11, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 67, 9, 64, 9, 
	9, 9, 9, 9, 9, 9, 9, 11, 
	0, 82, 11, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 25, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 57, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	57, 7, 0, 0, 0, 0, 0, 0, 
	0, 57, 67, 9, 64, 9, 9, 9, 
	9, 9, 9, 9, 9, 11, 0, 37, 
	11, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 57, 7, 0, 0, 0, 0, 
	0, 0, 0, 57, 67, 9, 64, 9, 
	9, 9, 9, 9, 9, 9, 9, 11, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 11, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 67, 9, 64, 9, 9, 
	9, 9, 9, 9, 9, 9, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	67, 9, 64, 9, 9, 9, 9, 9, 
	9, 9, 9, 11, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 11, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 67, 
	9, 64, 9, 9, 9, 9, 9, 9, 
	9, 9, 67, 9, 64, 9, 9, 9, 
	9, 9, 9, 9, 9, 11, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 11, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 67, 9, 64, 9, 9, 9, 9, 
	9, 9, 9, 9, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 37, 37, 
	37, 37, 37, 45, 0, 47, 0, 0, 
	47, 0, 0, 47, 0, 0, 0, 23, 
	61, 61, 61, 61, 61, 61, 61, 23, 
	0, 0, 0, 0, 5, 5, 5, 5, 
	5, 5, 5, 5, 0, 0, 5, 5, 
	5, 5, 5, 5, 5, 5, 0, 5, 
	5, 5, 5, 5, 5, 5, 53, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 59, 59, 
	59, 59, 59, 59, 59, 59, 59, 59, 
	59, 59, 59, 59, 59, 59, 59, 59, 
	59, 57, 57, 57, 57, 57, 57, 57, 
	57, 57, 57, 57, 57, 57, 57, 57, 
	57, 57, 57, 57, 57, 57, 57, 57, 
	57, 57, 57, 57, 57, 57, 57, 57, 
	57, 57, 57, 57, 57, 57, 47, 47, 
	47, 55, 53, 53, 53, 0
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
	33, 0, 0, 0, 0, 33, 0, 0, 
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
	0, 0, 0, 33, 0, 0, 0, 0, 
	0, 79, 0, 0, 0, 0
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
	0, 0, 0, 35, 0, 0, 0, 0, 
	0, 35, 0, 0, 0, 0
]

class << self
	attr_accessor :_ami_protocol_parser_eof_trans
	private :_ami_protocol_parser_eof_trans, :_ami_protocol_parser_eof_trans=
end
self._ami_protocol_parser_eof_trans = [
	0, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 1129, 
	1129, 1129, 1129, 1129, 1129, 1129, 1129, 1129, 
	1129, 1129, 1129, 1129, 1129, 1129, 1129, 1129, 
	1129, 1129, 0, 0, 0, 0, 0, 0, 
	0, 1166, 1166, 1166, 1166, 1166, 1166, 1166, 
	1166, 1166, 1166, 1166, 1166, 1166, 1166, 1166, 
	1166, 1166, 1166, 1166, 1166, 1166, 1166, 1166, 
	1166, 1166, 1166, 1166, 1166, 1166, 1166, 1166, 
	1166, 1166, 1166, 1166, 1166, 1166, 0, 0, 
	0, 0, 0, 0, 1169, 1169, 1169, 0, 
	0, 0, 1170, 1173, 1173, 1173
]

class << self
	attr_accessor :ami_protocol_parser_start
end
self.ami_protocol_parser_start = 187;
class << self
	attr_accessor :ami_protocol_parser_error
end
self.ami_protocol_parser_error = 0;

class << self
	attr_accessor :ami_protocol_parser_en_main
end
self.ami_protocol_parser_en_main = 187;
class << self
	attr_accessor :ami_protocol_parser_en_error_recovery
end
self.ami_protocol_parser_en_error_recovery = 88;
class << self
	attr_accessor :ami_protocol_parser_en_success
end
self.ami_protocol_parser_en_success = 93;
class << self
	attr_accessor :ami_protocol_parser_en_response_follows
end
self.ami_protocol_parser_en_response_follows = 193;


# line 774 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
begin
	 @current_pointer ||= 0
	 @data_ending_pointer ||=  @data.length
	 @current_state = ami_protocol_parser_start
	 @token_start = nil
	 @token_end = nil
	 @ragel_act = 0
end
# line 84 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"

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
    
# line 799 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
			when 21 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_start =  @current_pointer
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 834 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
		 @current_state = 187
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

      start_ignoring_syntax_error;
    		end
# line 33 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 10 then
# line 36 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      end_ignoring_syntax_error;
      	begin
		 @current_state = 187
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 36 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 11 then
# line 42 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      @current_message = NormalAmiResponse.new
    		end
# line 42 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 12 then
# line 46 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 start_capturing_follows_text 		end
# line 46 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 13 then
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      end_capturing_follows_text;
    		end
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 14 then
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin_capturing_event_name 		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 15 then
# line 52 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 init_event 		end
# line 52 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 16 then
# line 54 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      @current_message = NormalAmiResponse.new(true)
      	begin
		 @current_state = 193
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 54 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 17 then
# line 28 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 	begin
		 @current_state = 93
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 28 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 18 then
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 message_received; 	begin
		 @current_state = 187
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 22 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 23 then
# line 41 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 41 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 24 then
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
 begin  message_received @current_message  end
		end
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 25 then
# line 43 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 43 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 26 then
# line 44 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 44 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 27 then
# line 45 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
 begin   @current_pointer =  @current_pointer - 1; 	begin
		 @current_state = 88
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 45 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 28 then
# line 45 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1; begin   @current_pointer =  @current_pointer - 1; 	begin
		 @current_state = 88
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 45 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 29 then
# line 45 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin  @current_pointer = (( @token_end))-1; end
 begin   @current_pointer =  @current_pointer - 1; 	begin
		 @current_state = 88
		_trigger_goto = true
		_goto_level = _again
		break
	end
  end
		end
# line 45 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 30 then
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 6;		end
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 31 then
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 8;		end
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 32 then
# line 56 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 56 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 33 then
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 34 then
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 35 then
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin  @current_pointer = (( @token_end))-1; end
		end
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 36 then
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
# line 1159 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
when 19 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_start = nil;		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 20 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 0
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 1186 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
# line 98 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"

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
  
  # This method must do someting with @current_message or it'll be lost. TODO: Add it to events system.
  def message_received(current_message=@current_message)
    current_message
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
    ami_error! @data[@error_reason_start...@current_pointer]
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
  
  def ami_error!(reason)
    # raise "AMI Error: #{reason}"
  end
  
  def syntax_error!(ignored_chunk)
    p "Ignoring this: #{ignored_chunk}"
  end
  
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