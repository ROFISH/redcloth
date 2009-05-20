/*
 * redcloth_bbcode_inline.c.rl
 *
 * Copyright (C) 2009 Ryan Alyea
 */
#include <ruby.h>
#include "redcloth.h"

%%{
  
  machine redcloth_bbcode_inline;
  include redcloth_common "redcloth_common.c.rl";
  include redcloth_bbcode_inline "redcloth_bbcode_inline.rl";
  
  bbcode_tag = "[";
  
  dim_digit = [0-9.]+ ;
  prime = ("'" | '"')?;
  dim_noactions = dim_digit prime (("x" | " x ") dim_digit prime) %T (("x" | " x ") dim_digit prime)? ;
  
  other_phrase = phrase -- dim_noactions;
  
  main := |*
    bbcode_tag => {
      fhold;
      fcall bbcode_inline;
    };
    other_phrase => esc;
    PUNCT => esc;
    space => esc;
    
    EOF;
  *|;
  
}%%

%% write data nofinal;

VALUE
redcloth_bbcode_inline(self, p, pe, refs)
  VALUE self;
  char *p, *pe;
  VALUE refs;
{
  int cs, act, nest;
  char *ts = NULL, *te = NULL, *reg = NULL, *bck = NULL, *eof = NULL;
  char *orig_p = p, *orig_pe = pe;
  VALUE block = STR_NEW2("");
  VALUE attr_regs = Qnil;
  VALUE regs = Qnil; CLEAR_REGS()
  unsigned int opts = 0;
  VALUE buf = Qnil;
  VALUE hash = Qnil;

  VALUE html = STR_NEW2("");
  VALUE failed_start = STR_NEW2("");
  char *failed_start_point_p = NULL, *failed_start_point_ts = NULL, *failed_start_point_te = NULL;
  int stack[CALL_STACK_SIZE],top,nested_quote = 0, nested_spoiler = 0, store_cite = 1, store_title = 1;

  %% write init;

  %% write exec;

  return block;
}

VALUE
redcloth_bbcode_inline2(self, str, refs)
  VALUE self, str, refs;
{
  StringValue(str);
  return redcloth_bbcode_inline(self, RSTRING_PTR(str), RSTRING_PTR(str) + RSTRING_LEN(str) + 1, refs);
}