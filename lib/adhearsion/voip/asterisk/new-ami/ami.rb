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
	9, 1, 10, 1, 11, 1, 12, 1, 
	13, 1, 14, 1, 15, 1, 16, 1, 
	21, 1, 23, 1, 24, 1, 25, 1, 
	26, 1, 28, 1, 29, 1, 30, 1, 
	31, 1, 34, 1, 35, 1, 36, 1, 
	37, 1, 38, 2, 2, 12, 2, 3, 
	4, 2, 4, 5, 2, 7, 27, 2, 
	8, 19, 2, 14, 15, 2, 17, 26, 
	2, 18, 26, 2, 21, 22, 2, 24, 
	32, 3, 24, 20, 33
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
	146, 147, 148, 150, 151, 153, 168, 169, 
	184, 199, 214, 231, 232, 234, 249, 264, 
	281, 297, 313, 330, 331, 333, 335, 337, 
	339, 341, 343, 345, 347, 349, 351, 353, 
	355, 357, 359, 361, 363, 364, 365, 367, 
	383, 399, 415, 432, 433, 435, 451, 467, 
	483, 500, 501, 503, 520, 537, 554, 571, 
	588, 605, 622, 639, 656, 673, 690, 707, 
	724, 741, 757, 772, 787, 804, 805, 807, 
	822, 837, 854, 870, 886, 903, 919, 936, 
	952, 968, 985, 1002, 1018, 1034, 1051, 1067, 
	1072, 1073, 1075, 1077, 1078, 1078, 1093, 1095, 
	1111, 1127
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
	13, 13, 32, 47, 48, 57, 58, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	10, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	58, 32, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 58, 
	32, 47, 48, 57, 59, 64, 65, 90, 
	91, 96, 97, 122, 123, 126, 13, 32, 
	58, 33, 47, 48, 57, 59, 64, 65, 
	90, 91, 96, 97, 122, 123, 126, 13, 
	10, 13, 13, 32, 47, 48, 57, 58, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 58, 32, 47, 48, 57, 59, 64, 
	65, 90, 91, 96, 97, 122, 123, 126, 
	13, 32, 58, 33, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 58, 32, 47, 48, 57, 59, 
	64, 65, 90, 91, 96, 97, 122, 123, 
	126, 13, 32, 58, 33, 47, 48, 57, 
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
	2, 3, 3, 2, 2, 3, 2, 5, 
	1, 2, 2, 1, 0, 1, 2, 2, 
	2, 0
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
	0, 0, 0, 0, 0, 7, 0, 7, 
	7, 7
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
	227, 229, 231, 234, 236, 239, 248, 250, 
	259, 268, 277, 288, 290, 293, 302, 311, 
	322, 332, 342, 353, 355, 358, 361, 364, 
	367, 370, 373, 376, 379, 382, 385, 388, 
	391, 394, 397, 400, 403, 405, 407, 410, 
	420, 430, 440, 451, 453, 456, 466, 476, 
	486, 497, 499, 502, 513, 524, 535, 546, 
	557, 568, 579, 590, 601, 612, 623, 634, 
	645, 656, 666, 675, 684, 695, 697, 700, 
	709, 718, 729, 739, 749, 760, 770, 781, 
	791, 801, 812, 823, 833, 843, 854, 864, 
	870, 872, 875, 878, 880, 881, 890, 893, 
	903, 913
]

class << self
	attr_accessor :_ami_protocol_parser_trans_targs
	private :_ami_protocol_parser_trans_targs, :_ami_protocol_parser_trans_targs=
