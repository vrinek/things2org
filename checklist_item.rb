ChecklistItem = Struct.new(:id, :events) do
  def task_id
    last_event_prop("ts")[0]
  end

  def title
    last_event_prop("tt")
  end

  def to_org
    "- [ ] #{title}\n"
  end

  def index
    last_event_prop("ix")
  end

  private

  def last_event_prop(prop_name)
    events
      .map { |ev| ev.payload.dig("p", prop_name) }
      .reject(&:blank?)
      .last
  end
end

ChecklistItem::STORE = []
