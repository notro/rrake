#!/usr/bin/env ruby

require 'test/unit'
require 'rrake'

class TestClean < Test::Unit::TestCase
  include Rake
  def test_clean
    require 'rrake/clean'
    assert Task['clean'], "Should define clean"
    assert Task['clobber'], "Should define clobber"
    assert Task['clobber'].prerequisites.include?("clean"),
      "Clobber should require clean"
  end
end
