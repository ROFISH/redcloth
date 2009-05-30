/*
 * redcloth_inline.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
%%{

  machine redcloth_inline;
  include redcloth_bbcode_inline "redcloth_bbcode_inline.rl";

  # html
  start_tag_noactions = "<" Name space+ AttrSet* (AttrEnd)? ">" | "<" Name ">" ;
  empty_tag_noactions = "<" Name space+ AttrSet* (AttrEnd)? "/>" | "<" Name "/>" ;
  end_tag_noactions = "</" Name space* ">" ;
  any_tag_noactions = ( start_tag_noactions | empty_tag_noactions | end_tag_noactions ) ;
  
  start_tag = start_tag_noactions >X >A %T ;
  empty_tag = empty_tag_noactions >X >A %T ;
  end_tag = end_tag_noactions >X >A %T ;
  html_comment = ("<!--" (default+) :>> "-->") >X >A %T;
  html_break = ("<br" space* AttrSet* (AttrEnd)? "/"? ">" LF?) >X >A %T ;
  
  # links
  link_text_char = (default - [ "<>]) ;
  link_text_char_or_tag = ( link_text_char | any_tag_noactions ) ;
  link_mtext = ( link_text_char+ (mspace link_text_char+)* ) ;
  quoted_mtext = '"' link_mtext '"' ;
  link_mtext_including_tags = ( link_text_char_or_tag+ (mspace link_text_char_or_tag+)* ) ;
  mtext_including_quotes = (link_mtext ' "' link_mtext '" ' link_mtext?)+ ;
  link_says = ( C_noactions "."* " "* (quoted_mtext | mtext_including_quotes | link_mtext_including_tags ) ) >A %{ STORE("name"); } ;
  link_says_noquotes_noactions = ( C_noquotes_noactions "."* " "* ((link_mtext) -- '":') ) ;
  link = ( '"' link_says :>> '":' %A uri %{ STORE_URL("href"); } ) >X ;
  link_noquotes_noactions = ( '"' link_says_noquotes_noactions '":' uri ) ;
  bracketed_link = ( '["' link_says '":' %A uri %{ STORE("href"); } :> "]" ) >X ;

  # images
  image_src = ( uri ) >A %{ STORE("src"); } ;
  image_is = ( A2 C ". "? image_src :> title? ) ;
  image_link = ( ":" uri >A %{ STORE_URL("href"); } ) ;
  image = ( "!" image_is "!" %A image_link? ) >X %SET_ATTR ;
  bracketed_image = ( "[!" image_is "!" %A image_link? "]" ) >X %SET_ATTR ;

  # footnotes
  footno = "[" >X %A digit+ %T "]" ;

  # markup
  end_markup_phrase = (" " | PUNCT | EOF | LF) @{ fhold; };
  code = ("@" >X mtext >A %T :> "@") | ("[@" >X default+ >A %T :>> "@]") ;
  script_tag = ( "<script" [^>]* ">" (default+ -- "</script>") "</script>" LF? ) >X >A %T ;
  strong = "["? "*" >X mtext >A %T :> "*" "]"? ;
  b = "["? "**" >X mtext >A %T :> "**" "]"? ;
  mtext_excluding_underscore = mtext -- "_" ;
  emtext = mtext_excluding_underscore ("_" mtext_excluding_underscore)*;
  em = "["? "_" >X emtext >A %T "_" "]"? ;
  i = "["? "__" >X emtext >A %T :>> ("__" "]"?) ;
  del = "[-" >X C ( mtext ) >A %T :>> "-]" ;
  emdash_parenthetical_phrase_with_spaces = " -- " mtext " -- " ;
  del_phrase = (( " " >A %{ STORE("beginning_space"); } "-" | "-" when starts_line) >X C ( mtext ) >A %T :>> ( "-" end_markup_phrase )) - emdash_parenthetical_phrase_with_spaces ;
  ins = "["? "+" >X mtext >A %T :> "+" "]"? ;
  sup = "[^" >X mtext >A %T :> "^]" ;
  sup_phrase = ( "^" when starts_phrase) >X ( mtext ) >A %T :>> ( "^" end_markup_phrase ) ;
  sub = "[~" >X mtext >A %T :> "~]" ;
  sub_phrase = ( "~" when starts_phrase) >X ( mtext ) >A %T :>> ( "~" end_markup_phrase ) ;
  span = "[%" >X mtext >A %T :> "%]" ;
  span_phrase = (("%" when starts_phrase) >X ( mtext ) >A %T :>> ( "%" end_markup_phrase )) ;
  cite = "["? "??" >X mtext >A >ATTR :>> ("?" @T ( "?" | "?" @{ STORE_ATTR("text"); } "?" %SET_ATTR ))  "]"? ;
  ignore = "["? "==" >X %A mtext %T :> "==" "]"? ;
  snip = "["? "```" >X %A mtext %T :> "```" "]"? ;
  
  bbcode_tag = "[";
  
  # quotes
  quote1 = "'" >X %A mtext %T :> "'" ;
  non_quote_chars_or_link = (chars -- '"') | link_noquotes_noactions ;
  mtext_inside_quotes = ( non_quote_chars_or_link (mspace non_quote_chars_or_link)* ) ;
  html_tag_up_to_attribute_quote = "<" Name space+ NameAttr space* "=" space* ;
  quote2 = ('"' >X %A ( mtext_inside_quotes - (mtext_inside_quotes html_tag_up_to_attribute_quote ) ) %T :> '"' ) ;
  multi_paragraph_quote = (('"' when starts_line) >X  %A ( chars -- '"' ) %T );
  
  # glyphs
  ellipsis = ( " "? >A %T "..." ) >X ;
  emdash = "--" ;
  arrow = "->" ;
  endash = " - " ;
  acronym = ( [A-Z] >A [A-Z0-9]{2,} %T "(" default+ >A %{ STORE("title"); } :> ")" ) >X ;
  caps_noactions = upper{3,} ;
  caps = ( caps_noactions >A %*T ) >X ;
  dim_digit = [0-9.]+ ;
  prime = ("'" | '"')?;
  dim_noactions = dim_digit prime (("x" | " x ") dim_digit prime) %T (("x" | " x ") dim_digit prime)? ;
  dim = dim_noactions >X >A %T ;
  tm = [Tt] [Mm] ;
  trademark = " "? ( "[" tm "]" | "(" tm ")" ) ;
  reg = [Rr] ;
  registered = " "? ( "[" reg "]" | "(" reg ")" ) ;
  cee = [Cc] ;
  copyright = ( "[" cee "]" | "(" cee ")" ) ;
  entity = ( "&" %A ( '#' digit+ | ( alpha ( alpha | digit )+ ) ) %T ';' ) >X ;

  direct_uri = "http" "s"? "://" uchar+ absolute_path?;
  automatic_url = (direct_uri -- '[' -- ']') >X >A %{ STORE_URL("href"); } ;

  
  # info
  redcloth_version = "[RedCloth::VERSION]" ;

  other_phrase = phrase -- dim_noactions;

  code_tag := |*
    code_tag_end { CAT(block); fgoto main; };
    default => esc_pre;
  *|;

  main := |*
    image { UNLESS_DISABLED_INLINE(block,image,INLINE(block, "image");) };
    bracketed_image { UNLESS_DISABLED_INLINE(block,image,INLINE(block, "image");) };
    
    link { UNLESS_DISABLED_INLINE(block,link,PARSE_LINK_ATTR("name"); PASS(block, "name", "link");) };
    bracketed_link { UNLESS_DISABLED_INLINE(block,bracketed_link,PARSE_LINK_ATTR("name"); PASS(block, "name", "link");) };
    
    code { UNLESS_DISABLED_INLINE(block,code,PASS_CODE(block, "text", "code");) };
    code_tag_start { CAT(block); fgoto code_tag; };
    notextile { INLINE(block, "notextile"); };
    strong { UNLESS_DISABLED_INLINE(block,strong,PARSE_ATTR("text"); PASS(block, "text", "strong");) };
    b { UNLESS_DISABLED_INLINE(block,b,PARSE_ATTR("text"); PASS(block, "text", "b");) };
    em { UNLESS_DISABLED_INLINE(block,em,PARSE_ATTR("text"); PASS(block, "text", "em");) };
    i { UNLESS_DISABLED_INLINE(block,i,PARSE_ATTR("text"); PASS(block, "text", "i");) };
    del { UNLESS_DISABLED_INLINE(block,del,PASS(block, "text", "del");) };
    del_phrase { UNLESS_DISABLED_INLINE(block,del,PASS(block, "text", "del_phrase");) };
    ins { UNLESS_DISABLED_INLINE(block,ins,PARSE_ATTR("text"); PASS(block, "text", "ins");) };
    sup { UNLESS_DISABLED_INLINE(block,sup,PARSE_ATTR("text"); PASS(block, "text", "sup");) };
    sup_phrase { UNLESS_DISABLED_INLINE(block,sup,PARSE_ATTR("text"); PASS(block, "text", "sup_phrase");) };
    sub { UNLESS_DISABLED_INLINE(block,sub,PARSE_ATTR("text"); PASS(block, "text", "sub");) };
    sub_phrase { UNLESS_DISABLED_INLINE(block,sub,PARSE_ATTR("text"); PASS(block, "text", "sub_phrase");) };
    span { UNLESS_DISABLED_INLINE(block,span,PARSE_ATTR("text"); PASS(block, "text", "span");) };
    span_phrase { UNLESS_DISABLED_INLINE(block,span,PARSE_ATTR("text"); PASS(block, "text", "span_phrase");) };
    cite { UNLESS_DISABLED_INLINE(block,cite,PARSE_ATTR("text"); PASS(block, "text", "cite");) };
    ignore => ignore;
    snip { UNLESS_DISABLED_INLINE(block,snip,PASS(block, "text", "snip");) };
    quote1 { UNLESS_DISABLED_INLINE(block,quote1,PASS(block, "text", "quote1");) };
    quote2 { UNLESS_DISABLED_INLINE(block,quote2,PASS(block, "text", "quote2");) };
    multi_paragraph_quote { UNLESS_DISABLED_INLINE(block,multi_paragraph_quote,PASS(block, "text", "multi_paragraph_quote");) };
    
    ellipsis { UNLESS_DISABLED_INLINE(block,ellipsis,INLINE(block, "ellipsis");) };
    emdash { UNLESS_DISABLED_INLINE(block,emdash,INLINE(block, "emdash");) };
    endash { UNLESS_DISABLED_INLINE(block,endash,INLINE(block, "endash");) };
    arrow { UNLESS_DISABLED_INLINE(block,arrow,INLINE(block, "arrow");) };
    caps { UNLESS_DISABLED_INLINE(block,caps,INLINE(block, "caps");) };
    acronym { UNLESS_DISABLED_INLINE(block,acronym,INLINE(block, "acronym");) };
    dim { UNLESS_DISABLED_INLINE(block,dim,INLINE(block, "dim");) };
    trademark { UNLESS_DISABLED_INLINE(block,trademark,INLINE(block, "trademark");) };
    registered { UNLESS_DISABLED_INLINE(block,registered,INLINE(block, "registered");) };
    copyright { UNLESS_DISABLED_INLINE(block,copyright,INLINE(block, "copyright");) };
    footno { UNLESS_DISABLED_INLINE(block,footno,PASS(block, "text", "footno");) };
    entity { UNLESS_DISABLED_INLINE(block,entity,INLINE(block, "entity");) };
    
    script_tag { INLINE(block, "inline_html"); };
    start_tag { INLINE(block, "inline_html"); };
    end_tag { INLINE(block, "inline_html"); };
    empty_tag { INLINE(block, "inline_html"); };
    html_comment { INLINE(block, "inline_html"); };
    html_break { INLINE(block, "inline_html"); };
    
    redcloth_version { INLINE(block, "inline_redcloth_version"); };
    
    automatic_url { UNLESS_DISABLED_INLINE(block,link,PASS(block, "name", "link");) };
    
    bbcode_tag => {
      if(BBCODE_ENABLED()) {
        //hold required because p gets advanced on a string match and we want to start parsing bbcode with the staring [ bracket.
        //printf("bbcode_tag '%s'\n", p);
        fhold;
        fcall bbcode_inline;
      }
      else {
        rb_str_cat_escaped(self, block, ts, te);
      }
    };
    other_phrase => esc;
    PUNCT => esc;
    space => esc;
    
    EOF;
    
  *|;

}%%;
