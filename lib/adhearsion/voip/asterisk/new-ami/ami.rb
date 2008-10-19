# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# -*- ruby -*-
require 'rubygems'
require 'active_support'

require File.join(File.dirname(__FILE__), 'packets.rb')

class AmiStreamParser

  BUFFER_SIZE = 8.kilobytes unless defined? BUFFER_SIZE

  CAPTURED_VARIABLES = {} unless defined? CAPTURED_VARIABLES
  CAPTURE_CALLBACKS  = {} unless defined? CAPTURE_CALLBACKS

  # line 63 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
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
	7, 1, 8, 1, 9, 1, 10, 1, 
	11, 1, 12, 1, 13, 1, 14, 1, 
	15, 1, 16, 1, 19, 1, 21, 1, 
	22, 1, 25, 1, 26, 1, 27, 1, 
	28, 1, 29, 2, 2, 12, 2, 3, 
	4, 2, 4, 5, 2, 14, 15, 2, 
	17, 8, 2, 19, 20, 2, 22, 23, 
	3, 22, 18, 24
]

class << self
	attr_accessor :_ami_protocol_parser_key_offsets
	private :_ami_protocol_parser_key_offsets, :_ami_protocol_parser_key_offsets=
end
self._ami_protocol_parser_key_offsets = [
	0, 0, 5, 6, 7, 8, 9, 10, 
	11, 12, 13, 14, 15, 16, 17, 18, 
	19, 20, 21, 22, 23, 24, 25, 26, 
	28, 31, 33, 36, 37, 41, 43, 45, 
	47, 49, 50, 52, 53, 55, 57, 59, 
	61, 63, 65, 67, 69, 71, 72, 80, 
	88, 90, 92, 94, 96, 97, 98, 100, 
	102, 104, 106, 108, 110, 112, 113, 115, 
	116, 118, 119, 120, 122, 123, 124, 125, 
	126, 127, 128, 129, 130, 131, 132, 134, 
	136, 138, 139, 140, 142, 144, 146, 148, 
	150, 152, 153, 154, 157, 160, 174, 189, 
	204, 219, 236, 237, 239, 254, 255, 270, 
	285, 300, 317, 318, 320, 335, 350, 367, 
	383, 399, 416, 433, 449, 465, 482, 497, 
	498, 499, 501, 502, 504, 505, 506, 508, 
	510, 512, 514, 516, 518, 520, 522, 524, 
	526, 528, 530, 532, 534, 536, 538, 539, 
	540, 542, 558, 574, 590, 607, 608, 610, 
	626, 642, 658, 675, 676, 678, 695, 712, 
	729, 746, 763, 780, 797, 814, 831, 848, 
	865, 882, 899, 916, 932, 947, 962, 979, 
	980, 982, 997, 1012, 1029, 1045, 1061, 1078, 
	1094, 1111, 1127, 1143, 1160, 1177, 1193, 1209, 
	1226, 1242, 1242, 1242, 1242, 1242, 1242, 1242, 
	1243, 1243, 1258, 1260, 1276, 1292
]

class << self
	attr_accessor :_ami_protocol_parser_trans_keys
	private :_ami_protocol_parser_trans_keys, :_ami_protocol_parser_trans_keys=
end
self._ami_protocol_parser_trans_keys = [
	65, 69, 82, 101, 114, 115, 116, 101, 
	114, 105, 115, 107, 32, 67, 97, 108, 
	108, 32, 77, 97, 110, 97, 103, 101, 
	114, 47, 48, 57, 46, 48, 57, 48, 
	57, 13, 48, 57, 10, 69, 82, 101, 
	114, 86, 118, 69, 101, 78, 110, 84, 
	116, 58, 13, 32, 13, 10, 13, 13, 
	32, 69, 101, 83, 115, 80, 112, 79, 
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
	13, 10, 13, 48, 57, 46, 48, 57, 
	32, 47, 48, 57, 58, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 10, 13, 13, 
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
	13, 32, 58, 33, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 13, 10, 13, 13, 10, 13, 
	10, 13, 10, 13, 13, 45, 13, 45, 
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
	123, 126, 13, 13, 32, 47, 48, 57, 
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
	0, 5, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 0, 
	1, 0, 1, 1, 4, 2, 2, 2, 
	2, 1, 2, 1, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 1, 8, 8, 
	2, 2, 2, 2, 1, 1, 2, 2, 
	2, 2, 2, 2, 2, 1, 2, 1, 
	2, 1, 1, 2, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 2, 2, 
	2, 1, 1, 2, 2, 2, 2, 2, 
	2, 1, 1, 1, 1, 0, 1, 1, 
	1, 3, 1, 2, 1, 1, 1, 1, 
	1, 3, 1, 2, 1, 1, 3, 2, 
	2, 3, 3, 2, 2, 3, 1, 1, 
	1, 2, 1, 2, 1, 1, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 1, 1, 
	2, 2, 2, 2, 3, 1, 2, 2, 
	2, 2, 3, 1, 2, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 2, 1, 1, 3, 1, 
	2, 1, 1, 3, 2, 2, 3, 2, 
	3, 2, 2, 3, 3, 2, 2, 3, 
	2, 0, 0, 0, 0, 0, 0, 1, 
	0, 1, 2, 2, 2, 0
]

