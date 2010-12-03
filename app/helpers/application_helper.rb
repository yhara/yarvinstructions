module ApplicationHelper
  def lang_ja
    case params[:lang]
    when "ja" then true
    when "en" then false
    else request.env["HTTP_ACCEPT_LANGUAGE"] =~ /\Aja/
    end
  end

  def vars(ary, omit_value=false)
    if omit_value
      ary.map{|v|
        case v[0]
        when "VALUE", "..." then v[1]
        else v.join(" ")
        end
      }.join(", ")
    else
      ary.map{|v| v.join(" ")}.join(", ")
    end
  end
end
