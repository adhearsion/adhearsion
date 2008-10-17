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
	17, 1, 18, 1, 20, 1, 22, 1, 
	28, 1, 29, 1, 30, 1, 31, 2, 
	2, 14, 2, 3, 4, 2, 4, 5, 
	2, 5, 15, 2, 8, 4, 2, 9, 
	5, 2, 14, 15, 2, 16, 17, 2, 
	19, 27, 2, 20, 21, 2, 23, 24, 
	2, 23, 25, 2, 23, 26, 3, 4, 
	5, 15, 3, 8, 3, 4, 3, 9, 
	4, 5, 3, 9, 5, 15, 4, 8, 
	9, 4, 5, 4, 9, 4, 5, 15, 
	5, 8, 9, 4, 5, 15
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
	47, 49, 50, 51, 52, 53, 55, 56, 
	57, 59, 61, 63, 65, 67, 69, 71, 
	72, 73, 80, 82, 84, 86, 88, 89, 
	90, 92, 94, 96, 98, 100, 102, 104, 
	105, 106, 107, 108, 110, 111, 112, 113, 
	114, 115, 116, 117, 118, 119, 120, 121, 
	122, 124, 126, 128, 129, 130, 131, 133, 
	135, 137, 139, 141, 143, 144, 145, 146, 
	149, 152, 168, 183, 198, 213, 229, 245, 
	246, 248, 265, 266, 281, 296, 311, 327, 
	343, 344, 346, 363, 378, 395, 412, 429, 
	446, 463, 480, 497, 512, 528, 544, 545, 
	547, 564, 580, 596, 613, 629, 645, 661, 
	678, 694, 710, 726, 743, 759, 774, 791, 
	808, 825, 842, 859, 876, 893, 908, 924, 
	940, 941, 943, 960, 976, 992, 1009, 1025, 
	1026, 1027, 1029, 1030, 1032, 1033, 1034, 1036, 
	1038, 1040, 1042, 1044, 1046, 1048, 1050, 1052, 
	1054, 1056, 1058, 1060, 1062, 1064, 1066, 1067, 
	1068, 1070, 1086, 1102, 1118, 1135, 1151, 1152, 
	1154, 1170, 1186, 1203, 1219, 1235, 1253, 1271, 
	1289, 1307, 1325, 1343, 1361, 1377, 1394, 1410, 
	1411, 1413, 1429, 1445, 1462, 1478, 1478, 1478, 
	1478, 1478, 1479, 1479, 1496, 1498, 1500
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
	116, 58, 32, 13, 13, 10, 13, 13, 
	10, 69, 101, 83, 115, 80, 112, 79, 
	111, 78, 110, 83, 115, 69, 101, 58, 
	32, 69, 70, 80, 83, 101, 112, 115, 
	82, 114, 82, 114, 79, 111, 82, 114, 
	13, 10, 77, 109, 69, 101, 83, 115, 
	83, 115, 65, 97, 71, 103, 69, 101, 
	58, 32, 13, 13, 10, 13, 13, 10, 
	111, 108, 108, 111, 119, 115, 13, 10, 
	13, 10, 79, 111, 78, 110, 71, 103, 
	13, 10, 13, 85, 117, 67, 99, 67, 
	99, 69, 101, 83, 115, 83, 115, 13, 
	10, 13, 13, 48, 57, 46, 48, 57, 
	65, 97, 32, 47, 48, 57, 58, 64, 
	66, 90, 91, 96, 98, 122, 123, 126, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 32, 58, 33, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 10, 13, 
	13, 65, 97, 32, 47, 48, 57, 58, 
	64, 66, 90, 91, 96, 98, 122, 123, 
	126, 10, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
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
	32, 58, 33, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 10, 13, 13, 65, 97, 32, 47, 
	48, 57, 58, 64, 66, 90, 91, 96, 
	98, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 32, 58, 33, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 58, 67, 
	99, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	84, 116, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 73, 105, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 79, 111, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 58, 78, 110, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 58, 73, 105, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 58, 68, 100, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 32, 58, 33, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 58, 32, 47, 
	48, 57, 59, 64, 65, 90, 91, 96, 
	97, 122, 123, 126, 13, 10, 13, 13, 
	65, 97, 32, 47, 48, 57, 58, 64, 
	66, 90, 91, 96, 98, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 32, 58, 33, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
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
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	10, 13, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 32, 58, 33, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 67, 99, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 84, 
	116, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 73, 105, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 79, 111, 32, 47, 48, 
	57, 59, 64, 65, 90, 91, 96, 97, 
	122, 123, 126, 13, 58, 78, 110, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 73, 
	105, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	58, 68, 100, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 32, 58, 33, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 58, 32, 47, 48, 57, 
	59, 64, 65, 90, 91, 96, 97, 122, 
	123, 126, 13, 10, 13, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 58, 32, 
	47, 48, 57, 59, 64, 65, 90, 91, 
	96, 97, 122, 123, 126, 13, 32, 58, 
	33, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
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
	2, 1, 1, 1, 1, 2, 1, 1, 
	2, 2, 2, 2, 2, 2, 2, 1, 
	1, 7, 2, 2, 2, 2, 1, 1, 
	2, 2, 2, 2, 2, 2, 2, 1, 
	1, 1, 1, 2, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	2, 2, 2, 1, 1, 1, 2, 2, 
	2, 2, 2, 2, 1, 1, 1, 1, 
	1, 2, 1, 1, 1, 2, 2, 1, 
	2, 3, 1, 1, 1, 1, 2, 2, 
	1, 2, 3, 1, 3, 3, 3, 3, 
	3, 3, 3, 1, 2, 2, 1, 2, 
	3, 2, 2, 3, 2, 2, 2, 3, 
	2, 2, 2, 3, 2, 1, 3, 3, 
	3, 3, 3, 3, 3, 1, 2, 2, 
	1, 2, 3, 2, 2, 3, 2, 1, 
	1, 2, 1, 2, 1, 1, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 1, 1, 
	2, 2, 2, 2, 3, 2, 1, 2, 
	2, 2, 3, 2, 2, 4, 4, 4, 
	4, 4, 4, 4, 2, 3, 2, 1, 
	2, 2, 2, 3, 2, 0, 0, 0, 
	0, 1, 0, 3, 2, 2, 2
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
	0, 0, 0, 0, 0, 0, 0, 1, 
	1, 7, 7, 7, 7, 7, 7, 0, 
	0, 7, 0, 7, 7, 7, 7, 7, 
	0, 0, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 0, 0, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	0, 0, 7, 7, 7, 7, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 7, 7, 7, 7, 0, 0, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 7, 7, 7, 7, 7, 7, 0, 
	0, 7, 7, 7, 7, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0
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
	74, 77, 79, 81, 83, 85, 88, 90, 
	92, 95, 98, 101, 104, 107, 110, 113, 
	115, 117, 125, 128, 131, 134, 137, 139, 
	141, 144, 147, 150, 153, 156, 159, 162, 
	164, 166, 168, 170, 173, 175, 177, 179, 
	181, 183, 185, 187, 189, 191, 193, 195, 
	197, 200, 203, 206, 208, 210, 212, 215, 
	218, 221, 224, 227, 230, 232, 234, 236, 
	239, 242, 252, 261, 270, 279, 289, 299, 
	301, 304, 315, 317, 326, 335, 344, 354, 
	364, 366, 369, 380, 389, 400, 411, 422, 
	433, 444, 455, 466, 475, 485, 495, 497, 
	500, 511, 521, 531, 542, 552, 562, 572, 
	583, 593, 603, 613, 624, 634, 643, 654, 
	665, 676, 687, 698, 709, 720, 729, 739, 
	749, 751, 754, 765, 775, 785, 796, 806, 
	808, 810, 813, 815, 818, 820, 822, 825, 
	828, 831, 834, 837, 840, 843, 846, 849, 
	852, 855, 858, 861, 864, 867, 870, 872, 
	874, 877, 887, 897, 907, 918, 928, 930, 
	933, 943, 953, 964, 974, 984, 996, 1008, 
	1020, 1032, 1044, 1056, 1068, 1078, 1089, 1099, 
	1101, 1104, 1114, 1124, 1135, 1145, 1146, 1147, 
	1148, 1149, 1151, 1152, 1163, 1166, 1169
]