class << self
	attr_accessor :_ami_protocol_parser_range_lengths
	private :_ami_protocol_parser_range_lengths, :_ami_protocol_parser_range_lengths=
end
self._ami_protocol_parser_range_lengths = [
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 1, 
	1, 1, 1, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 1, 1, 7, 7, 7, 
	7, 7, 0, 0, 7, 0, 7, 7, 
	7, 7, 0, 0, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 7, 7, 7, 0, 0, 7, 
	7, 7, 7, 0, 0, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 0, 
	0, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 7, 7, 7
]

class << self
	attr_accessor :_ami_protocol_parser_index_offsets
	private :_ami_protocol_parser_index_offsets, :_ami_protocol_parser_index_offsets=
end
self._ami_protocol_parser_index_offsets = [
	0, 0, 6, 8, 10, 12, 14, 16, 
	18, 20, 22, 24, 26, 28, 30, 32, 
	34, 36, 38, 40, 42, 44, 46, 48, 
	50, 53, 55, 58, 60, 65, 68, 71, 
	74, 77, 79, 82, 84, 87, 90, 93, 
	96, 99, 102, 105, 108, 111, 113, 122, 
	131, 134, 137, 140, 143, 145, 147, 150, 
	153, 156, 159, 162, 165, 168, 170, 173, 
	175, 178, 180, 182, 185, 187, 189, 191, 
	193, 195, 197, 199, 201, 203, 205, 208, 
	211, 214, 216, 218, 221, 224, 227, 230, 
	233, 236, 238, 240, 243, 246, 254, 263, 
	272, 281, 292, 294, 297, 306, 308, 317, 
	326, 335, 346, 348, 351, 360, 369, 380, 
	390, 400, 411, 422, 432, 442, 453, 462, 
	464, 466, 469, 471, 474, 476, 478, 481, 
	484, 487, 490, 493, 496, 499, 502, 505, 
	508, 511, 514, 517, 520, 523, 526, 528, 
	530, 533, 543, 553, 563, 574, 576, 579, 
	589, 599, 609, 620, 622, 625, 636, 647, 
	658, 669, 680, 691, 702, 713, 724, 735, 
	746, 757, 768, 779, 789, 798, 807, 818, 
	820, 823, 832, 841, 852, 862, 872, 883, 
	893, 904, 914, 924, 935, 946, 956, 966, 
	977, 987, 988, 989, 990, 991, 992, 993, 
	995, 996, 1005, 1008, 1018, 1028
]

class << self
	attr_accessor :_ami_protocol_parser_trans_targs
	private :_ami_protocol_parser_trans_targs, :_ami_protocol_parser_trans_targs=
