module Adhearsion
  module VoIP
    module Conveniences

      # Compiles the provided Asterisk dialplan pattern into a Ruby regular
      # expression. For more usage of Asterisk's pattern syntax, see
      # http://www.voip-info.org/wiki/view/Asterisk+Dialplan+Patterns
      def _(pattern)
        # Uncomment the following code fragment for complete compatibility.
        # The fragment handles the seldom-used hyphen number spacer with no
        # meaning.
      	Regexp.new '^' << pattern.# gsub(/(?!\[[\w+-]+)-(?![\w-]+\])/,'').
      	  gsub('X', '[0-9]').gsub('Z', '[1-9]').gsub('N','[2-9]').
      	  gsub('.','.+').gsub('!','.*') << '$'
      end
    end
  end
end