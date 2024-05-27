require "json"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/object/blank"
require "pandoc-ruby"

ItemEvent = Struct.new(:index, :item_id, :payload) do
  def title
    payload.dig("p", "tt")
  end
end

Area = Struct.new(:id, :events) do
  def title
    events.map(&:title).compact.last
  end

  def filename
    return if title.blank?

    "#{title.parameterize}.org"
  end
end

Task = Struct.new(:id, :events) do
  def to_org
    org_header + org_timings + org_properties + note.to_org
  end

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

  def project
    return if project_id.nil?

    Project::STORE.find { |project| project.id == project_id }
  end

  def belongs_to_project?
    project_id.present?
  end

  def is_scheduled?
    scheduled.present?
  end

  private

  def org_header
    header = "* #{todo_state} #{title}"
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

  def project_id
    last_event_prop("pr")&.first
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

  def note
    Note.new(events.map { |ev| ev.payload.dig("p", "nt") }.compact)
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
end

Note = Struct.new(:note_events) do
  def to_org
    note = ""
    note_events.each do |ev|
      case ev["t"]
      when 1
        note = ev["v"]
      when 2
        change = ev.dig("ps", 0)
        start = change["p"].clamp(0, note.length)
        length = change["l"]
        new_string = change["r"]

        note[start, length] = new_string
      end
    end

    return note if note.blank?

    pandoc = PandocRuby.new(note, '--wrap=preserve', from: :markdown, to: :org)
    "\n" + pandoc.convert
  end
end

Tag = Struct.new(:id, :events) do
  def title
    events.map(&:title).compact.last
  end

  def to_org
    title.parameterize(separator: "_")
  end
end

class Project < Task
  def filename
    return if title.blank?

    if area_title
      "#{area_title.parameterize}/#{title.parameterize}.org"
    else
      "#{title.parameterize}.org"
    end
  end

  private

  def area_title
    return nil if area_id.blank?

    Area::STORE.find { |area| area.id == area_id }&.title
  end
end

Area::STORE = []
Task::STORE = []
Tag::STORE = []
Project::STORE = []

class ItemJsonMerger
  attr_reader :items_json

  def initialize
    @items_json = {
      "items" => []
    }
  end

  def add(json_file_path)
    @items_json["items"] += JSON[File.read(json_file_path)]["items"]
    @items_json["items"].uniq!

    self
  end

  def to_json
    @items_json.to_json
  end
end

class ThingsOrg
  def initialize(items_json)
    @items_json = JSON[items_json]

    initialize_tags_store!
    initialize_areas_store!
    initialize_projects_store!
    initialize_tasks_store!
  end

  def inbox_org
    org_file_title("Inbox") +
      tasks_org(
        tasks.reject(&:area_id)
             .reject(&:belongs_to_project?)
             .reject(&:is_scheduled?)
             .reject(&:someday?)
             .reject(&:done?)
             .reject(&:canceled?))
  end

  def archive_org
    org_file_title "Archive"
  end

  def projectless_org
    tasks_org = tasks_org(tasks.reject(&:area_id).select(&:someday?))

    org_file_title("No Project") + tasks_org
  end

  def extra_files
    areas.map(&:filename) +
      projects.reject(&:done?).reject(&:deleted?).map(&:filename)
  end

  def make_extra(filename)
    area = areas.find { |area| area.filename == filename }

    tasks_org = tasks_org(tasks.select { |t| t.area_id == area.id })

    things_id_property = <<~ORG
      #+PROPERTY: things_id #{area.id}
    ORG

    org_file_title(area.title) + things_id_property + tasks_org
  end

  private

  def tasks_org(tasks)
    org = tasks.sort_by(&:index).map(&:to_org).join("\n")
    org = "\n" + org unless org.blank?
    org
  end

  def org_file_title(title)
    <<~ORG
      #+title: #{title}
    ORG
  end

  def item_events
    @items_json["items"].map.with_index do |events, index|
      events.map do |item_id, event|
        ItemEvent.new(index, item_id, event)
      end
    end.flatten
  end

  def initialize_tasks_store!
    Task::STORE.clear

    item_events
      .select { |item_event| item_event.payload["e"] == "Task6" }
      .group_by(&:item_id)
      .map { |item_id, events| Task.new(item_id, events) }
      .select { |task| task.is_task? }
      .reject { |task| task.title.blank? }
      .reject { |task| task.deleted? }
      .each { |task| Task::STORE << task }
  end

  def tasks
    Task::STORE
  end

  def initialize_areas_store!
    Area::STORE.clear

    item_events
      .select { |item_event| item_event.payload["e"] == "Area3" }
      .group_by(&:item_id)
      .map { |item_id, events| Area.new(item_id, events) }
      .reject { |area| area.title.blank? }
      .each { |area| Area::STORE << area }
  end

  def areas
    Area::STORE
  end

  def initialize_tags_store!
    Tag::STORE.clear

    item_events
      .select { |item_event| item_event.payload["e"] == "Tag4" }
      .group_by(&:item_id)
      .map { |item_id, events| Tag.new(item_id, events) }
      .reject { |tag| tag.title.blank? }
      .each { |tag| Tag::STORE << tag }
  end

  def initialize_projects_store!
    Project::STORE.clear

    item_events
      .select { |item_event| item_event.payload["e"] == "Task6" }
      .group_by(&:item_id)
      .map { |item_id, events| Project.new(item_id, events) }
      .select { |project| project.is_project? }
      .reject { |project| project.canceled? }
      .each { |project| Project::STORE << project }
  end

  def projects
    Project::STORE
  end
end
