/*
 * redcloth_scan.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
%%{

  machine redcloth_scan;
  
  action bb_cat2html { CAT(html); }
  action bb_failed4html { rb_str_append(block,failed_start); rb_str_append(block,rb_funcall(self, rb_intern("escape"), 1, html)); fgoto main; }

  # blocks
  notextile_tag = notextile (LF | EOF) ;
  noparagraph_line_start = " "+ ;
  notextile_block_start = ( "notextile" >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) " "+ ) ;
  pre_tag_start = "<pre" [^>]* ">" (space* code_tag_start)? ;
  pre_tag_end = (code_tag_end space*)? "</pre>" LF? ;
  pre_block_start = ( "pre" >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) " "+ ) ;
  bc_start = ( "bc" >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) " "+ ) ;
  bq_start = ( "bq" >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) ( ":" %A uri %{ STORE("cite"); } )? " "+ ) ;
  non_ac_btype = ( "bq" | "bc" | "pre" | "notextile" );
  btype = (alpha alnum*) -- (non_ac_btype | "fn" digit+);
  block_start = ( btype >A %{ STORE("type"); } A C :> "." ( "." %extend | "" ) " "+ ) >B %{ STORE_B("fallback"); };
  all_btypes = btype | non_ac_btype;
  next_block_start = ( all_btypes A_noactions C_noactions :> "."+ " " ) >A @{ p = reg - 1; } ;
  double_return = LF [ \t]* LF ;
  block_end = ( double_return | EOF );
  ftype = ( "fn" >A %{ STORE("type"); } digit+ >A %{ STORE("id"); } ) ;
  footnote_start = ( ftype A C :> dotspace ) ;
  ul = "*" %{nest++; list_type = "ul";};
  ol = "#" %{nest++; list_type = "ol";};
  ul_start  = ( ul | ol )* ul A C :> " "+   ;
  ol_start  = ( ul | ol )* ol N A C :> " "+ ;
  list_start  = " "* ( ul_start | ol_start ) >{nest = 0;} ;
  dt_start = "-" . " "+ ;
  dd_start = ":=" ;
  long_dd  = dd_start " "* LF %{ ADD_BLOCK(); ASET("type", "dd"); } any+ >A %{ TRANSFORM("text"); } :>> "=:" ;
  dl_start = (dt_start mtext (LF dt_start mtext)* " "* dd_start)  ;
  blank_line = LF;
  link_alias = ( "[" >{ ASET("type", "ignore"); } %A chars %T "]" %A uri %{ STORE_URL("href"); } ) ;
  horizontal_rule = '*'{3,} | '-'{3,} | '_'{3,} ;
  
  # image lookahead
  IMG_A_LEFT = "<" %{ UNLESS_DISABLED_ATTRIBUTE(align,ASET("float", "left");) } ;
  IMG_A_RIGHT = ">" %{ UNLESS_DISABLED_ATTRIBUTE(align,ASET("float", "right");) } ;
  aligned_image = ( "["? "!" (IMG_A_LEFT | IMG_A_RIGHT) ) >A @{ p = reg - 1; } ;
  
  # html blocks
  BlockTagName = Name - ("pre" | "notextile" | "a" | "applet" | "basefont" | "bdo" | "br" | "font" | "iframe" | "img" | "map" | "object" | "param" | "embed" | "q" | "script" | "span" | "sub" | "sup" | "abbr" | "acronym" | "cite" | "code" | "del" | "dfn" | "em" | "ins" | "kbd" | "samp" | "strong" | "var" | "b" | "big" | "i" | "s" | "small" | "strike" | "tt" | "u");
  block_start_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? ">" | "<" BlockTagName ">";
  block_empty_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? "/>" | "<" BlockTagName "/>" ;
  block_end_tag = "</" BlockTagName space* ">" ;
  html_start = indent >B %{STORE_B("indent_before_start");} block_start_tag >B %{STORE_B("start_tag");}  indent >B %{STORE_B("indent_after_start");} ;
  html_end = indent >B %{STORE_B("indent_before_end");} block_end_tag >B %{STORE_B("end_tag");} (indent LF?) >B %{STORE_B("indent_after_end");} ;
  standalone_html = indent (block_start_tag | block_empty_tag | block_end_tag) indent (LF+ | EOF);
  html_end_terminating_block = ( LF indent block_end_tag ) >A @{ p = reg - 1; } ;

  # tables
  para = ( default+ ) -- LF ;
  btext = para ( LF{2} )? ;
  tddef = ( D? S A C :> dotspace ) ;
  td = ( tddef? btext >A %T :> "|" >{PASS(table, "text", "td");} ) >X ;
  trdef = ( A C :> dotspace ) ;
  tr = ( trdef? "|" %{INLINE(table, "tr_open");} td+ ) >X %{INLINE(table, "tr_close");} ;
  trows = ( tr (LF >X tr)* ) ;
  tdef = ( "table" >X A C :> dotspace LF ) ;
  table = ( tdef? trows >{CLEAR(table); INLINE(table, "table_open"); RESET_REG();} ) ;
  
  bbchars = (default - space - "]" - "[")+ ;
  bbmtext = ( bbchars (mspace bbchars)* ) ;
  
  bb_pre_tag_start = "[pre" [^\]]* "]" (space* "[code]")? ;
  bb_pre_tag_end = ("[/code]" space*)? "[/pre]" LF? ;
  
  bb_quote_title1 = " title"? "=" bbmtext %{ if(store_cite) STORE("cite"); } >A;
  bb_quote_title2 = "][cite]" mtext %{ if(store_cite) STORE("cite"); } >A "[/cite";
  bb_quote_title = (bb_quote_title1|bb_quote_title2);
  bb_quote_tag_start = ("[quote" bb_quote_title? "]") ;
  bb_quote_tag_end =  "[/quote]" LF? ;
  
  bb_spoiler_tag_title = " title"? "=" bbmtext %{ if(store_title) STORE("title"); } >A;
  bb_spoiler_tag_start = ("[spoiler" bb_spoiler_tag_title? "]") ;
  bb_spoiler_tag_end =  "[/spoiler]" LF? ;

  # info
  redcloth_version = ("RedCloth" >A ("::" | " " ) "VERSION"i ":"? " ")? %{STORE("prefix");} "RedCloth::VERSION" (LF* EOF | double_return) ;

  pre_tag := |*
    pre_tag_end         { CAT(block); DONE(block); fgoto main; };
    default => esc_pre;
  *|;
  
  pre_block := |*
    EOF { 
      ADD_BLOCKCODE(); 
      fgoto main; 
    };
    double_return { 
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCKCODE(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
      } 
    };
    double_return next_block_start { 
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCKCODE(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        END_EXTENDED(); 
        fgoto main; 
      } 
    };
    default => esc_pre;
  *|;

  script_tag := |*
    script_tag_end   { CAT(block); ASET("type", "ignore"); ADD_BLOCK(); fgoto main; };
    EOF              { ASET("type", "ignore"); ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;

  noparagraph_line := |*
    LF  { ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;
  
  notextile_block := |*
    EOF {
      ADD_BLOCK();
      fgoto main;
    };
    double_return {
      if (IS_NOT_EXTENDED()) {
        ADD_BLOCK();
        CAT(html);
        fgoto main;
      } else {
        CAT(block);
        ADD_EXTENDED_BLOCK();
        CAT(html);
      }
    };
    double_return next_block_start {
      if (IS_NOT_EXTENDED()) {
        ADD_BLOCK();
        CAT(html);
        fgoto main;
      } else {
        CAT(block);
        ADD_EXTENDED_BLOCK();
        END_EXTENDED();
        fgoto main; 
      } 
    };
    default => cat;
  *|;
 
  html := |*
    html_end        { ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;

  bc := |*
    EOF { 
      ADD_BLOCKCODE(); 
      INLINE(html, "bc_close"); 
      SET_PLAIN_BLOCK("p");
      fgoto main;
    };
    double_return { 
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCKCODE(); 
        INLINE(html, "bc_close"); 
        SET_PLAIN_BLOCK("p");
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        CAT(html); 
      } 
    };
    double_return next_block_start { 
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCKCODE(); 
        INLINE(html, "bc_close"); 
        SET_PLAIN_BLOCK("p");
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        CAT(html); 
        RSTRIP_BANG(html);
        INLINE(html, "bc_close"); 
        SET_PLAIN_BLOCK("p");
        END_EXTENDED(); 
        fgoto main; 
      } 
    };
    default => esc_pre;
  *|;

  bq := |*
    EOF { 
      ADD_BLOCK(); 
      INLINE(html, "bq_close"); 
      fgoto main; 
    };
    double_return { 
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCK(); 
        INLINE(html, "bq_close"); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
      } 
    };
    double_return next_block_start { 
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCK(); 
        INLINE(html, "bq_close"); 
        fgoto main; 
      } else {
        ADD_EXTENDED_BLOCK(); 
        INLINE(html, "bq_close"); 
        END_EXTENDED(); 
        fgoto main; 
      }
    };
    html_end_terminating_block { 
        if (IS_NOT_EXTENDED()) { 
          ADD_BLOCK(); 
          INLINE(html, "bq_close"); 
          fgoto main; 
        } else {
          ADD_EXTENDED_BLOCK(); 
          INLINE(html, "bq_close"); 
          END_EXTENDED(); 
          fgoto main; 
        }
      };
    default => cat;
  *|;
  
  bb_pre_tag := |*
    bb_pre_tag_end {
      rb_hash_aset(regs, ID2SYM(rb_intern("text")), rb_funcall(self, rb_intern("escape_pre"), 1, block));
      rb_str_append(html,rb_funcall(self, rb_intern("bb_block_pre"), 1, regs));
      extend = Qnil;
      CLEAR(block);
      CLEAR_REGS();
      fgoto main;
    };
    default => cat;
    EOF => { CLEAR(block); CLEAR_REGS(); RESET_TYPE(); rb_str_append(block,failed_start); failed_start = STR_NEW2(""); p = failed_start_point_p; ts = failed_start_point_ts; te = failed_start_point_te; fgoto done; };
  *|;
  
  bb_quote_tag := |*
    bb_quote_tag_start => { CAT(block); ++nested_quote; };
    bb_quote_tag_end {
      if (nested_quote-- == 0) {
        VALUE cite = ID2SYM(rb_intern("cite"));
        if (rb_hash_aref(regs,cite) != Qnil)
          rb_hash_aset(regs, cite, redcloth_inline2(self,rb_hash_aref(regs,cite),rb_hash_new()));
        rb_hash_aset(regs, ID2SYM(rb_intern("text")), redcloth_transform2(self,block));
        rb_str_append(html,rb_funcall(self, rb_intern("bbquote"), 1, regs));
        nested_quote = 0;
        extend = Qnil;
        store_cite = 1;
        CLEAR(block);
        CLEAR_REGS();
        fgoto main;
      }
      else { CAT(block); }
    };
    default => cat;
    EOF => { CLEAR(block); ADD_BLOCK(); CLEAR_REGS(); RESET_TYPE(); rb_str_append(block,failed_start); failed_start = STR_NEW2(""); p = failed_start_point_p; ts = failed_start_point_ts; te = failed_start_point_te; fgoto done; };
  *|;
  
  bb_spoiler_tag := |*
    bb_spoiler_tag_start => { CAT(block); ++nested_spoiler; };
    bb_spoiler_tag_end {
      if (nested_spoiler-- == 0) {
        rb_hash_aset(regs, ID2SYM(rb_intern("text")), redcloth_transform2(self,block));
        rb_str_append(html,rb_funcall(self, rb_intern("bb_block_spoiler"), 1, regs));
        extend = Qnil;
        store_title = 1;
        nested_spoiler = 0;
        CLEAR(block);
        CLEAR_REGS();
        fgoto main;
      }
      else { CAT(block); }
    };
    default => cat;
    EOF => { CLEAR(block); CLEAR_REGS(); RESET_TYPE(); rb_str_append(block,failed_start); failed_start = STR_NEW2(""); p = failed_start_point_p; ts = failed_start_point_ts; te = failed_start_point_te; fgoto done; };
  *|;

  block := |*
    EOF { 
      ADD_BLOCK(); 
      fgoto main;
    };
    double_return {
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
      } 
    };
    bb_quote_tag_start {
      //printf("bb_quote_tag_start");
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCK(); 
        failed_start_point_p = p; failed_start_point_ts = ts; failed_start_point_te = te;
        fgoto bb_quote_tag; 
      } else { 
        ADD_EXTENDED_BLOCK();
        END_EXTENDED(); 
        failed_start_point_p = p; failed_start_point_ts = ts; failed_start_point_te = te;
        fgoto bb_quote_tag;
      }
    };
    double_return next_block_start { 
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
        END_EXTENDED(); 
        fgoto main; 
      }      
    };
    html_end_terminating_block { 
      if (IS_NOT_EXTENDED()) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
        END_EXTENDED(); 
        fgoto main; 
      }      
    };
    LF list_start { 
      ADD_BLOCK(); 
      CLEAR_LIST(); 
      LIST_ITEM(); 
      fgoto list; 
    };
    
    default => cat;
  *|;

  footnote := |*
    block_end       { ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;

  list := |*
    LF list_start   { ADD_BLOCK(); LIST_ITEM(); };
    block_end       { ADD_BLOCK(); nest = 0; LIST_CLOSE(); fgoto main; };
    default => cat;
  *|;

  dl := |*
    LF dt_start     { ADD_BLOCK(); ASET("type", "dt"); };
    dd_start        { ADD_BLOCK(); ASET("type", "dd"); };
    long_dd         { INLINE(html, "dd"); CLEAR_REGS(); };
    block_end       { ADD_BLOCK(); INLINE(html, "dl_close");  fgoto main; };
    default => cat;
  *|;
  
  done := |*
    EOF;
  *|;

  main := |*
    bb_pre_tag_start     { ASET("type", "notextile"); rb_str_append(failed_start,STR_NEW(ts,te-ts)); failed_start_point_p = p; failed_start_point_ts = ts; failed_start_point_te = te; fgoto bb_pre_tag; };
    bb_quote_tag_start   { rb_str_append(failed_start,STR_NEW(ts,te-ts)); failed_start_point_p = p; failed_start_point_ts = ts; failed_start_point_te = te; store_cite = 0; fgoto bb_quote_tag; };
    bb_spoiler_tag_start { rb_str_append(failed_start,STR_NEW(ts,te-ts)); failed_start_point_p = p; failed_start_point_ts = ts; failed_start_point_te = te; store_title = 0; fgoto bb_spoiler_tag; };
    
    noparagraph_line_start  { UNLESS_DISABLED_BLOCK(block,noparagraph_line_start,ASET("type", "ignored_line"); fgoto noparagraph_line;) };
    notextile_tag   { INLINE(block, "notextile"); };
    notextile_block_start { ASET("type", "notextile"); fgoto notextile_block; };
    script_tag_start { CAT(block); fgoto script_tag; };
    pre_tag_start       { ASET("type", "notextile"); CAT(block); fgoto pre_tag; };
    pre_block_start { fgoto pre_block; };
    standalone_html { ASET("type", "html"); CAT(block); ADD_BLOCK(); };
    html_start      { ASET("type", "html_block"); fgoto html; };
    bc_start        { INLINE(html, "bc_open"); ASET("type", "code"); SET_PLAIN_BLOCK("code"); fgoto bc; };
    bq_start        { INLINE(html, "bq_open"); ASET("type", "p"); fgoto bq; };
    block_start     { fgoto block; };
    footnote_start  { fgoto footnote; };
    horizontal_rule { INLINE(html, "hr"); };
    list_start      { CLEAR_LIST(); LIST_ITEM(); fgoto list; };
    dl_start        { p = ts; INLINE(html, "dl_open"); ASET("type", "dt"); fgoto dl; };
    table           { INLINE(table, "table_close"); DONE(table); fgoto block; };
    #link_alias      { UNLESS_DISABLED_INLINE(block,link_alias,STORE_LINK_ALIAS(); DONE(block);) };
    aligned_image   { RESET_TYPE(); fgoto block; };
    redcloth_version { INLINE(html, "redcloth_version"); };

    blank_line => cat;
    default
    { 
      CLEAR_REGS();
      RESET_TYPE();
      CAT(block);
      fgoto block;
    };
    EOF;
  *|;

}%%;
