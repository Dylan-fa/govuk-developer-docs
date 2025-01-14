module AnalyticsHelpers
  def urlize(string)
    string.downcase.gsub(" ", "_").gsub("-", "_")
  end

  def build_event(data, attributes = [], output = {})
    data.sort_by { |k, _v| k["name"] }.each do |item|
      name = item["name"]
      value = item["value"]
      if value
        case value
        when String
          output[name] = value
        when Array
          output[name] = build_event(value, attributes)
        end
      else
        attribute = attributes.find { |x| x["name"] == name }
        output[name] = attribute ? attribute["type"] : value
      end
    end
    output
  end

  def to_html(hash, html = "")
    html += "<ul class='govuk-list indented-list'>"
    hash.each do |key, value|
      case value
      when String
        html += "<li><a href='/analytics/attribute_#{urlize(key)}.html' class='govuk-link'>#{key}</a>: #{value}</li>"
      when Hash
        html += "<li>#{key}: #{to_html(value)}</li>"
      end
    end
    html += "</ul>"
    html
  end

  def tag_colours
    {
      "high" => "govuk-tag--red",
      "medium" => "govuk-tag--yellow",
      "low" => "govuk-tag--green",
    }
  end

  def implementation_percentage(events)
    implemented = events.select { |x| x["implemented"] == true }.count
    percentage = ((implemented.to_f / events.count) * 100.00).round(2)
    percentage = 0 if implemented.zero? || events.count.zero?
    "#{implemented} of #{events.count} (#{percentage}%)"
  end

  def create_page_title(title)
    header = ["GOV.UK GA4 Implementation record"]
    header.prepend(title) if title
    header.join(" | ")
  end
end
