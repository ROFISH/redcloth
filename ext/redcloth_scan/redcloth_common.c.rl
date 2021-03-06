%%{
  
  machine redcloth_common;
  
  action esc { rb_str_cat_escaped(self, block, ts, te); }
  action esc_pre { rb_str_cat_escaped_for_preformatted(self, block, ts, te); }
  action ignore { rb_str_append(block, rb_funcall(self, rb_intern("ignore"), 1, regs)); }
  action esc_test {rb_str_cat_escaped_test(self, block, ts, te);}
  
  # conditionals
  action starts_line {
    p == orig_p || *(p-1) == '\r' || *(p-1) == '\n' || *(p-1) == '\f'
  }
  action starts_phrase {
    p == orig_p || *(p-1) == '\r' || *(p-1) == '\n' || *(p-1) == '\f' || *(p-1) == ' '
  }
  action extended { !NIL_P(extend) }
  action not_extended { NIL_P(extend) }
  action following_hash_is_ol_not_id { 
    (*(p+1) == '#') ? (*(p+2) == '#' || *(p+2) == '*' || *(p+2) == ' ') : 1 == 1
  }


  include redcloth_common "redcloth_common.rl";
  
}%%;