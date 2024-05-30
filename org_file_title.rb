class OrgFileTitle
  def initialize(title)
    @title = title
  end

  def to_org
    <<~ORG
      #+title: #{@title}
    ORG
  end
end
