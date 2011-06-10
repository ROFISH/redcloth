module RedCloth
  module VERSION
    MAJOR = 0
    MINOR = 8
    TINY  = 3
    RELEASE_CANDIDATE = nil

    STRING = [MAJOR, MINOR, TINY].join('.')
    TAG = "REL_#{[MAJOR, MINOR, TINY, RELEASE_CANDIDATE].compact.join('_')}".upcase.gsub(/\.|-/, '_')
    FULL_VERSION = "#{[MAJOR, MINOR, TINY, RELEASE_CANDIDATE].compact.join('.')}"
    
    class << self
      def to_s
        STRING
      end
      
      def ==(arg)
        STRING == arg
      end
    end
  end
  
  NAME = "BBRedCloth"
  GEM_NAME = NAME
  URL  = "http://redcloth.org/"

  DESCRIPTION = "#{NAME}-#{VERSION::FULL_VERSION} - Textile parser for Ruby. Includes BBCode additions.\n#{URL}"
end