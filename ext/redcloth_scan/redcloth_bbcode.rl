/*
 * redcloth_bbcode.rl
 *
 * Copyright (C) 2009 Ryan Alyea
 */
%%{

  machine redcloth_bbcode;
  
  action cat2html { CAT(html); }
  action failed4html { rb_str_append(block,temp); rb_str_append(block,html); }
  
  b   = "[b]" >X mtext >A %T :> "[/b]" ;
  i   = "[i]" >X mtext >A %T :> "[/i]" ;
  u   = "[u]" >X mtext >A %T :> "[/u]" ;
  s   = "[s]" >X mtext >A %T :> "[/s]" ;
  del = "[del]" >X mtext >A %T :> "[/del]" ;
  ins = "[ins]" >X mtext >A %T :> "[/ins]" ;
  sub = "[sub]" >X mtext >A %T :> "[/sub]" ;
  sup = "[sup]" >X mtext >A %T :> "[/sup]" ;
  notextile = "[notextile]" >X mtext >A %T :> "[/notextile]" ;
  innercolor = ("#"[0-9a-fA-F]{3}|"#"[0-9a-fA-F]{6}|"aqua"|"black"|"blue"|"fuchsia"|"gray"|"green"|"lime"|"maroon"|"navy"|"olive"|"purple"|"red"|"silver"|"teal"|"white"|"yellow"|"orange"|"cyan"|"magenta"|"grey") %{ STORE("color"); };
  color = ("[color=" innercolor >A "]" mtext >A %T :> "[/color]") >X ;
  innersize = space* ( (digit? "."? digit{1,2} ("em"|"pt"|"px"|"%")? )|("xx-small"|"x-small"|"small"|"medium"|"large"|"x-large"|"xx-large"|"smaller"|"larger")) %{ STORE("size"); } space* ;
  size = ("[size=" innersize >A "]" mtext >A %T :> "[/size]") >X ;
  inneralign = space* ("left"|"center"|"right") %{ STORE("align"); } space* ;
  align = ("[align=" inneralign >A "]" mtext >A %T :> "[/align]") >X ;
  acronym = ("[acronym=" mtext %{ STORE("title"); } >A "]" mtext >A %T :> "[/acronym]") >X ;
  
  pre_tag_start = "[pre" [^\]]* "]" (space* "[code]")? ;
  pre_tag_end = ("[/code]" space*)? "[/pre]" LF? ;
  
  quote_tag_start = "[quote" [^\]]* "]" ;
  quote_tag_end =  "[/quote]" LF? ;
  
  dim_digit = [0-9.]+ ;
  prime = ("'" | '"')?;
  dim_noactions = dim_digit prime (("x" | " x ") dim_digit prime) %T (("x" | " x ") dim_digit prime)? ;
  dim = dim_noactions >X >A %T ;
  
  other_phrase = phrase -- dim_noactions;
  
  pre_tag := |*
    pre_tag_end         { rb_str_append(block,rb_str_new2("<pre><code>")); rb_str_append(block,html); rb_str_append(block,rb_str_new2("</code></pre>")); temp = rb_str_new2(""); html = rb_str_new2(""); fgoto main; };
    default => cat2html;
    EOF => failed4html;
  *|;
  
  quote_tag := |*
    quote_tag_end { rb_str_append(block,rb_str_new2("<blockquote>")); rb_str_append(block,redcloth_transform2(self,html)); rb_str_append(block,rb_str_new2("</blockquote>")); temp = rb_str_new2(""); html = rb_str_new2(""); fgoto main; };
    default => cat2html;
    EOF => failed4html;
  *|;
  
  main := |*
  
    b { PARSE_ATTR("text"); PASS(block, "text", "strong"); };
    i { PARSE_ATTR("text"); PASS(block, "text", "em"); };
    u { PARSE_ATTR("text"); PASS(block, "text", "ins"); };
    s { PARSE_ATTR("text"); PASS(block, "text", "del"); };
    del { PARSE_ATTR("text"); PASS(block, "text", "del"); };
    ins { PARSE_ATTR("text"); PASS(block, "text", "ins"); };
    sub { PARSE_ATTR("text"); PASS(block, "text", "sub"); };
    sup { PARSE_ATTR("text"); PASS(block, "text", "sup"); };
    notextile => ignore;
    color { PARSE_ATTR("text"); PASS(block, "text", "color"); };
    size { PARSE_ATTR("text"); PASS(block, "text", "bbsize"); };
    align { PARSE_ATTR("text"); PASS(block, "text", "align"); };
    acronym { PARSE_ATTR("text"); PASS(block, "text", "acronym"); };
    
    pre_tag_start { ASET("type", "notextile"); rb_str_append(temp,rb_str_new(ts,te-ts)); fgoto pre_tag; };
    
    #pre { PARSE_ATTR("text"); PASS(block, "text", "pre"); };
    
    #quote { PARSE_ATTR("text"); PASS(block, "text", "quote"); };
    
    quote_tag_start { rb_str_append(temp,rb_str_new(ts,te-ts)); fgoto quote_tag; };
    
    
    other_phrase => cat;
    PUNCT => cat;
    space => cat;
  
    EOF;
    
  *|;

}%%;