end
self._ami_protocol_parser_trans_targs = [
	2, 175, 3, 175, 4, 175, 5, 175, 
	6, 175, 7, 175, 8, 175, 9, 175, 
	10, 175, 11, 175, 12, 175, 13, 175, 
	14, 175, 15, 175, 16, 175, 17, 175, 
	18, 175, 19, 175, 20, 175, 21, 175, 
	22, 175, 23, 27, 175, 24, 175, 25, 
	26, 175, 175, 175, 25, 26, 175, 23, 
	27, 175, 29, 29, 175, 30, 30, 175, 
	31, 31, 175, 32, 175, 34, 35, 33, 
	34, 33, 175, 34, 33, 34, 35, 33, 
	37, 37, 175, 38, 38, 175, 39, 39, 
	175, 40, 40, 175, 41, 41, 175, 42, 
	42, 175, 43, 175, 44, 45, 65, 75, 
	80, 45, 75, 80, 175, 44, 45, 65, 
	75, 80, 45, 75, 80, 175, 46, 46, 
	175, 47, 47, 175, 48, 48, 175, 49, 
	49, 175, 50, 175, 51, 175, 52, 52, 
	175, 53, 53, 175, 54, 54, 175, 55, 
	55, 175, 56, 56, 175, 57, 57, 175, 
	58, 58, 175, 59, 175, 61, 64, 60, 
	61, 60, 62, 61, 60, 63, 175, 175, 
	175, 61, 64, 60, 66, 175, 67, 175, 
	68, 175, 69, 175, 70, 175, 71, 175, 
	72, 175, 73, 175, 74, 175, 175, 175, 
	76, 76, 175, 77, 77, 175, 78, 78, 
	175, 79, 175, 175, 175, 81, 81, 175, 
	82, 82, 175, 83, 83, 175, 84, 84, 
	175, 85, 85, 175, 86, 86, 175, 87, 
	175, 175, 175, 90, 89, 90, 89, 91, 
	90, 89, 92, 89, 179, 90, 89, 94, 
	95, 102, 95, 102, 95, 102, 95, 0, 
	180, 0, 98, 96, 97, 96, 97, 96, 
	97, 96, 0, 98, 96, 97, 96, 97, 
	96, 97, 96, 0, 98, 96, 97, 96, 
	97, 96, 97, 96, 0, 100, 103, 106, 
	104, 105, 104, 105, 104, 105, 104, 99, 
	100, 99, 101, 100, 99, 94, 95, 102, 
	95, 102, 95, 102, 95, 0, 98, 96, 
	97, 96, 97, 96, 97, 96, 0, 100, 
	103, 106, 104, 105, 104, 105, 104, 105, 
	104, 99, 100, 106, 104, 105, 104, 105, 
	104, 105, 104, 99, 100, 106, 104, 105, 
	104, 105, 104, 105, 104, 99, 100, 103, 
	106, 104, 105, 104, 105, 104, 105, 104, 
	99, 108, 107, 109, 108, 107, 108, 110, 
	107, 108, 111, 107, 108, 112, 107, 108, 
	113, 107, 108, 114, 107, 108, 115, 107, 
	108, 116, 107, 108, 117, 107, 108, 118, 
	107, 108, 119, 107, 108, 120, 107, 108, 
	121, 107, 108, 122, 107, 108, 123, 107, 
	108, 124, 107, 125, 181, 181, 181, 182, 
	108, 107, 108, 130, 128, 129, 128, 129, 
	128, 129, 128, 107, 108, 130, 128, 129, 
	128, 129, 128, 129, 128, 107, 108, 130, 
	128, 129, 128, 129, 128, 129, 128, 107, 
	132, 170, 173, 171, 172, 171, 172, 171, 
	172, 171, 131, 132, 131, 183, 132, 131, 
	108, 136, 134, 135, 134, 135, 134, 135, 
	134, 107, 108, 136, 134, 135, 134, 135, 
	134, 135, 134, 107, 108, 136, 134, 135, 
	134, 135, 134, 135, 134, 107, 138, 166, 
	169, 167, 168, 167, 168, 167, 168, 167, 
	137, 138, 137, 184, 138, 137, 108, 140, 
	136, 134, 135, 134, 135, 134, 135, 134, 
	107, 108, 136, 141, 134, 135, 134, 135, 
	134, 135, 134, 107, 108, 136, 142, 134, 
	135, 134, 135, 134, 135, 134, 107, 108, 
	136, 143, 134, 135, 134, 135, 134, 135, 
	134, 107, 108, 144, 136, 134, 135, 134, 
	135, 134, 135, 134, 107, 108, 136, 145, 
	134, 135, 134, 135, 134, 135, 134, 107, 
	108, 136, 146, 134, 135, 134, 135, 134, 
	135, 134, 107, 108, 136, 147, 134, 135, 
	134, 135, 134, 135, 134, 107, 108, 136, 
	148, 134, 135, 134, 135, 134, 135, 134, 
	107, 108, 136, 149, 134, 135, 134, 135, 
	134, 135, 134, 107, 108, 136, 150, 134, 
	135, 134, 135, 134, 135, 134, 107, 108, 
	136, 151, 134, 135, 134, 135, 134, 135, 
	134, 107, 108, 152, 136, 134, 135, 134, 
	135, 134, 135, 134, 107, 108, 153, 136, 
	134, 135, 134, 135, 134, 135, 134, 107, 
	125, 156, 154, 155, 154, 155, 154, 155, 
	154, 181, 156, 154, 155, 154, 155, 154, 
	155, 154, 181, 156, 154, 155, 154, 155, 
	154, 155, 154, 181, 158, 161, 164, 162, 
	163, 162, 163, 162, 163, 162, 157, 158, 
	157, 185, 158, 157, 156, 154, 155, 154, 
	155, 154, 155, 154, 181, 156, 154, 155, 
	154, 155, 154, 155, 154, 181, 158, 161, 
	164, 162, 163, 162, 163, 162, 163, 162, 
	157, 158, 164, 162, 163, 162, 163, 162, 
	163, 162, 157, 158, 164, 162, 163, 162, 
	163, 162, 163, 162, 157, 158, 161, 164, 
	162, 163, 162, 163, 162, 163, 162, 157, 
	108, 136, 134, 135, 134, 135, 134, 135, 
	134, 107, 138, 166, 169, 167, 168, 167, 
	168, 167, 168, 167, 137, 138, 169, 167, 
	168, 167, 168, 167, 168, 167, 137, 138, 
	169, 167, 168, 167, 168, 167, 168, 167, 
	137, 138, 166, 169, 167, 168, 167, 168, 
	167, 168, 167, 137, 132, 170, 173, 171, 
	172, 171, 172, 171, 172, 171, 131, 132, 
	173, 171, 172, 171, 172, 171, 172, 171, 
	131, 132, 173, 171, 172, 171, 172, 171, 
	172, 171, 131, 132, 170, 173, 171, 172, 
	171, 172, 171, 172, 171, 131, 108, 130, 
	128, 129, 128, 129, 128, 129, 128, 107, 
	176, 177, 178, 177, 178, 175, 1, 175, 
	28, 28, 175, 36, 36, 175, 92, 89, 
	0, 126, 127, 174, 127, 174, 127, 174, 
	127, 107, 108, 110, 107, 108, 139, 133, 
	165, 133, 165, 133, 165, 133, 107, 108, 
	139, 133, 165, 133, 165, 133, 165, 133, 
	107, 159, 160, 159, 160, 159, 160, 159, 
	181, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	175, 175, 175, 175, 175, 175, 175, 175, 
	181, 181, 181, 181, 181, 181, 181, 181, 
	181, 181, 181, 181, 181, 181, 181, 181, 
	181, 181, 181, 181, 181, 181, 181, 181, 
	181, 181, 181, 181, 181, 181, 181, 181, 
	181, 181, 181, 181, 181, 181, 181, 181, 
	181, 181, 181, 181, 181, 181, 181, 181, 
	181, 181, 181, 181, 181, 181, 181, 181, 
	175, 175, 175, 181, 181, 181, 181, 0
]

