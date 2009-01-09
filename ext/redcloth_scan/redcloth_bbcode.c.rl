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
  VALUE block = rb_str_new2("");
  VALUE regs = Qnil;
  unsigned int opts = 0;
  VALUE buf = Qnil;
  VALUE hash = Qnil;
  
  VALUE html = rb_str_new2("");
  VALUE failed_start = rb_str_new2("");
  int stack[CALL_STACK_SIZE],top;
  
  %% write init;

  %% write exec;

  return block;
}

VALUE
redcloth_bbcode2(self, str, refs)
  VALUE self, str, refs;
{
  StringValue(str);
  return redcloth_bbcode(self, RSTRING_PTR(str), RSTRING_PTR(str) + RSTRING_LEN(str) + 1, refs);
}