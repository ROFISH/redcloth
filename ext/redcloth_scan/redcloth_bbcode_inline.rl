/*
 * redcloth_bbcode_inline.rl
 *
 * Copyright (C) 2009 Ryan Alyea
 */
%%{

  machine redcloth_bbcode_inline;
  
  bbchars = (default - space - "]" - "[")+ ;
  bbmtext = ( bbchars (mspace bbchars)* ) ;
  mtext_spaced = ( mspace* chars (mspace chars)* mspace* ) ;
  
  bb_b   = "[b]" >X mtext_spaced >A %T :>> "[/b]" ;
  bb_i   = "[i]" >X mtext_spaced >A %T :>> "[/i]" ;
  bb_u   = "[u]" >X mtext_spaced >A %T :>> "[/u]" ;
  bb_s   = "[s]" >X mtext_spaced >A %T :>> "[/s]" ;
  bb_del = "[del]" >X mtext_spaced >A %T :>> "[/del]" ;
  bb_ins = "[ins]" >X mtext_spaced >A %T :>> "[/ins]" ;
  bb_sub = "[sub]" >X mtext_spaced >A %T :>> "[/sub]" ;
  bb_sup = "[sup]" >X mtext_spaced >A %T :>> "[/sup]" ;
  bb_notextile = "[notextile]" >X mtext_spaced >A %T :>> "[/notextile]" ;
  bb_innercolor = ("#"[0-9a-fA-F]{3}|"#"[0-9a-fA-F]{6}|"aqua"|"black"|"blue"|"fuchsia"|"gray"|"green"|"lime"|"maroon"|"navy"|"olive"|"purple"|"red"|"silver"|"teal"|"white"|"yellow"|"orange"|"cyan"|"magenta"|"grey") %{ STORE("color"); };
  bb_color = ("[color=" >X bb_innercolor >A "]" mtext_spaced >A %T :>> "[/color]") ;
  bb_innersize = space* ( (digit? "."? digit{1,2} ("em"|"pt"|"px"|"%")? )|("xx-small"|"x-small"|"small"|"medium"|"large"|"x-large"|"xx-large"|"smaller"|"larger")) %{ STORE("size"); } space* ;
  bb_size = ("[size=" >X bb_innersize >A "]" mtext_spaced >A %T :>> "[/size]")  ;
  bb_inneralign = space* ("left"|"center"|"right") %{ STORE("bbalign"); } space* ;
  bb_align = ("[align=" >X bb_inneralign >A "]" mtext_spaced >A %T :>> "[/align]")  ;
  bb_acronym = ("[acronym=" >X bbmtext %{ STORE("title"); } >A "]" mtext_spaced >A %T :>> "[/acronym]") ;
  
  bb_link = "[url]" >X uri %{ STORE("href"); } >A :>> "[/url]" ;
  bb_link2 = "[url=">X uri %{ STORE("href"); } >A "]" mtext %{ STORE("name"); } >A :>> "[/url]" ;
  
  bb_img = "[img]" >X uri %{ STORE("src"); } >A :>> "[/img]" ;
  bb_img2 = "[img=">X uri %{ STORE("src"); } >A "]" mtext{0,1} %{ STORE("title"); } >A :>> "[/img]" ;
  
  bb_pre_tag_start = "[pre" [^\]]* "]" (space* "[code]")? ;
  bb_pre_tag_end = ("[/code]" space*)? "[/pre]" LF? ;
  
  bb_spoiler_title = " title"? "=" bbmtext %{ STORE("title"); } >A;
  bb_spoiler = "[spoiler" >X bb_spoiler_title? "]"  mtext >A %T :>> "[/spoiler]" ;
  
  nl = "\n";
  
  action bb_cat2html { CAT(html); }
  action bb_failed4html { rb_str_append(block,failed_start); rb_str_append(block,rb_funcall(self, rb_intern("escape"), 1, html)); fgoto bbcode_inline; }
  
  bb_inline_pre_tag := |*
    bb_pre_tag_end {
      rb_hash_aset(regs, ID2SYM(rb_intern("text")), rb_funcall(self, rb_intern("escape_pre"), 1, html));
      rb_str_append(block,rb_funcall(self, rb_intern("bb_pre"), 1, regs));
      BBDONE();
      fgoto bbcode_inline;
    };
    default => bb_cat2html;
    EOF => bb_failed4html;
  *|;
  
  bbcode_inline := |*
    bb_b   { PASS(block, "text", "strong"); };
    bb_i   { PASS(block, "text", "em"); };
    bb_u   { PASS(block, "text", "ins"); };
    bb_s   { PASS(block, "text", "del"); };
    bb_del { PASS(block, "text", "del"); };
    bb_ins { PASS(block, "text", "ins"); };
    bb_sub { PASS(block, "text", "sub"); };
    bb_sup { PASS(block, "text", "sup"); };
    bb_notextile => ignore;
    bb_color   { PASS(block, "text", "color"); };
    bb_size    { PASS(block, "text", "bbsize"); };
    bb_align   { PASS(block, "text", "bbalign"); };
    bb_acronym { PASS(block, "text", "acronym"); };
    bb_link    { PASS(block, "name", "link"); };
    bb_link2   { PASS(block, "name", "link"); };
    bb_img     { UNLESS_DISABLED_INLINE(block,image,PASS(block, "name", "image");); };
    bb_img2    { UNLESS_DISABLED_INLINE(block,image,PASS(block, "name", "image");); };
    bb_spoiler { PASS(block, "name", "bb_spoiler"); CLEAR_REGS();};
    
    bb_pre_tag_start     { ASET("type", "notextile"); rb_str_append(failed_start,rb_str_new(ts,te-ts)); fgoto bb_inline_pre_tag; };
    nl => { fhold; fret; };
    default => { CAT(block); fret;};
  *|;

}%%;