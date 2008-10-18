# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# -*- ruby -*-
require 'rubygems'
require 'active_support'

require File.join(File.dirname(__FILE__), 'packets.rb')

class AmiStreamParser

  BUFFER_SIZE = 8.kilobytes unless defined? BUFFER_SIZE

  CAPTURED_VARIABLES = {} unless defined? CAPTURED_VARIABLES
  CAPTURE_CALLBACKS  = {} unless defined? CAPTURE_CALLBACKS

  # line 66 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
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
	7, 1, 10, 1, 11, 1, 12, 1, 
	13, 1, 14, 1, 15, 1, 16, 1, 
	17, 1, 18, 1, 19, 1, 21, 1, 
	23, 1, 29, 1, 30, 1, 31, 1, 
	32, 2, 2, 14, 2, 3, 4, 2, 
	4, 5, 2, 5, 15, 2, 8, 4, 
	2, 9, 5, 2, 14, 15, 2, 16, 
	17, 2, 20, 28, 2, 21, 22, 2, 
	24, 25, 2, 24, 26, 2, 24, 27, 
	3, 4, 5, 15, 3, 8, 3, 4, 
	3, 9, 4, 5, 3, 9, 5, 15, 
	4, 8, 9, 4, 5, 4, 9, 4, 
	5, 15, 5, 8, 9, 4, 5, 15
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
	47, 49, 50, 51, 52, 53, 55, 57, 
	59, 61, 63, 65, 67, 69, 70, 71, 
	78, 80, 82, 84, 86, 87, 88, 90, 
	92, 94, 96, 98, 100, 102, 103, 104, 
	105, 106, 108, 109, 110, 111, 112, 113, 
	114, 115, 116, 117, 118, 119, 120, 122, 
	124, 126, 127, 128, 130, 132, 134, 136, 
	138, 140, 141, 142, 145, 148, 164, 179, 
	194, 209, 227, 228, 230, 247, 248, 263, 
	278, 293, 311, 312, 314, 331, 346, 363, 
	380, 397, 414, 431, 448, 465, 480, 498, 
	501, 519, 520, 522, 539, 542, 560, 576, 
	592, 610, 626, 642, 660, 678, 681, 699, 
	715, 731, 749, 764, 781, 798, 815, 832, 
	849, 866, 883, 898, 916, 934, 935, 937, 
	954, 957, 975, 991, 1007, 1025, 1026, 1027, 
	1029, 1030, 1032, 1033, 1034, 1036, 1038, 1040, 
	1042, 1044, 1046, 1048, 1050, 1052, 1054, 1056, 
	1058, 1060, 1062, 1064, 1066, 1067, 1068, 1070, 
	1086, 1102, 1118, 1136, 1137, 1139, 1142, 1160, 
	1176, 1192, 1210, 1226, 1244, 1262, 1280, 1298, 
	1316, 1334, 1352, 1368, 1386, 1404, 1405, 1407, 
	1410, 1428, 1444, 1460, 1478, 1478, 1478, 1478, 
	1478, 1478, 1478, 1479, 1479, 1496, 1498, 1500
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
	116, 58, 32, 13, 13, 10, 13, 69, 
	101, 83, 115, 80, 112, 79, 111, 78, 
	110, 83, 115, 69, 101, 58, 32, 69, 
	70, 80, 83, 101, 112, 115, 82, 114, 
	82, 114, 79, 111, 82, 114, 13, 10, 
	77, 109, 69, 101, 83, 115, 83, 115, 
	65, 97, 71, 103, 69, 101, 58, 32, 
	13, 13, 10, 13, 13, 10, 111, 108, 
	108, 111, 119, 115, 13, 10, 13, 10, 
	79, 111, 78, 110, 71, 103, 13, 10, 
	85, 117, 67, 99, 67, 99, 69, 101, 
	83, 115, 83, 115, 13, 10, 13, 48, 
	57, 46, 48, 57, 65, 97, 32, 47, 
	48, 57, 58, 64, 66, 90, 91, 96, 
	98, 122, 123, 126, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 9, 13, 32, 58, 33, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 10, 13, 13, 65, 
	97, 32, 47, 48, 57, 58, 64, 66, 
	90, 91, 96, 98, 122, 123, 126, 10, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 9, 13, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	10, 13, 13, 65, 97, 32, 47, 48, 
	57, 58, 64, 66, 90, 91, 96, 98, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 58, 67, 99, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 84, 116, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 73, 105, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 79, 111, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 78, 
	110, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	73, 105, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 68, 100, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	9, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 9, 13, 32, 9, 13, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	10, 13, 13, 65, 97, 32, 47, 48, 
	57, 58, 64, 66, 90, 91, 96, 98, 
	122, 123, 126, 9, 13, 32, 9, 13, 
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	9, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 9, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 9, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 9, 13, 
	32, 9, 13, 32, 58, 33, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 9, 13, 32, 58, 33, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 67, 99, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 84, 116, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 73, 
	105, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	79, 111, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 78, 110, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 73, 105, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 58, 68, 100, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 9, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 9, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 10, 
	13, 13, 65, 97, 32, 47, 48, 57, 
	58, 64, 66, 90, 91, 96, 98, 122, 
	123, 126, 9, 13, 32, 9, 13, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 9, 
	13, 32, 58, 33, 47, 48, 57, 59, 
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
	91, 96, 97, 122, 123, 126, 9, 13, 
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 10, 13, 9, 13, 32, 9, 13, 
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	9, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 67, 99, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 84, 116, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	73, 105, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 79, 111, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 78, 110, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 73, 105, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	68, 100, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	9, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 9, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 10, 13, 9, 
	13, 32, 9, 13, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 9, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 13, 
	65, 97, 32, 47, 48, 57, 58, 64, 
	66, 90, 91, 96, 98, 122, 123, 126, 
	13, 45, 13, 45, 13, 45, 0
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
	2, 1, 1, 1, 1, 2, 2, 2, 
	2, 2, 2, 2, 2, 1, 1, 7, 
	2, 2, 2, 2, 1, 1, 2, 2, 
	2, 2, 2, 2, 2, 1, 1, 1, 
	1, 2, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 2, 2, 
	2, 1, 1, 2, 2, 2, 2, 2, 
	2, 1, 1, 1, 1, 2, 1, 1, 
	1, 4, 1, 2, 3, 1, 1, 1, 
	1, 4, 1, 2, 3, 1, 3, 3, 
	3, 3, 3, 3, 3, 1, 4, 3, 
	4, 1, 2, 3, 3, 4, 2, 2, 
	4, 2, 2, 4, 4, 3, 4, 2, 
	2, 4, 1, 3, 3, 3, 3, 3, 
	3, 3, 1, 4, 4, 1, 2, 3, 
	3, 4, 2, 2, 4, 1, 1, 2, 
	1, 2, 1, 1, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 1, 1, 2, 2, 
	2, 2, 4, 1, 2, 3, 4, 2, 
	2, 4, 2, 4, 4, 4, 4, 4, 
	4, 4, 2, 4, 4, 1, 2, 3, 
	4, 2, 2, 4, 0, 0, 0, 0, 
	0, 0, 1, 0, 3, 2, 2, 2
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
	7, 0, 0, 7, 0, 7, 7, 7, 
	7, 7, 7, 7, 7, 0, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 0, 0, 7, 
	0, 7, 7, 7, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	7, 7, 7, 0, 0, 0, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 0, 0, 0, 
	7, 7, 7, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0
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
	74, 77, 79, 81, 83, 85, 88, 91, 
	94, 97, 100, 103, 106, 109, 111, 113, 
	121, 124, 127, 130, 133, 135, 137, 140, 
	143, 146, 149, 152, 155, 158, 160, 162, 
	164, 166, 169, 171, 173, 175, 177, 179, 
	181, 183, 185, 187, 189, 191, 193, 196, 
	199, 202, 204, 206, 209, 212, 215, 218, 
	221, 224, 226, 228, 231, 234, 244, 253, 
	262, 271, 283, 285, 288, 299, 301, 310, 
	319, 328, 340, 342, 345, 356, 365, 376, 
	387, 398, 409, 420, 431, 442, 451, 463, 
	467, 479, 481, 484, 495, 499, 511, 521, 
	531, 543, 553, 563, 575, 587, 591, 603, 
	613, 623, 635, 644, 655, 666, 677, 688, 
	699, 710, 721, 730, 742, 754, 756, 759, 
	770, 774, 786, 796, 806, 818, 820, 822, 
	825, 827, 830, 832, 834, 837, 840, 843, 
	846, 849, 852, 855, 858, 861, 864, 867, 
	870, 873, 876, 879, 882, 884, 886, 889, 
	899, 909, 919, 931, 933, 936, 940, 952, 
	962, 972, 984, 994, 1006, 1018, 1030, 1042, 
	1054, 1066, 1078, 1088, 1100, 1112, 1114, 1117, 
	1121, 1133, 1143, 1153, 1165, 1166, 1167, 1168, 
	1169, 1170, 1171, 1173, 1174, 1185, 1188, 1191
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
	32, 0, 33, 33, 0, 34, 0, 35, 
	0, 37, 36, 37, 36, 212, 37, 36, 
	39, 39, 0, 40, 40, 0, 41, 41, 
	0, 42, 42, 0, 43, 43, 0, 44, 
	44, 0, 45, 45, 0, 46, 0, 47, 
	0, 48, 68, 78, 83, 48, 78, 83, 
	0, 49, 49, 0, 50, 50, 0, 51, 
	51, 0, 52, 52, 0, 53, 0, 54, 
	0, 55, 55, 0, 56, 56, 0, 57, 
	57, 0, 58, 58, 0, 59, 59, 0, 
	60, 60, 0, 61, 61, 0, 62, 0, 
	63, 0, 65, 64, 65, 64, 66, 65, 
	64, 67, 0, 213, 0, 69, 0, 70, 
	0, 71, 0, 72, 0, 73, 0, 74, 
	0, 75, 0, 76, 0, 77, 0, 214, 
	0, 79, 79, 0, 80, 80, 0, 81, 
	81, 0, 82, 0, 215, 0, 84, 84, 
	0, 85, 85, 0, 86, 86, 0, 87, 
	87, 0, 88, 88, 0, 89, 89, 0, 
	90, 0, 216, 0, 27, 91, 0, 25, 
	92, 0, 139, 139, 94, 138, 94, 138, 
	94, 138, 94, 0, 97, 95, 96, 95, 
	96, 95, 96, 95, 0, 97, 95, 96, 
	95, 96, 95, 96, 95, 0, 97, 95, 
	96, 95, 96, 95, 96, 95, 0, 133, 
	99, 134, 137, 135, 136, 135, 136, 135, 
	136, 135, 98, 99, 98, 100, 99, 98, 
	101, 110, 110, 102, 109, 102, 109, 102, 
	109, 102, 0, 217, 0, 105, 103, 104, 
	103, 104, 103, 104, 103, 0, 105, 103, 
	104, 103, 104, 103, 104, 103, 0, 105, 
	103, 104, 103, 104, 103, 104, 103, 0, 
	119, 107, 132, 131, 129, 130, 129, 130, 
	129, 130, 129, 106, 107, 106, 108, 107, 
	106, 101, 110, 110, 102, 109, 102, 109, 
	102, 109, 102, 0, 105, 103, 104, 103, 
	104, 103, 104, 103, 0, 105, 111, 111, 
	103, 104, 103, 104, 103, 104, 103, 0, 
	105, 112, 112, 103, 104, 103, 104, 103, 
	104, 103, 0, 105, 113, 113, 103, 104, 
	103, 104, 103, 104, 103, 0, 105, 114, 
	114, 103, 104, 103, 104, 103, 104, 103, 
	0, 105, 115, 115, 103, 104, 103, 104, 
	103, 104, 103, 0, 105, 116, 116, 103, 
	104, 103, 104, 103, 104, 103, 0, 105, 
	117, 117, 103, 104, 103, 104, 103, 104, 
	103, 0, 118, 103, 104, 103, 104, 103, 
	104, 103, 0, 119, 107, 120, 131, 129, 
	130, 129, 130, 129, 130, 129, 106, 119, 
	107, 119, 106, 124, 122, 125, 128, 126, 
	127, 126, 127, 126, 127, 126, 121, 122, 
	121, 123, 122, 121, 101, 110, 110, 102, 
	109, 102, 109, 102, 109, 102, 0, 124, 
	122, 124, 121, 124, 122, 125, 128, 126, 
	127, 126, 127, 126, 127, 126, 121, 122, 
	128, 126, 127, 126, 127, 126, 127, 126, 
	121, 122, 128, 126, 127, 126, 127, 126, 
	127, 126, 121, 124, 122, 125, 128, 126, 
	127, 126, 127, 126, 127, 126, 121, 107, 
	131, 129, 130, 129, 130, 129, 130, 129, 
	106, 107, 131, 129, 130, 129, 130, 129, 
	130, 129, 106, 119, 107, 132, 131, 129, 
	130, 129, 130, 129, 130, 129, 106, 119, 
	107, 132, 131, 129, 130, 129, 130, 129, 
	130, 129, 106, 133, 99, 133, 98, 133, 
	99, 134, 137, 135, 136, 135, 136, 135, 
	136, 135, 98, 99, 137, 135, 136, 135, 
	136, 135, 136, 135, 98, 99, 137, 135, 
	136, 135, 136, 135, 136, 135, 98, 133, 
	99, 134, 137, 135, 136, 135, 136, 135, 
	136, 135, 98, 97, 95, 96, 95, 96, 
	95, 96, 95, 0, 97, 140, 140, 95, 
	96, 95, 96, 95, 96, 95, 0, 97, 
	141, 141, 95, 96, 95, 96, 95, 96, 
	95, 0, 97, 142, 142, 95, 96, 95, 
	96, 95, 96, 95, 0, 97, 143, 143, 
	95, 96, 95, 96, 95, 96, 95, 0, 
	97, 144, 144, 95, 96, 95, 96, 95, 
	96, 95, 0, 97, 145, 145, 95, 96, 
	95, 96, 95, 96, 95, 0, 97, 146, 
	146, 95, 96, 95, 96, 95, 96, 95, 
	0, 147, 95, 96, 95, 96, 95, 96, 
	95, 0, 133, 99, 148, 137, 135, 136, 
	135, 136, 135, 136, 135, 98, 152, 150, 
	153, 156, 154, 155, 154, 155, 154, 155, 
	154, 149, 150, 149, 151, 150, 149, 101, 
	110, 110, 102, 109, 102, 109, 102, 109, 
	102, 0, 152, 150, 152, 149, 152, 150, 
	153, 156, 154, 155, 154, 155, 154, 155, 
	154, 149, 150, 156, 154, 155, 154, 155, 
	154, 155, 154, 149, 150, 156, 154, 155, 
	154, 155, 154, 155, 154, 149, 152, 150, 
	153, 156, 154, 155, 154, 155, 154, 155, 
	154, 149, 159, 158, 159, 158, 160, 159, 
	158, 161, 158, 218, 159, 158, 219, 0, 
	164, 163, 165, 164, 163, 164, 166, 163, 
	164, 167, 163, 164, 168, 163, 164, 169, 
	163, 164, 170, 163, 164, 171, 163, 164, 
	172, 163, 164, 173, 163, 164, 174, 163, 
	164, 175, 163, 164, 176, 163, 164, 177, 
	163, 164, 178, 163, 164, 179, 163, 164, 
	180, 163, 181, 220, 220, 220, 221, 164, 
	163, 164, 186, 184, 185, 184, 185, 184, 
	185, 184, 163, 164, 186, 184, 185, 184, 
	185, 184, 185, 184, 163, 164, 186, 184, 
	185, 184, 185, 184, 185, 184, 163, 189, 
	188, 190, 193, 191, 192, 191, 192, 191, 
	192, 191, 187, 188, 187, 222, 188, 187, 
	189, 188, 189, 187, 189, 188, 190, 193, 
	191, 192, 191, 192, 191, 192, 191, 187, 
	188, 193, 191, 192, 191, 192, 191, 192, 
	191, 187, 188, 193, 191, 192, 191, 192, 
	191, 192, 191, 187, 189, 188, 190, 193, 
	191, 192, 191, 192, 191, 192, 191, 187, 
	164, 186, 184, 185, 184, 185, 184, 185, 
	184, 163, 164, 186, 196, 196, 184, 185, 
	184, 185, 184, 185, 184, 163, 164, 186, 
	197, 197, 184, 185, 184, 185, 184, 185, 
	184, 163, 164, 186, 198, 198, 184, 185, 
	184, 185, 184, 185, 184, 163, 164, 186, 
	199, 199, 184, 185, 184, 185, 184, 185, 
	184, 163, 164, 186, 200, 200, 184, 185, 
	184, 185, 184, 185, 184, 163, 164, 186, 
	201, 201, 184, 185, 184, 185, 184, 185, 
	184, 163, 164, 186, 202, 202, 184, 185, 
	184, 185, 184, 185, 184, 163, 164, 203, 
	184, 185, 184, 185, 184, 185, 184, 163, 
	189, 188, 204, 193, 191, 192, 191, 192, 
	191, 192, 191, 187, 207, 206, 208, 211, 
	209, 210, 209, 210, 209, 210, 209, 205, 
	206, 205, 223, 206, 205, 207, 206, 207, 
	205, 207, 206, 208, 211, 209, 210, 209, 
	210, 209, 210, 209, 205, 206, 211, 209, 
	210, 209, 210, 209, 210, 209, 205, 206, 
	211, 209, 210, 209, 210, 209, 210, 209, 
	205, 207, 206, 208, 211, 209, 210, 209, 
	210, 209, 210, 209, 205, 0, 0, 0, 
	0, 0, 0, 162, 0, 0, 182, 195, 
	195, 183, 194, 183, 194, 183, 194, 183, 
	163, 164, 166, 163, 164, 166, 163, 164, 
	166, 163, 220, 220, 220, 220, 220, 220, 
	220, 220, 220, 220, 220, 220, 220, 220, 
	220, 220, 220, 220, 220, 220, 220, 220, 
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
	0, 19, 0, 0, 19, 0, 19, 0, 
	19, 70, 29, 31, 0, 17, 31, 0, 
	0, 0, 19, 0, 0, 19, 0, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	0, 19, 0, 0, 19, 0, 19, 0, 
	19, 0, 0, 0, 0, 0, 0, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	0, 19, 0, 0, 19, 0, 19, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	0, 19, 0, 0, 19, 0, 0, 19, 
	0, 0, 19, 0, 0, 19, 0, 19, 
	13, 19, 0, 0, 0, 0, 0, 0, 
	0, 0, 19, 15, 19, 0, 19, 0, 
	19, 0, 19, 0, 19, 0, 19, 0, 
	19, 0, 19, 33, 19, 0, 19, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	0, 19, 23, 19, 17, 19, 0, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	0, 19, 0, 0, 19, 0, 0, 19, 
	23, 19, 17, 19, 3, 0, 0, 0, 
	0, 0, 5, 5, 5, 5, 5, 5, 
	5, 5, 5, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 9, 
	55, 9, 52, 9, 9, 9, 9, 9, 
	9, 9, 9, 11, 0, 0, 11, 0, 
	0, 5, 5, 5, 5, 5, 5, 5, 
	5, 5, 0, 17, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	9, 55, 9, 52, 9, 9, 9, 9, 
	9, 9, 9, 9, 11, 0, 0, 11, 
	0, 0, 5, 5, 5, 5, 5, 5, 
	5, 5, 5, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 9, 55, 9, 52, 9, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	55, 9, 9, 61, 104, 61, 92, 61, 
	61, 61, 61, 61, 61, 61, 61, 64, 
	0, 0, 64, 0, 0, 5, 5, 5, 
	5, 5, 5, 5, 5, 5, 0, 9, 
	96, 9, 9, 9, 96, 9, 52, 9, 
	9, 9, 9, 9, 9, 9, 9, 64, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 64, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 9, 96, 9, 52, 9, 
	9, 9, 9, 9, 9, 9, 9, 11, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 11, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 9, 55, 9, 52, 9, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	55, 9, 52, 9, 9, 9, 9, 9, 
	9, 9, 9, 9, 55, 9, 9, 9, 
	55, 9, 52, 9, 9, 9, 9, 9, 
	9, 9, 9, 11, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 11, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 9, 
	55, 9, 52, 9, 9, 9, 9, 9, 
	9, 9, 9, 7, 0, 0, 0, 0, 
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
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 9, 55, 9, 52, 9, 9, 
	9, 9, 9, 9, 9, 9, 61, 104, 
	61, 92, 61, 61, 61, 61, 61, 61, 
	61, 61, 64, 0, 0, 64, 0, 0, 
	5, 5, 5, 5, 5, 5, 5, 5, 
	5, 0, 9, 96, 9, 9, 9, 96, 
	9, 52, 9, 9, 9, 9, 9, 9, 
	9, 9, 64, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 64, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 9, 96, 
	9, 52, 9, 9, 9, 9, 9, 9, 
	9, 9, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 21, 0, 0, 21, 0, 
	27, 0, 0, 27, 0, 27, 0, 0, 
	27, 0, 0, 27, 0, 0, 27, 0, 
	0, 27, 0, 0, 27, 0, 0, 27, 
	0, 0, 27, 0, 0, 27, 0, 0, 
	27, 0, 0, 27, 0, 0, 27, 0, 
	0, 27, 0, 0, 27, 0, 0, 27, 
	0, 0, 0, 47, 73, 47, 85, 27, 
	0, 27, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 27, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 27, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 9, 
	88, 9, 52, 9, 9, 9, 9, 9, 
	9, 9, 9, 58, 0, 82, 58, 0, 
	9, 88, 9, 9, 9, 88, 9, 52, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	58, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 58, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 9, 88, 9, 52, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	27, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 27, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 27, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 27, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 27, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 27, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 27, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 27, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 27, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	9, 88, 9, 52, 9, 9, 9, 9, 
	9, 9, 9, 9, 61, 114, 61, 92, 
	61, 61, 61, 61, 61, 61, 61, 61, 
	100, 0, 79, 100, 0, 9, 109, 9, 
	9, 9, 109, 9, 52, 9, 9, 9, 
	9, 9, 9, 9, 9, 100, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 100, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 9, 109, 9, 52, 9, 9, 9, 
	9, 9, 9, 9, 9, 19, 19, 19, 
	19, 19, 0, 0, 0, 0, 67, 49, 
	49, 49, 49, 49, 49, 49, 49, 49, 
	25, 27, 0, 0, 27, 0, 0, 27, 
	0, 0, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 45, 43, 41, 
	0
]

