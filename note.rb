Note = Struct.new(:note_events) do
  def to_org(level: 1)
    return "" if text.blank?

    pandoc = PandocRuby.new(text,
                            "--wrap=preserve --base-header-level=#{level}",
                            from: :markdown,
                            to: :org)
    "\n" + pandoc.convert
  end

  private

  def text
    txt = ""

    note_events.each do |ev|
      case ev["t"]
      when 1
        txt = ev["v"]
      when 2
        change = ev.dig("ps", 0)
        start = change["p"].clamp(0, txt.length)
        length = change["l"]
        new_string = change["r"]

        txt[start, length] = new_string
      end
    end

    txt = insert_blank_line_before_lists(txt)
    replace_markdown_highlight_with_org_verbatim(txt)
  end

  def insert_blank_line_before_lists(txt)
    lines = txt.lines
    lines.each.with_index.map do |line, index|
      if index == 0
        line
      elsif lines[index - 1] == "\n"
        line
      elsif line.start_with?("- ") && !lines[index - 1].start_with?("- ")
        "\n#{line}"
      else
        line
      end
    end.join
  end

  def replace_markdown_highlight_with_org_verbatim(txt)
    txt.gsub(/::(.*?)::/m, "=\\1=")
  end
end
