Area = Struct.new(:id, :events) do
  def title
    events.map(&:title).compact.last
  end

  def filename
    return if title.blank?

    "#{title.parameterize}.org"
  end
end

Area::STORE = []
