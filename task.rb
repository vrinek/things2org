require_relative "task_base"
require_relative "project"
require_relative "note"

class Task < TaskBase
  def to_org
    org_header + org_timings + org_properties + note.to_org
  end

  def project
    return if project_id.nil?

    Project::STORE.find { |project| project.id == project_id }
  end

  def belongs_to_project?
    project_id.present?
  end

  private

  def project_id
    last_event_prop("pr")&.first
  end

  def note
    Note.new(events.map { |ev| ev.payload.dig("p", "nt") }.compact)
  end
end

Task::STORE = []
