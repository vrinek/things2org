require_relative "task_base"
require_relative "project"
require_relative "note"
require_relative "header"

class Task < TaskBase
  def to_org
    org_header + org_timings + org_properties + note.to_org
  end

  def project
    return Project::STORE.find { |project| project.id == project_id } if project_id

    header&.project
  end

  def header
    return if header_id.nil?

    Header::STORE.find { |header| header.id == header_id }
  end

  def belongs_to_project?
    project_id.present? || header_id.present?
  end

  def project_id
    last_event_prop("pr")&.first || header&.project_id
  end

  private

  def header_id
    last_event_prop("agr")&.first
  end

  def note
    Note.new(events.map { |ev| ev.payload.dig("p", "nt") }.compact)
  end
end

Task::STORE = []