end
self._ami_protocol_parser_trans_targs = [
	2, 29, 38, 29, 38, 0, 3, 0, 
	4, 0, 5, 0, 6, 0, 7, 0, 
	8, 0, 9, 0, 10, 0, 11, 0, 
	12, 0, 13, 0, 14, 0, 15, 0, 
	16, 0, 17, 0, 18, 0, 19, 0, 
	20, 0, 21, 0, 22, 0, 23, 0, 
	24, 0, 25, 92, 0, 26, 0, 27, 
	91, 0, 28, 0, 29, 38, 29, 38, 
	0, 30, 30, 0, 31, 31, 0, 32, 
	32, 0, 33, 33, 0, 34, 0, 36, 
	37, 35, 36, 35, 193, 36, 35, 36, 
	37, 35, 39, 39, 0, 40, 40, 0, 
	41, 41, 0, 42, 42, 0, 43, 43, 
	0, 44, 44, 0, 45, 45, 0, 46, 
	0, 47, 48, 68, 78, 83, 48, 78, 
	83, 0, 47, 48, 68, 78, 83, 48, 
	78, 83, 0, 49, 49, 0, 50, 50, 
	0, 51, 51, 0, 52, 52, 0, 53, 
	0, 54, 0, 55, 55, 0, 56, 56, 
	0, 57, 57, 0, 58, 58, 0, 59, 
	59, 0, 60, 60, 0, 61, 61, 0, 
	62, 0, 64, 67, 63, 64, 63, 65, 
	64, 63, 66, 0, 194, 0, 64, 67, 
	63, 69, 0, 70, 0, 71, 0, 72, 
	0, 73, 0, 74, 0, 75, 0, 76, 
	0, 77, 0, 195, 0, 79, 79, 0, 
	80, 80, 0, 81, 81, 0, 82, 0, 
	196, 0, 84, 84, 0, 85, 85, 0, 
	86, 86, 0, 87, 87, 0, 88, 88, 
	0, 89, 89, 0, 90, 0, 197, 0, 
	27, 91, 0, 25, 92, 0, 94, 118, 
	94, 118, 94, 118, 94, 0, 97, 95, 
	96, 95, 96, 95, 96, 95, 0, 97, 
	95, 96, 95, 96, 95, 96, 95, 0, 
	97, 95, 96, 95, 96, 95, 96, 95, 
	0, 99, 114, 117, 115, 116, 115, 116, 
	115, 116, 115, 98, 99, 98, 100, 99, 
	98, 101, 102, 109, 102, 109, 102, 109, 
	102, 0, 198, 0, 105, 103, 104, 103, 
	104, 103, 104, 103, 0, 105, 103, 104, 
	103, 104, 103, 104, 103, 0, 105, 103, 
	104, 103, 104, 103, 104, 103, 0, 107, 
	110, 113, 111, 112, 111, 112, 111, 112, 
	111, 106, 107, 106, 108, 107, 106, 101, 
	102, 109, 102, 109, 102, 109, 102, 0, 
	105, 103, 104, 103, 104, 103, 104, 103, 
	0, 107, 110, 113, 111, 112, 111, 112, 
	111, 112, 111, 106, 107, 113, 111, 112, 
	111, 112, 111, 112, 111, 106, 107, 113, 
	111, 112, 111, 112, 111, 112, 111, 106, 
	107, 110, 113, 111, 112, 111, 112, 111, 
	112, 111, 106, 99, 114, 117, 115, 116, 
	115, 116, 115, 116, 115, 98, 99, 117, 
	115, 116, 115, 116, 115, 116, 115, 98, 
	99, 117, 115, 116, 115, 116, 115, 116, 
	115, 98, 99, 114, 117, 115, 116, 115, 
	116, 115, 116, 115, 98, 97, 95, 96, 
	95, 96, 95, 96, 95, 0, 121, 120, 
	121, 120, 122, 121, 120, 123, 120, 199, 
	121, 120, 200, 0, 126, 125, 127, 126, 
	125, 126, 128, 125, 126, 129, 125, 126, 
	130, 125, 126, 131, 125, 126, 132, 125, 
	126, 133, 125, 126, 134, 125, 126, 135, 
	125, 126, 136, 125, 126, 137, 125, 126, 
	138, 125, 126, 139, 125, 126, 140, 125, 
	126, 141, 125, 126, 142, 125, 143, 201, 
	201, 201, 202, 126, 125, 126, 148, 146, 
	147, 146, 147, 146, 147, 146, 125, 126, 
	148, 146, 147, 146, 147, 146, 147, 146, 
	125, 126, 148, 146, 147, 146, 147, 146, 
	147, 146, 125, 150, 188, 191, 189, 190, 
	189, 190, 189, 190, 189, 149, 150, 149, 
	203, 150, 149, 126, 154, 152, 153, 152, 
	153, 152, 153, 152, 125, 126, 154, 152, 
	153, 152, 153, 152, 153, 152, 125, 126, 
	154, 152, 153, 152, 153, 152, 153, 152, 
	125, 156, 184, 187, 185, 186, 185, 186, 
	185, 186, 185, 155, 156, 155, 204, 156, 
	155, 126, 158, 154, 152, 153, 152, 153, 
	152, 153, 152, 125, 126, 154, 159, 152, 
	153, 152, 153, 152, 153, 152, 125, 126, 
	154, 160, 152, 153, 152, 153, 152, 153, 
	152, 125, 126, 154, 161, 152, 153, 152, 
	153, 152, 153, 152, 125, 126, 162, 154, 
	152, 153, 152, 153, 152, 153, 152, 125, 
	126, 154, 163, 152, 153, 152, 153, 152, 
	153, 152, 125, 126, 154, 164, 152, 153, 
	152, 153, 152, 153, 152, 125, 126, 154, 
	165, 152, 153, 152, 153, 152, 153, 152, 
	125, 126, 154, 166, 152, 153, 152, 153, 
	152, 153, 152, 125, 126, 154, 167, 152, 
	153, 152, 153, 152, 153, 152, 125, 126, 
	154, 168, 152, 153, 152, 153, 152, 153, 
	152, 125, 126, 154, 169, 152, 153, 152, 
	153, 152, 153, 152, 125, 126, 170, 154, 
	152, 153, 152, 153, 152, 153, 152, 125, 
	126, 171, 154, 152, 153, 152, 153, 152, 
	153, 152, 125, 143, 174, 172, 173, 172, 
	173, 172, 173, 172, 201, 174, 172, 173, 
	172, 173, 172, 173, 172, 201, 174, 172, 
	173, 172, 173, 172, 173, 172, 201, 176, 
	179, 182, 180, 181, 180, 181, 180, 181, 
	180, 175, 176, 175, 205, 176, 175, 174, 
	172, 173, 172, 173, 172, 173, 172, 201, 
	174, 172, 173, 172, 173, 172, 173, 172, 
	201, 176, 179, 182, 180, 181, 180, 181, 
	180, 181, 180, 175, 176, 182, 180, 181, 
	180, 181, 180, 181, 180, 175, 176, 182, 
	180, 181, 180, 181, 180, 181, 180, 175, 
	176, 179, 182, 180, 181, 180, 181, 180, 
	181, 180, 175, 126, 154, 152, 153, 152, 
	153, 152, 153, 152, 125, 156, 184, 187, 
	185, 186, 185, 186, 185, 186, 185, 155, 
	156, 187, 185, 186, 185, 186, 185, 186, 
	185, 155, 156, 187, 185, 186, 185, 186, 
	185, 186, 185, 155, 156, 184, 187, 185, 
	186, 185, 186, 185, 186, 185, 155, 150, 
	188, 191, 189, 190, 189, 190, 189, 190, 
	189, 149, 150, 191, 189, 190, 189, 190, 
	189, 190, 189, 149, 150, 191, 189, 190, 
	189, 190, 189, 190, 189, 149, 150, 188, 
	191, 189, 190, 189, 190, 189, 190, 189, 
	149, 126, 148, 146, 147, 146, 147, 146, 
	147, 146, 125, 0, 0, 0, 0, 0, 
	0, 124, 0, 0, 144, 145, 192, 145, 
	192, 145, 192, 145, 125, 126, 128, 125, 
	126, 157, 151, 183, 151, 183, 151, 183, 
	151, 125, 126, 157, 151, 183, 151, 183, 
	151, 183, 151, 125, 177, 178, 177, 178, 
	177, 178, 177, 201, 201, 201, 201, 201, 
	201, 201, 201, 201, 201, 201, 201, 201, 
	201, 201, 201, 201, 201, 201, 201, 201, 
	201, 201, 201, 201, 201, 201, 201, 201, 
	201, 201, 201, 201, 201, 201, 201, 201, 
	201, 201, 201, 201, 201, 201, 201, 201, 
	201, 201, 201, 201, 201, 201, 201, 201, 
	201, 201, 201, 201, 201, 201, 201, 201, 
	0
]

