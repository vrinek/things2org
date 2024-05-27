Tag = Struct.new(:id, :events) do
  def title
    events.map(&:title).compact.last
  end

  def to_org
    title.parameterize(separator: "_")
  end
end

Tag::STORE = []
