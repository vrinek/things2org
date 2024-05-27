require "json"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/object/blank"
require "pandoc-ruby"

require_relative "item_event"
require_relative "tag"
require_relative "area"
require_relative "task"
require_relative "project"
require_relative "item_json_merger"

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