class << self
	attr_accessor :_ami_protocol_parser_to_state_actions
	private :_ami_protocol_parser_to_state_actions, :_ami_protocol_parser_to_state_actions=
end
self._ami_protocol_parser_to_state_actions = [
	0, 37, 0, 0, 0, 0, 0, 0, 
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
	0, 0, 0, 0, 0, 37, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 37, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 76, 0, 0, 0
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
	0, 0, 0, 0, 39, 0, 0, 0
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	35, 0, 0, 0, 0, 0, 0, 0
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 1213, 1213, 1213, 1213, 1213, 
	1213, 1213, 1213, 1213, 1213, 1213, 1213, 1213, 
	1213, 1213, 1213, 1213, 1213, 1213, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 1214, 1215, 1216
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
self.ami_protocol_parser_en_error_recovery = 157;
class << self
	attr_accessor :ami_protocol_parser_en_response_follows
end
self.ami_protocol_parser_en_response_follows = 220;


# line 870 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
begin
	 @current_pointer ||= 0
	 @data_ending_pointer ||=  @data.length
	 @current_state = ami_protocol_parser_start
	 @token_start = nil
	 @token_end = nil
	 @ragel_act = 0
end
# line 89 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"

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
    
# line 895 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
			when 23 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_start =  @current_pointer
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 930 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
 before_action_id 		end
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 9 then
# line 32 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 after_action_id  		end
# line 32 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 10 then
# line 34 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 message_received @current_message 		end
# line 34 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 11 then
# line 36 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

       @current_pointer =  @current_pointer - 1;
      start_ignoring_syntax_error;
      	begin
		 @current_state = 157
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 36 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 12 then
# line 41 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      end_ignoring_syntax_error;
      	begin
		 @current_state = 1
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 41 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 13 then
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      @current_message = NormalAmiResponse.new
    		end
# line 47 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 14 then
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 start_capturing_follows_text 		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 15 then
# line 52 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      end_capturing_follows_text;
    		end
# line 52 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 16 then
# line 56 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin_capturing_event_name 		end
# line 56 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 17 then
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 init_event 		end
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 18 then
# line 59 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

      @current_message = NormalAmiResponse.new(true)
      	begin
		 @current_state = 220
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 59 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 20 then
# line 34 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 	begin
		 @current_state = 1
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 34 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 24 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 25 then
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 1;		end
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 26 then
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 2;		end
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 27 then
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 4;		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 28 then
# line 50 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 50 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 29 then
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 30 then
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 31 then
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 32 then
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
# line 1203 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
when 21 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_start = nil;		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 22 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 0
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 1230 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
when 11 then
# line 36 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin

       @current_pointer =  @current_pointer - 1;
      start_ignoring_syntax_error;
      	begin
		 @current_state = 157
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 36 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 19 then
# line 27 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 	begin
		 @current_state = 93
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 27 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 1286 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
# line 103 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"

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
    puts "Instantiated new event"
  end
  
  # This method must do someting with @current_message or it'll be lost.
  def message_received(current_message)
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
    add_pair_to_current_message
  end
  
  def before_action_id
    @start_action_id = @current_pointer
  end
  
  def after_action_id
    @current_message.action_id = @data[@start_action_id...@current_pointer]
    puts "ActionID: #{current_message.action_id}"
    @start_action_id = nil
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
    text = @data[@follows_text_start..(@current_pointer - "\r\n--END COMMAND--".size)]
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
