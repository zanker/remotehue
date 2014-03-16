module ApplicationHelper
  def active_class(controller, action=nil)
    if controller == params[:controller]
      if !action or action == params[:action]
        return :active
      end
    end

    nil
  end

  def transitiontime_list
    list = []
    list.push([t("instant"), 0])
    [1, 2, 3, 4, 5, 10, 20, 30, 40, 50].each do |s|
      list.push([t("seconds", :count => s), s * 10])
    end

    [1, 2, 3, 4, 5, 10, 15, 20, 30, 45, 60].each do |m|
      list.push([t("minutes", :count => m), m * 60 * 10])
    end

    list
  end

  def linkify_text(text, *args)
    text.scan(/(\{(.+?)\})/).each do |match|
      link = args.shift
      if link.is_a?(String)
        text = text.gsub(match.first, link_to(match.last, link)).html_safe
      elsif link.first == :email
        text = text.gsub(match.first, mail_to(link.last, match.last)).html_safe
      elsif link.first == :blank
        text = text.gsub(match.first, link_to(match.last, link.last, :target => "_blank")).html_safe
      end
    end

    text
  end

  def main_page_title
    if response.code == "404"
      title = t("titles.404")

    elsif response.code == "500"
      title = t("titles.500")

    elsif params[:controller] == "sessions"
      title = t("titles.login")

    elsif params[:controller] == "usercp/bridges"
      title = case params[:action]
        when "new" then t("titles.adding_bridge")
        when "edit" then t("titles.editing_bridge", :name => @bridge.name)
        else t("titles.bridges")
      end

    elsif params[:controller] == "usercp/triggers"
      title = case params[:action]
        when "new" then t("titles.adding_trigger")
        when "edit" then t("titles.editing_trigger", :name => @trigger.name)
        else t("titles.triggers")
      end

    elsif params[:controller] == "usercp/help"
      title = case params[:action]
        when "ifttt" then t("titles.help_ifttt")
      end

    elsif params[:controller] == "usercp/schedules"
      title = case params[:action]
        when "new" then t("titles.adding_schedule")
        when "edit" then t("titles.editing_schedule", :name => @schedule.name)
        else t("titles.schedules")
      end

    elsif params[:controller] == "usercp/settings"
      title = t("titles.account_management")

    elsif params[:controller] == "subscriptions"
      title = t("titles.subscription_plans")

    elsif params[:controller] == "home"
      if params[:action] == "privacy_policy"
        title = t("titles.privacy_policy")
      elsif params[:action] == "terms_conditions"
        title = t("titles.terms_conditions")
      end
    end


    "#{title || t("titles.home")} - Remote Hue"
  end
end