class << self
	attr_accessor :_ami_protocol_parser_trans_actions
	private :_ami_protocol_parser_trans_actions, :_ami_protocol_parser_trans_actions=
end
self._ami_protocol_parser_trans_actions = [
	0, 47, 0, 47, 0, 47, 0, 47, 
	0, 47, 0, 47, 0, 47, 0, 47, 
	0, 47, 0, 47, 0, 47, 0, 47, 
	0, 47, 0, 47, 0, 47, 0, 47, 
	0, 47, 0, 47, 0, 47, 0, 47, 
	1, 47, 0, 0, 47, 0, 47, 3, 
	0, 47, 37, 47, 3, 0, 47, 0, 
	0, 47, 0, 0, 47, 0, 0, 47, 
	0, 0, 47, 0, 47, 74, 25, 25, 
	27, 0, 39, 27, 0, 74, 25, 25, 
	0, 0, 47, 0, 0, 47, 0, 0, 
	47, 0, 0, 47, 0, 0, 47, 0, 
	0, 47, 0, 47, 0, 0, 0, 0, 
	0, 0, 0, 0, 47, 0, 0, 0, 
	0, 0, 0, 0, 0, 47, 0, 0, 
	47, 0, 0, 47, 0, 0, 47, 0, 
	0, 47, 0, 47, 0, 47, 0, 0, 
	47, 0, 0, 47, 0, 0, 47, 0, 
	0, 47, 0, 0, 47, 0, 0, 47, 
	0, 0, 47, 0, 47, 13, 13, 13, 
	0, 0, 0, 0, 0, 0, 47, 68, 
	47, 13, 13, 13, 0, 47, 0, 47, 
	0, 47, 0, 47, 0, 47, 0, 47, 
	0, 47, 29, 47, 0, 47, 41, 47, 
	0, 0, 47, 0, 0, 47, 0, 0, 
	47, 19, 47, 80, 47, 0, 0, 47, 
	0, 0, 47, 0, 0, 47, 0, 0, 
	47, 0, 0, 47, 0, 0, 47, 19, 
	47, 77, 47, 15, 15, 0, 0, 0, 
	0, 0, 0, 0, 17, 0, 0, 0, 
	5, 5, 5, 5, 5, 5, 5, 0, 
	71, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 65, 9, 62, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	11, 0, 0, 11, 0, 0, 5, 5, 
	5, 5, 5, 5, 5, 0, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 65, 
	9, 62, 9, 9, 9, 9, 9, 9, 
	9, 9, 11, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 11, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 65, 9, 
	62, 9, 9, 9, 9, 9, 9, 9, 
	9, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 23, 0, 0, 57, 49, 57, 89, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	65, 9, 62, 9, 9, 9, 9, 9, 
	9, 9, 9, 11, 0, 86, 11, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 65, 9, 
	62, 9, 9, 9, 9, 9, 9, 9, 
	9, 11, 0, 86, 11, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
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
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 23, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 55, 7, 0, 0, 0, 0, 0, 
	0, 0, 55, 7, 0, 0, 0, 0, 
	0, 0, 0, 55, 65, 9, 62, 9, 
	9, 9, 9, 9, 9, 9, 9, 11, 
	0, 35, 11, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 55, 7, 0, 0, 
	0, 0, 0, 0, 0, 55, 65, 9, 
	62, 9, 9, 9, 9, 9, 9, 9, 
	9, 11, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 11, 7, 0, 0, 0, 
	0, 0, 0, 0, 0, 65, 9, 62, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	0, 7, 0, 0, 0, 0, 0, 0, 
	0, 0, 65, 9, 62, 9, 9, 9, 
	9, 9, 9, 9, 9, 11, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 11, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 65, 9, 62, 9, 9, 9, 9, 
	9, 9, 9, 9, 65, 9, 62, 9, 
	9, 9, 9, 9, 9, 9, 9, 11, 
	7, 0, 0, 0, 0, 0, 0, 0, 
	0, 11, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 65, 9, 62, 9, 9, 
	9, 9, 9, 9, 9, 9, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	35, 35, 35, 35, 35, 43, 0, 45, 
	0, 0, 45, 0, 0, 45, 0, 0, 
	0, 21, 59, 59, 59, 59, 59, 59, 
	59, 21, 0, 0, 0, 0, 5, 5, 
	5, 5, 5, 5, 5, 5, 0, 0, 
	5, 5, 5, 5, 5, 5, 5, 5, 
	0, 5, 5, 5, 5, 5, 5, 5, 
	51, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	47, 47, 47, 47, 47, 47, 47, 47, 
	57, 57, 57, 57, 57, 57, 57, 57, 
	57, 57, 57, 57, 57, 57, 57, 57, 
	57, 57, 57, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	45, 45, 45, 53, 51, 51, 51, 0
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
	31, 0, 0, 0, 0, 31, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 31, 
	0, 0, 0, 0, 0, 83, 0, 0, 
	0, 0
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
	0, 0, 0, 0, 0, 0, 0, 33, 
	0, 0, 0, 0, 0, 33, 0, 0, 
	0, 0
]