class << self
	attr_accessor :_ami_protocol_parser_trans_targs
	private :_ami_protocol_parser_trans_targs, :_ami_protocol_parser_trans_targs=
end
self._ami_protocol_parser_trans_targs = [
	2, 29, 40, 29, 40, 0, 3, 0, 
	4, 0, 5, 0, 6, 0, 7, 0, 
	8, 0, 9, 0, 10, 0, 11, 0, 
	12, 0, 13, 0, 14, 0, 15, 0, 
	16, 0, 17, 0, 18, 0, 19, 0, 
	20, 0, 21, 0, 22, 0, 23, 0, 
	24, 0, 25, 96, 0, 26, 0, 27, 
	95, 0, 28, 0, 29, 40, 29, 40, 
	0, 30, 30, 0, 31, 31, 0, 32, 
	32, 0, 33, 33, 0, 34, 0, 35, 
	0, 37, 36, 37, 36, 38, 37, 36, 
	39, 0, 213, 0, 41, 41, 0, 42, 
	42, 0, 43, 43, 0, 44, 44, 0, 
	45, 45, 0, 46, 46, 0, 47, 47, 
	0, 48, 0, 49, 0, 50, 70, 80, 
	86, 50, 80, 86, 0, 51, 51, 0, 
	52, 52, 0, 53, 53, 0, 54, 54, 
	0, 55, 0, 56, 0, 57, 57, 0, 
	58, 58, 0, 59, 59, 0, 60, 60, 
	0, 61, 61, 0, 62, 62, 0, 63, 
	63, 0, 64, 0, 65, 0, 67, 66, 
	67, 66, 68, 67, 66, 69, 0, 214, 
	0, 71, 0, 72, 0, 73, 0, 74, 
	0, 75, 0, 76, 0, 77, 0, 78, 
	0, 79, 0, 215, 0, 81, 81, 0, 
	82, 82, 0, 83, 83, 0, 84, 0, 
	85, 0, 39, 0, 87, 87, 0, 88, 
	88, 0, 89, 89, 0, 90, 90, 0, 
	91, 91, 0, 92, 92, 0, 93, 0, 
	94, 0, 39, 0, 27, 95, 0, 25, 
	96, 0, 142, 142, 98, 141, 98, 141, 
	98, 141, 98, 0, 101, 99, 100, 99, 
	100, 99, 100, 99, 0, 101, 99, 100, 
	99, 100, 99, 100, 99, 0, 101, 99, 
	100, 99, 100, 99, 100, 99, 0, 102, 
	101, 99, 100, 99, 100, 99, 100, 99, 
	0, 104, 139, 137, 138, 137, 138, 137, 
	138, 137, 103, 104, 103, 105, 104, 103, 
	106, 116, 116, 107, 115, 107, 115, 107, 
	115, 107, 0, 216, 0, 110, 108, 109, 
	108, 109, 108, 109, 108, 0, 110, 108, 
	109, 108, 109, 108, 109, 108, 0, 110, 
	108, 109, 108, 109, 108, 109, 108, 0, 
	111, 110, 108, 109, 108, 109, 108, 109, 
	108, 0, 113, 135, 133, 134, 133, 134, 
	133, 134, 133, 112, 113, 112, 114, 113, 
	112, 106, 116, 116, 107, 115, 107, 115, 
	107, 115, 107, 0, 110, 108, 109, 108, 
	109, 108, 109, 108, 0, 110, 117, 117, 
	108, 109, 108, 109, 108, 109, 108, 0, 
	110, 118, 118, 108, 109, 108, 109, 108, 
	109, 108, 0, 110, 119, 119, 108, 109, 
	108, 109, 108, 109, 108, 0, 110, 120, 
	120, 108, 109, 108, 109, 108, 109, 108, 
	0, 110, 121, 121, 108, 109, 108, 109, 
	108, 109, 108, 0, 110, 122, 122, 108, 
	109, 108, 109, 108, 109, 108, 0, 110, 
	123, 123, 108, 109, 108, 109, 108, 109, 
	108, 0, 124, 108, 109, 108, 109, 108, 
	109, 108, 0, 125, 110, 108, 109, 108, 
	109, 108, 109, 108, 0, 127, 131, 129, 
	130, 129, 130, 129, 130, 129, 126, 127, 
	126, 128, 127, 126, 106, 116, 116, 107, 
	115, 107, 115, 107, 115, 107, 0, 127, 
	131, 129, 130, 129, 130, 129, 130, 129, 
	126, 127, 131, 129, 130, 129, 130, 129, 
	130, 129, 126, 127, 132, 131, 129, 130, 
	129, 130, 129, 130, 129, 126, 127, 131, 
	129, 130, 129, 130, 129, 130, 129, 126, 
	113, 135, 133, 134, 133, 134, 133, 134, 
	133, 112, 113, 135, 133, 134, 133, 134, 
	133, 134, 133, 112, 113, 136, 135, 133, 
	134, 133, 134, 133, 134, 133, 112, 113, 
	135, 133, 134, 133, 134, 133, 134, 133, 
	112, 104, 139, 137, 138, 137, 138, 137, 
	138, 137, 103, 104, 139, 137, 138, 137, 
	138, 137, 138, 137, 103, 104, 140, 139, 
	137, 138, 137, 138, 137, 138, 137, 103, 
	104, 139, 137, 138, 137, 138, 137, 138, 
	137, 103, 101, 99, 100, 99, 100, 99, 
	100, 99, 0, 101, 143, 143, 99, 100, 
	99, 100, 99, 100, 99, 0, 101, 144, 
	144, 99, 100, 99, 100, 99, 100, 99, 
	0, 101, 145, 145, 99, 100, 99, 100, 
	99, 100, 99, 0, 101, 146, 146, 99, 
	100, 99, 100, 99, 100, 99, 0, 101, 
	147, 147, 99, 100, 99, 100, 99, 100, 
	99, 0, 101, 148, 148, 99, 100, 99, 
	100, 99, 100, 99, 0, 101, 149, 149, 
	99, 100, 99, 100, 99, 100, 99, 0, 
	150, 99, 100, 99, 100, 99, 100, 99, 
	0, 151, 101, 99, 100, 99, 100, 99, 
	100, 99, 0, 153, 157, 155, 156, 155, 
	156, 155, 156, 155, 152, 153, 152, 154, 
	153, 152, 106, 116, 116, 107, 115, 107, 
	115, 107, 115, 107, 0, 153, 157, 155, 
	156, 155, 156, 155, 156, 155, 152, 153, 
	157, 155, 156, 155, 156, 155, 156, 155, 
	152, 153, 158, 157, 155, 156, 155, 156, 
	155, 156, 155, 152, 153, 157, 155, 156, 
	155, 156, 155, 156, 155, 152, 161, 160, 
	161, 160, 162, 161, 160, 163, 160, 217, 
	161, 160, 218, 0, 166, 165, 167, 166, 
	165, 166, 168, 165, 166, 169, 165, 166, 
	170, 165, 166, 171, 165, 166, 172, 165, 
	166, 173, 165, 166, 174, 165, 166, 175, 
	165, 166, 176, 165, 166, 177, 165, 166, 
	178, 165, 166, 179, 165, 166, 180, 165, 
	166, 181, 165, 166, 182, 165, 183, 219, 
	219, 219, 220, 166, 165, 166, 188, 186, 
	187, 186, 187, 186, 187, 186, 165, 166, 
	188, 186, 187, 186, 187, 186, 187, 186, 
	165, 166, 188, 186, 187, 186, 187, 186, 
	187, 186, 165, 166, 189, 188, 186, 187, 
	186, 187, 186, 187, 186, 165, 191, 194, 
	192, 193, 192, 193, 192, 193, 192, 190, 
	191, 190, 221, 191, 190, 191, 194, 192, 
	193, 192, 193, 192, 193, 192, 190, 191, 
	194, 192, 193, 192, 193, 192, 193, 192, 
	190, 191, 195, 194, 192, 193, 192, 193, 
	192, 193, 192, 190, 191, 194, 192, 193, 
	192, 193, 192, 193, 192, 190, 166, 188, 
	186, 187, 186, 187, 186, 187, 186, 165, 
	166, 188, 198, 198, 186, 187, 186, 187, 
	186, 187, 186, 165, 166, 188, 199, 199, 
	186, 187, 186, 187, 186, 187, 186, 165, 
	166, 188, 200, 200, 186, 187, 186, 187, 
	186, 187, 186, 165, 166, 188, 201, 201, 
	186, 187, 186, 187, 186, 187, 186, 165, 
	166, 188, 202, 202, 186, 187, 186, 187, 
	186, 187, 186, 165, 166, 188, 203, 203, 
	186, 187, 186, 187, 186, 187, 186, 165, 
	166, 188, 204, 204, 186, 187, 186, 187, 
	186, 187, 186, 165, 166, 205, 186, 187, 
	186, 187, 186, 187, 186, 165, 166, 206, 
	188, 186, 187, 186, 187, 186, 187, 186, 
	165, 208, 211, 209, 210, 209, 210, 209, 
	210, 209, 207, 208, 207, 222, 208, 207, 
	208, 211, 209, 210, 209, 210, 209, 210, 
	209, 207, 208, 211, 209, 210, 209, 210, 
	209, 210, 209, 207, 208, 212, 211, 209, 
	210, 209, 210, 209, 210, 209, 207, 208, 
	211, 209, 210, 209, 210, 209, 210, 209, 
	207, 0, 0, 0, 0, 164, 0, 0, 
	184, 197, 197, 185, 196, 185, 196, 185, 
	196, 185, 165, 166, 168, 165, 166, 168, 
	165, 166, 168, 165, 219, 219, 219, 219, 
	219, 219, 219, 219, 219, 219, 219, 219, 
	219, 219, 219, 219, 219, 219, 219, 219, 
	219, 219, 0
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
	19, 68, 29, 31, 0, 0, 31, 0, 
	0, 19, 17, 19, 0, 0, 19, 0, 
	0, 19, 0, 0, 19, 0, 0, 19, 
	0, 0, 19, 0, 0, 19, 0, 0, 
	19, 0, 19, 0, 19, 0, 0, 0, 
	0, 0, 0, 0, 19, 0, 0, 19, 
	0, 0, 19, 0, 0, 19, 0, 0, 
	19, 0, 19, 0, 19, 0, 0, 19, 
	0, 0, 19, 0, 0, 19, 0, 0, 
	19, 0, 0, 19, 0, 0, 19, 0, 
	0, 19, 0, 19, 13, 19, 0, 0, 
	0, 0, 0, 0, 0, 0, 19, 15, 
	19, 0, 19, 0, 19, 0, 19, 0, 
	19, 0, 19, 0, 19, 0, 19, 33, 
	19, 0, 19, 0, 19, 0, 0, 19, 
	0, 0, 19, 0, 0, 19, 23, 19, 
	0, 19, 0, 19, 0, 0, 19, 0, 
	0, 19, 0, 0, 19, 0, 0, 19, 
	0, 0, 19, 0, 0, 19, 23, 19, 
	0, 19, 0, 19, 3, 0, 0, 0, 
	0, 0, 5, 5, 5, 5, 5, 5, 
	5, 5, 5, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 53, 50, 9, 9, 9, 9, 9, 
	9, 9, 9, 11, 0, 0, 11, 0, 
	0, 5, 5, 5, 5, 5, 5, 5, 
	5, 5, 0, 17, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 53, 50, 9, 9, 9, 9, 
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
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 102, 90, 59, 
	59, 59, 59, 59, 59, 59, 59, 62, 
	0, 0, 62, 0, 0, 5, 5, 5, 
	5, 5, 5, 5, 5, 5, 0, 62, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 62, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 62, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 94, 50, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	11, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 11, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 11, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 53, 
	50, 9, 9, 9, 9, 9, 9, 9, 
	9, 11, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 11, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 11, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	53, 50, 9, 9, 9, 9, 9, 9, 
	9, 9, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 102, 90, 59, 59, 59, 
	59, 59, 59, 59, 59, 62, 0, 0, 
	62, 0, 0, 5, 5, 5, 5, 5, 
	5, 5, 5, 5, 0, 62, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 62, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 62, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 94, 50, 9, 9, 
	9, 9, 9, 9, 9, 9, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 21, 
	0, 0, 21, 0, 27, 0, 0, 27, 
	0, 27, 0, 0, 27, 0, 0, 27, 
	0, 0, 27, 0, 0, 27, 0, 0, 
	27, 0, 0, 27, 0, 0, 27, 0, 
	0, 27, 0, 0, 27, 0, 0, 27, 
	0, 0, 27, 0, 0, 27, 0, 0, 
	27, 0, 0, 27, 0, 0, 0, 45, 
	71, 45, 83, 27, 0, 27, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 27, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 27, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 27, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 86, 50, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	56, 0, 80, 56, 0, 56, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 56, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 56, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 86, 50, 9, 9, 
	9, 9, 9, 9, 9, 9, 27, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	27, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 27, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	27, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 27, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	27, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 27, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	27, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 27, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 27, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 112, 90, 59, 59, 59, 59, 59, 
	59, 59, 59, 98, 0, 77, 98, 0, 
	98, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 98, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 98, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 107, 
	50, 9, 9, 9, 9, 9, 9, 9, 
	9, 19, 19, 19, 0, 0, 0, 0, 
	65, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 25, 27, 0, 0, 27, 0, 
	0, 27, 0, 0, 45, 45, 45, 45, 
	45, 45, 45, 45, 45, 45, 45, 45, 
	45, 45, 45, 45, 45, 45, 45, 43, 
	41, 39, 0
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
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 35, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
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
	0, 0, 0, 74, 0, 0, 0
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
	0, 0, 0, 37, 0, 0, 0
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
	19, 19, 19, 19, 19, 19, 19, 0, 
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
	0, 0, 0, 0, 0, 0, 0
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
	0, 0, 0, 0, 0, 1191, 1191, 1191, 
	1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 
	1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 1192, 1193, 1194
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
self.ami_protocol_parser_en_success = 97;
class << self
	attr_accessor :ami_protocol_parser_en_error_recovery
end
self.ami_protocol_parser_en_error_recovery = 159;
class << self
	attr_accessor :ami_protocol_parser_en_response_follows
end
self.ami_protocol_parser_en_response_follows = 219;


# line 864 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
    
# line 889 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
			when 22 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_start =  @current_pointer
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 924 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
		 @current_state = 159
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
		 @current_state = 219
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 59 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 19 then
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
when 23 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 24 then
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 1;		end
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 25 then
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 2;		end
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 26 then
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 4;		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 27 then
# line 50 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 50 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 28 then
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 48 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 29 then
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 49 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 30 then
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 31 then
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
# line 1197 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
when 20 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_start = nil;		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 21 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 0
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 1224 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
		 @current_state = 159
		_trigger_goto = true
		_goto_level = _again
		break
	end

    		end
# line 36 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
# line 1269 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
    puts "Syntax error"
    view_buffer
    @current_syntax_error_start = @current_pointer + 1 # Adding 1 since the pointer is still set to the last successful match
  end
  
  def end_ignoring_syntax_error
    # Subtracting 3 from @current_pointer below for "\r\n\r" which separates a stanza
    offending_data = @data[@current_syntax_error_start...@current_pointer - 3]
    view_buffer
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
  
  def view_buffer
    buffer = @data.clone
    buffer.insert(@current_pointer, "^")
    # buffer.gsub("\r", "\\r\r")
    # buffer.gsub("\n", "\\n\n")
    puts <<-INSPECTION

VVVVVVVVVVVVVVVVVVVVVVVVVVVVV
####  Viewing the buffer ####
#############################
#{buffer}
#############################
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    INSPECTION
  end
  
end