class << self
	attr_accessor :_ami_protocol_parser_trans_actions
	private :_ami_protocol_parser_trans_actions, :_ami_protocol_parser_trans_actions=
end
self._ami_protocol_parser_trans_actions = [
	0, 0, 0, 0, 0, 19, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	1, 0, 0, 0, 0, 0, 0, 3, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	0, 19, 0, 0, 19, 0, 19, 60, 
	29, 29, 31, 0, 17, 31, 0, 60, 
	29, 29, 0, 0, 19, 0, 0, 19, 
	0, 0, 19, 0, 0, 19, 0, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	19, 0, 0, 0, 0, 0, 0, 0, 
	0, 19, 0, 0, 0, 0, 0, 0, 
	0, 0, 19, 0, 0, 19, 0, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	19, 0, 19, 0, 0, 19, 0, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	0, 19, 0, 0, 19, 0, 0, 19, 
	13, 19, 0, 13, 0, 0, 0, 0, 
	0, 0, 0, 19, 15, 19, 0, 13, 
	0, 0, 19, 0, 19, 0, 19, 0, 
	19, 0, 19, 0, 19, 0, 19, 33, 
	19, 0, 19, 0, 19, 0, 0, 19, 
	0, 0, 19, 0, 0, 19, 23, 19, 
	17, 19, 0, 0, 19, 0, 0, 19, 
	0, 0, 19, 0, 0, 19, 0, 0, 
	19, 0, 0, 19, 23, 19, 63, 19, 
	3, 0, 0, 0, 0, 0, 5, 5, 
	5, 5, 5, 5, 5, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 57, 9, 54, 9, 9, 9, 9, 
	9, 9, 9, 9, 11, 0, 0, 11, 
	0, 0, 5, 5, 5, 5, 5, 5, 
	5, 0, 17, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 57, 
	9, 54, 9, 9, 9, 9, 9, 9, 
	9, 9, 11, 0, 0, 11, 0, 0, 
	5, 5, 5, 5, 5, 5, 5, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 57, 9, 54, 9, 9, 9, 9, 
	9, 9, 9, 9, 11, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 11, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	57, 9, 54, 9, 9, 9, 9, 9, 
	9, 9, 9, 57, 9, 54, 9, 9, 
	9, 9, 9, 9, 9, 9, 11, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	11, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 57, 9, 54, 9, 9, 9, 
	9, 9, 9, 9, 9, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 21, 
	0, 0, 21, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 27, 0, 0, 49, 
	41, 49, 72, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 57, 9, 54, 9, 9, 
	9, 9, 9, 9, 9, 9, 11, 0, 
	69, 11, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 57, 9, 54, 9, 9, 9, 9, 
	9, 9, 9, 9, 11, 0, 69, 11, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 27, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 47, 7, 0, 0, 
	0, 0, 0, 0, 0, 47, 7, 0, 
	0, 0, 0, 0, 0, 0, 47, 57, 
	9, 54, 9, 9, 9, 9, 9, 9, 
	9, 9, 11, 0, 39, 11, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 47, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	47, 57, 9, 54, 9, 9, 9, 9, 
	9, 9, 9, 9, 11, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 11, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	57, 9, 54, 9, 9, 9, 9, 9, 
	9, 9, 9, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 57, 9, 54, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	11, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 11, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 57, 9, 54, 9, 
	9, 9, 9, 9, 9, 9, 9, 57, 
	9, 54, 9, 9, 9, 9, 9, 9, 
	9, 9, 11, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 11, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 57, 9, 
	54, 9, 9, 9, 9, 9, 9, 9, 
	9, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 19, 19, 19, 19, 19, 
	0, 0, 0, 0, 25, 51, 51, 51, 
	51, 51, 51, 51, 25, 0, 0, 0, 
	0, 5, 5, 5, 5, 5, 5, 5, 
	5, 0, 0, 5, 5, 5, 5, 5, 
	5, 5, 5, 0, 5, 5, 5, 5, 
	5, 5, 5, 43, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	49, 49, 49, 49, 49, 49, 49, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 45, 43, 43, 43, 
	0
]