class << self
	attr_accessor :_ami_protocol_parser_eof_trans
	private :_ami_protocol_parser_eof_trans, :_ami_protocol_parser_eof_trans=
end
self._ami_protocol_parser_eof_trans = [
	0, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	1008, 1008, 1008, 1008, 1008, 1008, 1008, 1008, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 1027, 1027, 1027, 1027, 1027, 
	1027, 1027, 1027, 1027, 1027, 1027, 1027, 1027, 
	1027, 1027, 1027, 1027, 1027, 1027, 0, 0, 
	0, 0, 0, 0, 0, 1064, 1064, 1064, 
	1064, 1064, 1064, 1064, 1064, 1064, 1064, 1064, 
	1064, 1064, 1064, 1064, 1064, 1064, 1064, 1064, 
	1064, 1064, 1064, 1064, 1064, 1064, 1064, 1064, 
	1064, 1064, 1064, 1064, 1064, 1064, 1064, 1064, 
	1064, 1064, 0, 0, 0, 0, 0, 0, 
	1067, 1067, 1067, 0, 0, 0, 1068, 1071, 
	1071, 1071
]

class << self
	attr_accessor :ami_protocol_parser_start
end
self.ami_protocol_parser_start = 175;
class << self
	attr_accessor :ami_protocol_parser_error
