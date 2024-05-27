ItemEvent = Struct.new(:index, :item_id, :payload) do
  def title
    payload.dig("p", "tt")
  end
end
