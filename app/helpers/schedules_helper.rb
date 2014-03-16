module SchedulesHelper
  def solar_offset_options(type)
    list = []

    list.push([t("usercp.schedules.manage.before_#{type}_hour", :count => 3), -180])
    list.push([t("usercp.schedules.manage.before_#{type}_hour", :count => 2.5), -150])
    list.push([t("usercp.schedules.manage.before_#{type}_hour", :count => 2), -120])
    list.push([t("usercp.schedules.manage.before_#{type}_hour", :count => 1.5), -90])
    list.push([t("usercp.schedules.manage.before_#{type}_hour", :count => 1), -60])

    [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55].reverse.each do |min|
      list.push([t("usercp.schedules.manage.before_#{type}", :minutes => min), -min])
    end

    list.push([t("usercp.schedules.manage.at_#{type}"), 0])

    [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55].each do |min|
      list.push([t("usercp.schedules.manage.after_#{type}", :minutes => min), min])
    end

    list.push([t("usercp.schedules.manage.after_#{type}_hour", :count => 1), 60])
    list.push([t("usercp.schedules.manage.after_#{type}_hour", :count => 1.5), 90])
    list.push([t("usercp.schedules.manage.after_#{type}_hour", :count => 2), 120])
    list.push([t("usercp.schedules.manage.after_#{type}_hour", :count => 2.5), 150])
    list.push([t("usercp.schedules.manage.after_#{type}_hour", :count => 3), 180])

    # Convert minutes into seconds
    list.each {|t| t[1] = t[1] * 60}

    list
  end

  def trigger_list
    list = {}
    current_user.triggers.sort(:name.asc).only(:name, :_type).each do |trigger|
      list[t("trigger_types.#{trigger._type}")] ||= []
      list[t("trigger_types.#{trigger._type}")].push([trigger.name, trigger._id])
    end

    list
  end
end