class << self
	attr_accessor :_ami_protocol_parser_to_state_actions
	private :_ami_protocol_parser_to_state_actions, :_ami_protocol_parser_to_state_actions=
end
self._ami_protocol_parser_to_state_actions = [
	0, 35, 0, 0, 0, 0, 0, 0, 
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
	0, 0, 0, 0, 0, 35, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 35, 
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
	0, 66, 0, 0, 0, 0
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
	0, 37, 0, 0, 0, 0
]

class << self
	attr_accessor :_ami_protocol_parser_eof_actions
	private :_ami_protocol_parser_eof_actions, :_ami_protocol_parser_eof_actions=
end
self._ami_protocol_parser_eof_actions = [
	0, 19, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 0, 0, 0, 0, 0, 
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
	0, 0, 0, 0, 0, 0
]

class << self
	attr_accessor :_ami_protocol_parser_eof_trans
	private :_ami_protocol_parser_eof_trans, :_ami_protocol_parser_eof_trans=
end
self._ami_protocol_parser_eof_trans = [
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
	0, 0, 0, 0, 0, 1055, 1055, 1055, 
	1055, 1055, 1055, 1055, 1055, 1055, 1055, 1055, 
	1055, 1055, 1055, 1055, 1055, 1055, 1055, 1055, 
	0, 0, 0, 0, 0, 0, 0, 1092, 
	1092, 1092, 1092, 1092, 1092, 1092, 1092, 1092, 
	1092, 1092, 1092, 1092, 1092, 1092, 1092, 1092, 
	1092, 1092, 1092, 1092, 1092, 1092, 1092, 1092, 
	1092, 1092, 1092, 1092, 1092, 1092, 1092, 1092, 
	1092, 1092, 1092, 1092, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1093, 1096, 1096, 1096
]

