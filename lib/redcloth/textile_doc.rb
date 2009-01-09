module RedCloth
  class TextileDoc < String
    #
    # Accessors for setting security restrictions.
    #
    # This is a nice thing if you're using RedCloth for
    # formatting in public places (e.g. Wikis) where you
    # don't want users to abuse HTML for bad things.
    #
    # If +:filter_html+ is set, HTML which wasn't
    # created by the Textile processor will be escaped.
    # Alternatively, if +:sanitize_html+ is set, 
    # HTML can pass through the Textile processor but
    # unauthorized tags and attributes will be removed.
    #
    # If +:filter_styles+ is set, it will also disable
    # the style markup specifier. ('{color: red}')
    #
    # If +:filter_classes+ is set, it will also disable
    # class attributes. ('!(classname)image!')
    #
    # If +:filter_ids+ is set, it will also disable
    # id attributes. ('!(classname#id)image!')
    #
    attr_accessor :filter_html, :sanitize_html, :filter_styles, :filter_classes, :filter_ids

    #
    # Deprecated accessor for toggling hard breaks.
    #
    # Traditional RedCloth converted single newlines
    # to HTML break tags, but later versions required
    # +:hard_breaks+ be set to enable this behavior.
    # +:hard_breaks+ is once again the default. The
    # accessor is deprecated and will be removed in a
    # future version.
    #
    attr_accessor :hard_breaks

    # Accessor for toggling lite mode.
    #
    # In lite mode, block-level rules are ignored.  This means
    # that tables, paragraphs, lists, and such aren't available.
    # Only the inline markup for bold, italics, entities and so on.
    #
    #   r = RedCloth.new( "And then? She *fell*!", [:lite_mode] )
    #   r.to_html
    #   #=> "And then? She <strong>fell</strong>!"
    #
    attr_accessor :lite_mode
    
    # Accessor for toggling BBCode
    attr_accessor :bbcode
    
    def bbcode=(boolean)
      #link_aliases seriously mess up bbcode, so they MUST be disabled if using BBCode.
      boolean ? (@disable_inline << :link_alias) : @disable_inline.delete(:link_alias)
      @no_span_caps = true
      @bbcode = boolean
    end
    
    # Accessor for toggling BBCode only
    attr_accessor :bbcode_only

    #
    # Accessor for toggling span caps.
    #
    # Textile places `span' tags around capitalized
    # words by default, but this wreaks havoc on Wikis.
    # If +:no_span_caps+ is set, this will be
    # suppressed.
    #
    attr_accessor :no_span_caps
    
    #
    # Accessor for disabling inline elements.
    #
    # Depending upon the needs of the application,
    # some inline elements, such as images, may be
    # disabled using the array in +:disable_inline+.
    #
    #   RedCloth.new( "Images should *not* be allowed! !test_image.jpg!" ).to_html
    #     #=> "<p>Images should <strong>not</strong> be allowed! <img src=\"test_image.jpg\" alt=\"\" /></p>"
    #   RedCloth.new( "Images should *not* be allowed! !test_image.jpg!", [:disable_inline=>:image] ).to_html
    #     #=> "<p>Images should <strong>not</strong> be allowed! !test_image.jpg!</p>"
    #   RedCloth.new( "Images should *not* be allowed! !test_image.jpg!", [:disable_inline=>[:image,:strong]] ).to_html
    #     #=> "<p>Images should *not* be allowed! !test_image.jpg!</p>"
    #
    attr_accessor :disable_inline
    
    #
    # Insures that disable_inline is an Array
    #
    def disable_inline=(disablers)
      disablers.is_a?(Array) ?
        @disable_inline = disablers :
        @disable_inline = [disablers]
    end

    # Returns a new RedCloth object, based on _string_, observing 
    # any _restrictions_ specified.
    #
    #   r = RedCloth.new( "h1. A *bold* man" )
    #     #=> "h1. A *bold* man"
    #   r.to_html
    #     #=>"<h1>A <b>bold</b> man</h1>"
    #
    def initialize( string, restrictions = [] )
      @disable_inline = []
      restrictions.each do |r|
        case r
          when Hash
            r.each {|k,v| method("#{k}=").call( v )}
          else
            method("#{r}=").call( true )
        end
      end
      super( string )
    end

    #
    # Generates HTML from the Textile contents.
    #
    #   RedCloth.new( "And then? She *fell*!" ).to_html
    #     #=>"<p>And then? She <strong>fell</strong>!</p>"
    #
    def to_html( *rules )
      apply_rules(rules)
  
      to(RedCloth::Formatters::HTML)
    end

    #
    # Generates LaTeX from the Textile contents.
    #
    #   RedCloth.new( "And then? She *fell*!" ).to_latex
    #     #=> "And then? She \\textbf{fell}!\n\n"
    #
    def to_latex( *rules )
      apply_rules(rules)
  
      to(RedCloth::Formatters::LATEX)
    end

    private
    def apply_rules(rules)
      rules.each do |r|
        method(r).call(self) if self.respond_to?(r)
      end
    end
  end
end