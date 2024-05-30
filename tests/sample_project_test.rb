require 'minitest/autorun'

require_relative "../things_org"

class SampleProjectTest < Minitest::Test
  def setup
    @things_org = ThingsOrg.new(File.read("tests/items.json"), at: 0)
  end

  def test_headers
    assert_equal 4, @things_org.send(:headers).size
    assert_equal ["Before you go…",
                  "Learn the basics",
                  "Boost your productivity",
                  "Tune your setup"].sort, @things_org.send(:headers).map(&:title).sort
  end

  def test_inbox_org
    assert_equal <<~ORG, @things_org.inbox_org
      #+title: Inbox
    ORG
  end

  def test_archive_org
    assert_equal <<~ORG, @things_org.archive_org
      #+title: Archive
    ORG
  end

  def test_projectless_org
    assert_equal <<~ORG, @things_org.projectless_org
      #+title: No Project
    ORG
  end

  def test_extra_files
    assert_equal ["meet-things-for-mac.org"], @things_org.extra_files.sort
  end

  def test_make_extra
    assert_equal File.read("./tests/meet-things-for-mac.0.org"),
                 @things_org.make_extra("meet-things-for-mac.org")
  end
end
