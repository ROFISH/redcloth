/*
 * redcloth_bbcode.rl
 *
 * Copyright (C) 2009 Ryan Alyea
 */
%%{

  machine redcloth_bbcode;
  
  action cat2html { CAT(html); }
  action failed4html { rb_str_append(block,failed_start); rb_str_append(block,rb_funcall(self, rb_intern("escape"), 1, html)); fgoto main; }
  
  bbchars = (default - space - "]" - "[")+ ;
  bbmtext = ( bbchars (mspace bbchars)* ) ;
  
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
  color = ("[color=" >X innercolor >A "]" mtext >A %T :> "[/color]") ;
  innersize = space* ( (digit? "."? digit{1,2} ("em"|"pt"|"px"|"%")? )|("xx-small"|"x-small"|"small"|"medium"|"large"|"x-large"|"xx-large"|"smaller"|"larger")) %{ STORE("size"); } space* ;
  size = ("[size=" >X innersize >A "]" mtext >A %T :> "[/size]")  ;
  inneralign = space* ("left"|"center"|"right") %{ STORE("align"); } space* ;
  align = ("[align=" >X inneralign >A "]" mtext >A %T :> "[/align]")  ;
  acronym = ("[acronym=" >X bbmtext %{ STORE("title"); } >A "]" mtext >A %T :> "[/acronym]") ;
  
  link = "[url]" >X uri %{ STORE("href"); } >A :> "[/url]" ;
  link2 = "[url=">X uri %{ STORE("href"); } >A "]" mtext %{ STORE("name"); } >A :> "[/url]" ;
  
  img = "[img]" >X uri %{ STORE("src"); } >A :> "[/img]" ;
  img2 = "[img=">X uri %{ STORE("src"); } >A "]" mtext %{ STORE("title"); } >A :> "[/img]" ;
  
  pre_tag_start = "[pre" [^\]]* "]" (space* "[code]")? ;
  pre_tag_end = ("[/code]" space*)? "[/pre]" LF? ;
  
  quote_title = " title"? "=" bbmtext %{ STORE("cite"); } >A;
  quote_tag_start = ("[quote" quote_title? "]") ;
  quote_tag_end =  "[/quote]" LF? ;
  
  spoiler_title = " title"? "=" bbmtext %{ STORE("title"); } >A;
  spoiler_tag_start = ("[spoiler" spoiler_title? "]") ;
  spoiler_tag_end =  "[/spoiler]" LF? ;
  
  dim_digit = [0-9.]+ ;
  prime = ("'" | '"')?;
  dim_noactions = dim_digit prime (("x" | " x ") dim_digit prime) %T (("x" | " x ") dim_digit prime)? ;
  dim = dim_noactions >X >A %T ;
  
  other_phrase = phrase -- dim_noactions;
  
  pre_tag := |*
    pre_tag_end         { rb_str_append(block,rb_str_new2("<pre><code>")); rb_str_append(block,rb_funcall(self, rb_intern("escape_pre"), 1, html)); rb_str_append(block,rb_str_new2("</code></pre>")); BBDONE(); fgoto main; };
    #LF                  { rb_str_append(html,rb_str_new2("<br/>")); };
    default => cat2html;
    EOF => failed4html;
  *|;
  
  quote_tag := |*
    quote_tag_end { rb_hash_aset(regs, ID2SYM(rb_intern("text")), redcloth_transform2(self,html)); rb_str_append(block,rb_funcall(self, rb_intern("bbquote"), 1, regs)); BBDONE(); fgoto main;};
    default => cat2html;
    EOF => failed4html;
  *|;
  
  spoiler_tag := |*
    spoiler_tag_end { rb_hash_aset(regs, ID2SYM(rb_intern("text")), redcloth_transform2(self,html)); rb_str_append(block,rb_funcall(self, rb_intern("bbspoiler"), 1, regs)); BBDONE(); fgoto main;};
    default => cat2html;
    EOF => failed4html;
  *|;
  
  main := |*
  
    b   { PASS(block, "text", "strong"); };
    i   { PASS(block, "text", "em"); };
    u   { PASS(block, "text", "ins"); };
    s   { PASS(block, "text", "del"); };
    del { PASS(block, "text", "del"); };
    ins { PASS(block, "text", "ins"); };
    sub { PASS(block, "text", "sub"); };
    sup { PASS(block, "text", "sup"); };
    notextile => ignore;
    color   { PASS(block, "text", "color"); };
    size    { PASS(block, "text", "bbsize"); };
    align   { PASS(block, "text", "align"); };
    acronym { PASS(block, "text", "acronym"); };
    link    { PASS(block, "name", "link"); };
    link2   { PASS(block, "name", "link"); };
    img     { PASS(block, "name", "image"); };
    img2    { PASS(block, "name", "image"); };
    
    pre_tag_start     { ASET("type", "notextile"); rb_str_append(failed_start,rb_str_new(ts,te-ts)); fgoto pre_tag; };
    quote_tag_start   { rb_str_append(failed_start,rb_str_new(ts,te-ts)); fgoto quote_tag; };
    spoiler_tag_start { rb_str_append(failed_start,rb_str_new(ts,te-ts)); fgoto spoiler_tag; };
    
    other_phrase => cat;
    PUNCT => cat;
    space => cat;
  
    EOF;
    
  *|;

}%%;