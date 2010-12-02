module ApplicationHelper
  def code_chars_limit
    100
  end

  def lang_ja
    case params[:lang]
    when "ja" then true
    when "en" then false
    else request.env["HTTP_ACCEPT_LANGUAGE"] =~ /\Aja/
    end
  end

  def vars(ary)
    ary.map{|v| v.join(" ")}.join(", ")
  end
end
