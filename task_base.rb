require_relative "tag"

# This is a base class for Task and Project. In Things, a project is a special
# kind of task, so they share a lot of common properties.
TaskBase = Struct.new(:id, :events) do
  def title
    events.map(&:title).compact.last
  end

  def area_id
    last_event_prop("ar")&.first
  end

  def index
    last_event_prop("ix")
  end

  def someday?
    last_event_prop("st") == 2
  end

  def done?
    last_event_prop("ss") == 3
  end

  def canceled?
    last_event_prop("ss") == 2
  end

  def deleted?
    events.last.payload.dig("p").empty? &&
      events.last.payload.dig("t") == 2
  end

  def is_task?
    last_event_prop("tp") == 0
  end

  def is_project?
    last_event_prop("tp") == 1
  end

  def is_header?
    last_event_prop("tp") == 2
  end

  def is_scheduled?
    scheduled.present?
  end

  private

  def org_header(level: 1)
    header = "#{"*" * level} #{todo_state} #{title}"
    header << " #{org_tags}" if org_tags
    header << "\n"
    header
  end

  def todo_state
    if done?
      "DONE"
    elsif canceled?
      "CANCELED"
    elsif someday?
      "SOMEDAY"
    else
      "TODO"
    end
  end

  def org_properties
    <<~ORG
      :PROPERTIES:
      :things_id: #{id}
      :END:
    ORG
  end

  def tag_ids
    events.map { |ev| ev.payload.dig("p", "tg") }.compact.last
  end

  def tags
    Tag::STORE.select { |tag| tag_ids.include?(tag.id) }
  end

  def org_tags
    return if tags.empty?

    ":#{tags.map(&:to_org).join(":")}:"
  end

  # This is scheduled + deadline
  def org_timings
    return "" if org_scheduled.blank? && org_deadline.blank?

    [org_scheduled, org_deadline].join(" ").strip + "\n"
  end

  def scheduled
    sr = last_event_prop("sr")

    return if sr.blank?

    Time.at(sr).utc
  end

  def org_scheduled
    return "" if scheduled.blank?

    "SCHEDULED: <#{scheduled.strftime("%Y-%m-%d %a")}>"
  end

  def org_deadline
    dd = last_event_prop("dd")

    return "" if dd.blank?

    time = Time.at(dd).utc

    "DEADLINE: <#{time.strftime("%Y-%m-%d %a")}>"
  end

  def last_event_prop(prop_name)
    events
      .map { |ev| ev.payload.dig("p", prop_name) }
      .reject(&:blank?)
      .last
  end

  def note
    Note.new(events.map { |ev| ev.payload.dig("p", "nt") }.compact)
  end
end
