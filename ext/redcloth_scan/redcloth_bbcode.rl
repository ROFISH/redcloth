/*
 * redcloth_bbcode.rl
 *
 * Copyright (C) 2009 Ryan Alyea
 */
%%{

  machine redcloth_bbcode;
  include redcloth_bbcode_inline 'redcloth_bbcode_inline.rl';
  
  #bb_pre_tag_start = "[pre" [^\]]* "]" (space* "[code]")? ;
  #bb_pre_tag_end = ("[/code]" space*)? "[/pre]" LF? ;
  
  bb_quote_title = " title"? "=" bbmtext %{ STORE("cite"); } >A;
  bb_quote_tag_start = ("[quote" bb_quote_title? "]") ;
  bb_quote_tag_end =  "[/quote]" LF? ;
  
  bb_spoiler_title = " title"? "=" bbmtext %{ STORE("title"); } >A;
  bb_spoiler_tag_start = ("[spoiler" bb_spoiler_title? "]") ;
  bb_spoiler_tag_end =  "[/spoiler]" LF? ;
  
  bbcode_tag = "[";
  
  double_return = LF{2,} ;
  
  block := |*
    EOF { 
      rb_hash_aset(regs, ID2SYM(rb_intern("text")), block);
      rb_str_append(html, rb_funcall(self, rb_intern("p"), 1, regs));
      CLEAR(block); 
      CLEAR_REGS()
      fgoto main;
    };
    bbcode_tag => {
      fhold;
      fcall bbcode_inline;
    };
    double_return {
      rb_hash_aset(regs, ID2SYM(rb_intern("text")), block);
      rb_str_append(html, rb_funcall(self, rb_intern("p"), 1, regs));
      CLEAR(block); 
      CLEAR_REGS()
      fgoto main; 
    };
    default => cat;
  *|;
  
  main := |*
    #bbcode_tag => {
    #  fhold;
    #  fcall bbcode_inline;
    #};
    default => { CAT(block); fgoto block; };
  *|;

}%%;