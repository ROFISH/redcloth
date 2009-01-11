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
  
  bb_quote_title = " title"? "=" bbmtext %{ if(store_cite) STORE("cite"); } >A;
  bb_quote_tag_start = LF? ("[quote" bb_quote_title? "]") ;
  bb_quote_tag_end =  "[/quote]" LF? ;
  
  bb_spoiler_tag_title = " title"? "=" bbmtext %{ if(store_title) STORE("title"); } >A;
  bb_spoiler_tag_start = ("[spoiler" bb_spoiler_tag_title? "]") ;
  bb_spoiler_tag_end =  "[/spoiler]" LF? ;
  
  bbcode_tag = "[";
  
  blank_line = LF;
  double_return = LF{2,} ;
  
  direct_uri = "http" "s"? "://" uchar+ absolute_path?;
  automatic_url = direct_uri >X >A %{ STORE_URL("href"); } ;
  
  bb_pre_tag := |*
    bb_pre_tag_end {
      rb_hash_aset(regs, ID2SYM(rb_intern("text")), rb_funcall(self, rb_intern("escape_pre"), 1, rb_funcall(block,rb_intern("strip"),0)));
      rb_str_append(html,rb_funcall(self, rb_intern("bb_block_pre"), 1, regs));
      CLEAR(block);
      CLEAR_REGS();
      fgoto main;
    };
    default => cat;
    EOF => { CLEAR(block); CLEAR_REGS(); rb_str_append(block,failed_start); failed_start = rb_str_new2(""); p = failed_start_point_p; ts = failed_start_point_ts; te = failed_start_point_te; fgoto block; };
  *|;
  
  bb_quote_tag := |*
    bb_quote_tag_start => { CAT(block); ++nested_quote; };
    bb_quote_tag_end {
      if (nested_quote-- == 0) {
        rb_hash_aset(regs, ID2SYM(rb_intern("text")), redcloth_transform2(self,rb_funcall(block,rb_intern("strip"),0)));
        rb_str_append(html,rb_funcall(self, rb_intern("bbquote"), 1, regs));
        nested_quote = 0;
        store_cite = 1;
        CLEAR(block);
        CLEAR_REGS();
        fgoto main;
      }
      else { CAT(block); }
    };
    default => cat;
    EOF => { CLEAR(block); CLEAR_REGS(); rb_str_append(block,failed_start); failed_start = rb_str_new2(""); p = failed_start_point_p; ts = failed_start_point_ts; te = failed_start_point_te; fgoto block; };
  *|;
  
  bb_spoiler_tag := |*
    bb_spoiler_tag_start => { CAT(block); ++nested_spoiler; };
    bb_spoiler_tag_end {
      if (nested_spoiler-- == 0) {
        rb_hash_aset(regs, ID2SYM(rb_intern("text")), redcloth_transform2(self,rb_funcall(block,rb_intern("strip"),0)));
        rb_str_append(html,rb_funcall(self, rb_intern("bb_block_spoiler"), 1, regs));
        nested_spoiler = 0;
        store_title = 1;
        CLEAR(block);
        CLEAR_REGS();
        fgoto main;
      }
      else { CAT(block); }
    };
    default => cat;
    EOF => { CLEAR(block); CLEAR_REGS(); rb_str_append(block,failed_start); failed_start = rb_str_new2(""); p = failed_start_point_p; ts = failed_start_point_ts; te = failed_start_point_te; fgoto block; };
  *|;
  
  block := |*
    EOF { 
      rb_hash_aset(regs, ID2SYM(rb_intern("text")), rb_funcall(block,rb_intern("strip"),0));
      rb_str_append(html, rb_funcall(self, rb_intern("p"), 1, regs));
      CLEAR(block); 
      CLEAR_REGS()
      fgoto main;
    };
    bb_quote_tag_start {
      rb_hash_aset(regs, ID2SYM(rb_intern("text")), rb_funcall(block,rb_intern("strip"),0));
      rb_str_append(html, rb_funcall(self, rb_intern("p"), 1, regs));
      CLEAR(block); 
      CLEAR_REGS()
      fgoto bb_quote_tag;
    };
    automatic_url { UNLESS_DISABLED_INLINE(block,link,PASS(block, "name", "link");) };
    bbcode_tag => {
      fhold;
      fcall bbcode_inline;
    };
    double_return {
      rb_hash_aset(regs, ID2SYM(rb_intern("text")), rb_funcall(block,rb_intern("strip"),0));
      rb_str_append(html, rb_funcall(self, rb_intern("p"), 1, regs));
      CLEAR(block); 
      CLEAR_REGS()
      fgoto main; 
    };
    default => esc;
  *|;
  
  main := |*
    #bbcode_tag => {
    #  fhold;
    #  fcall bbcode_inline;
    #};
    bb_pre_tag_start => { rb_str_append(failed_start,rb_str_new(ts,te-ts)); failed_start_point_p = p; failed_start_point_ts = ts; failed_start_point_te = te; fgoto bb_pre_tag; };
    bb_quote_tag_start   { rb_str_append(failed_start,rb_str_new(ts,te-ts)); failed_start_point_p = p; failed_start_point_ts = ts; failed_start_point_te = te; store_cite = 0; fgoto bb_quote_tag; };
    bb_spoiler_tag_start { rb_str_append(failed_start,rb_str_new(ts,te-ts)); failed_start_point_p = p; failed_start_point_ts = ts; failed_start_point_te = te; store_title = 0; fgoto bb_spoiler_tag; };
    blank_line => cat;
    default => { fhold; fgoto block; };
  *|;

}%%;