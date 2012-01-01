#!/usr/bin/env ruby

require File.expand_path('../helper', __FILE__)

class TestErb < Test::Unit::TestCase

  def test_redcloth_erb
    template = %{<%=t "This new ERB tag makes is so _easy_ to use *RedCloth*" %>}
    expected = %{<p>This new <span class="caps">ERB</span> tag makes is so <em>easy</em> to use <strong>RedCloth</strong></p>}
    assert_equal expected, ERB.new(template).result
  end

end