end
self.ami_protocol_parser_error = 0;

class << self
	attr_accessor :ami_protocol_parser_en_main
end
self.ami_protocol_parser_en_main = 175;
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
self.ami_protocol_parser_en_response_follows = 181;


# line 721 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
    
# line 746 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
# line 781 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
		 @current_state = 175
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
		 @current_state = 175
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
		 @current_state = 181
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
# line 29 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 	begin
		 @current_state = 93
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 29 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 19 then
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 	begin
		 @current_state = 175
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 51 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 20 then
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 message_received; 	begin
		 @current_state = 175
		_trigger_goto = true
		_goto_level = _again
		break
	end
 		end
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 24 then
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 1 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 25 then
# line 41 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 41 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 26 then
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
 begin  message_received @current_message  end
		end
# line 31 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 27 then
# line 43 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 43 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 28 then
# line 44 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 44 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 29 then
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
when 30 then
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
when 31 then
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
when 32 then
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 6;		end
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 33 then
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @ragel_act = 8;		end
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 34 then
# line 56 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer+1
		end
# line 56 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 35 then
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 36 then
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 @token_end =  @current_pointer
 @current_pointer =  @current_pointer - 1;		end
# line 57 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 37 then
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
		begin
 begin  @current_pointer = (( @token_end))-1; end
		end
# line 55 "lib/adhearsion/voip/asterisk/new-ami/ami.rl"
when 38 then
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
# line 1128 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
# line 1155 "lib/adhearsion/voip/asterisk/new-ami/ami.rb"
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
  
  # TODO: Add it to events system.
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
  
  # TODO: Invoke Theatre
  def ami_error!(reason)
    # raise "AMI Error: #{reason}"
  end
  
  # TODO: Invoke Theatre
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