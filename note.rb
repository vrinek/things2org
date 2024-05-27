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
