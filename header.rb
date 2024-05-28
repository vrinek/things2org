class Header < TaskBase
  def project_id
    last_event_prop("pr")&.first
  end
end

Header::STORE = []
