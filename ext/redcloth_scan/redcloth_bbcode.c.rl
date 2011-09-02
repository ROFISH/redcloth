/*
 * redcloth_bbcode.c.rl
 *
 * Copyright (C) 2009 Ryan Alyea
 */
#include <ruby.h>
#include "redcloth.h"

%%{
  
  machine redcloth_bbcode;
  include redcloth_common "redcloth_common.c.rl";
  include redcloth_bbcode "redcloth_bbcode.rl";
  
}%%

%% write data nofinal;

VALUE
redcloth_bbcode(self, p, pe, refs)
  VALUE self;
  char *p, *pe;
  VALUE refs;
{
  int cs, act, nest;
  char *ts = NULL, *te = NULL, *reg = NULL, *bck = NULL, *eof = NULL;
  char *orig_p = p, *orig_pe = pe;
  VALUE block = STR_NEW2("");
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
  
  if (RSTRING_LEN(block) > 0)
  {
    rb_hash_aset(regs, ID2SYM(rb_intern("text")), block);
    rb_str_append(html, rb_funcall(self, rb_intern("p"), 1, regs));
    CLEAR(block); 
    CLEAR_REGS()
  }

  return rb_funcall(html, rb_intern("strip"), 0);
}

VALUE
redcloth_bbcode2(self, str, refs)
  VALUE self, str, refs;
{
  StringValue(str);
  return redcloth_bbcode(self, RSTRING_PTR(str), RSTRING_PTR(str) + RSTRING_LEN(str) + 1, refs);
}