class << self
	attr_accessor :ami_protocol_parser_start
end
self.ami_protocol_parser_start = 1;
class << self
	attr_accessor :ami_protocol_parser_error
end
self.ami_protocol_parser_error = 0;

class << self
	attr_accessor :ami_protocol_parser_en_main
end
self.ami_protocol_parser_en_main = 1;
class << self
	attr_accessor :ami_protocol_parser_en_success
end
self.ami_protocol_parser_en_success = 93;
class << self
	attr_accessor :ami_protocol_parser_en_error_recovery
end
self.ami_protocol_parser_en_error_recovery = 119;
class << self
	attr_accessor :ami_protocol_parser_en_response_follows
end
self.ami_protocol_parser_en_response_follows = 201;


# line 795 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
begin
	 @current_pointer ||= 0
	 @data_ending_pointer ||=  @data.length
	 @current_state = ami_protocol_parser_start
	 @token_start = nil
	 @token_end = nil
	 @ragel_act = 0
end
# line 86 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"

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
    
# line 820 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
# line 855 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
		 @current_state = 1
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

       @current_pointer =  @current_pointer - 1;
      start_ignoring_syntax_error;
      	begin
		 @current_state = 119
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 33 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 10 then
# line 38 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      end_ignoring_syntax_error;
      	begin
		 @current_state = 1
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 38 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 11 then
# line 44 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      @current_message = NormalAmiResponse.new
    		end
# line 44 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 12 then
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 start_capturing_follows_text 		end
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 13 then
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      end_capturing_follows_text;
    		end
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 14 then
# line 53 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin_capturing_event_name 		end
# line 53 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 15 then
# line 54 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 init_event 		end
# line 54 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 16 then
# line 56 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      @current_message = NormalAmiResponse.new(true)
      	begin
		 @current_state = 201
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 56 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
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
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 message_received; 	begin
		 @current_state = 1
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 22 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 23 then
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 1;		end
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 24 then
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 3;		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 25 then
# line 50 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 50 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 26 then
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 27 then
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 28 then
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin  @current_pointer = (( @token_end))-1; end
		end
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 29 then
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
# line 1124 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
# line 1151 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
	__acts = _ami_protocol_parser_eof_actions[ @current_state]
	__nacts =  _ami_protocol_parser_actions[__acts]
	__acts += 1
	while __nacts > 0
		__nacts -= 1
		__acts += 1
		case _ami_protocol_parser_actions[__acts - 1]
when 9 then
# line 33 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

       @current_pointer =  @current_pointer - 1;
      start_ignoring_syntax_error;
      	begin
		 @current_state = 119
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 33 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 1196 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
		end # eof action switch
	end
	if _trigger_goto
		next
	end
end
	end
	if _goto_level <= _out
		break
	end
	end
	end
# line 100 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"

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
    CAPTURE_CALLBACKS[variable_name].call(capture) if CAPTURE_CALLBACKS.has_key? variable_name
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
    view_buffer "Syntax error"
    @current_syntax_error_start = @current_pointer + 1 # Adding 1 since the pointer is still set to the last successful match
  end
  
  def end_ignoring_syntax_error
    # Subtracting 3 from @current_pointer below for "\r\n\r" which separates a stanza
    offending_data = @data[@current_syntax_error_start...@current_pointer - 3]
    syntax_error! offending_data
    @current_syntax_error_start = nil
  end
  
  def capture_callback_for(variable_name, &block)
    CAPTURE_CALLBACKS[variable_name] = block
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
    buffer.insert(@current_pointer, "^")
    
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