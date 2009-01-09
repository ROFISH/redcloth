/*
 * redcloth_bbcode.rl
 *
 * Copyright (C) 2009 Ryan Alyea
 */
%%{

  machine redcloth_bbcode;
  
  bbchars = (default - space - "]" - "[")+ ;
  bbmtext = ( bbchars (mspace bbchars)* ) ;
  
  action bb_cat2html { CAT(html); }
  action bb_failed4html { rb_str_append(block,failed_start); rb_str_append(block,rb_funcall(self, rb_intern("escape"), 1, html)); fgoto main; }
  
  bb_pre_tag_start = "[pre" [^\]]* "]" (space* "[code]")? ;
  bb_pre_tag_end = ("[/code]" space*)? "[/pre]" LF? ;
  
  bb_quote_title = " title"? "=" bbmtext %{ STORE("cite"); } >A;
  bb_quote_tag_start = ("[quote" bb_quote_title? "]") ;
  bb_quote_tag_end =  "[/quote]" LF? ;
  
  bb_spoiler_title = " title"? "=" bbmtext %{ STORE("title"); } >A;
  bb_spoiler_tag_start = ("[spoiler" bb_spoiler_title? "]") ;
  bb_spoiler_tag_end =  "[/spoiler]" LF? ;
  
  dim_digit = [0-9.]+ ;
  prime = ("'" | '"')?;
  dim_noactions = dim_digit prime (("x" | " x ") dim_digit prime) %T (("x" | " x ") dim_digit prime)? ;
  dim = dim_noactions >X >A %T ;
  
  other_phrase = phrase -- dim_noactions;
  
  bb_pre_tag := |*
    bb_pre_tag_end {
      rb_str_append(block,rb_str_new2("<pre><code>"));
      rb_str_append(block,rb_funcall(self, rb_intern("escape_pre"), 1, html));
      rb_str_append(block,rb_str_new2("</code></pre>"));
      BBDONE();
      fgoto main; 
    };
    #LF                  { rb_str_append(html,rb_str_new2("<br/>")); };
    default => bb_cat2html;
    #EOF => bb_failed4html;
  *|;
  
  bb_quote_tag := |*
    bb_quote_tag_end { 
      rb_hash_aset(regs, ID2SYM(rb_intern("text")), redcloth_transform2(self,html));
      rb_str_append(block,rb_funcall(self, rb_intern("bbquote"), 1, regs));
      BBDONE();
      fgoto main;
    };
    default => bb_cat2html;
    #EOF => bb_failed4html;
  *|;
  
  bb_spoiler_tag := |*
    bb_spoiler_tag_end { rb_hash_aset(regs, ID2SYM(rb_intern("text")), redcloth_transform2(self,html)); rb_str_append(block,rb_funcall(self, rb_intern("bbspoiler"), 1, regs)); BBDONE(); fgoto main;};
    default => bb_cat2html;
    #EOF => bb_failed4html;
  *|;
  
  main := |*
    
    bb_pre_tag_start     { ASET("type", "notextile"); rb_str_append(failed_start,rb_str_new(ts,te-ts)); fgoto bb_pre_tag; };
    bb_quote_tag_start   { rb_str_append(failed_start,rb_str_new(ts,te-ts)); fgoto bb_quote_tag; };
    bb_spoiler_tag_start { rb_str_append(failed_start,rb_str_new(ts,te-ts)); fgoto bb_spoiler_tag; };
    
    other_phrase => cat;
    PUNCT => cat;
    space => cat;
  
    EOF;
    
  *|;

}%%;