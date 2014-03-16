class Usercp::TriggersController < Usercp::BaseController
  def index
    @triggers = current_user.triggers.sort_by {|t| t.name}
  end

  def new
    @trigger = Trigger.new
    @active_lights, @active_groups = {}, {}

    render :manage
  end

  def usage
    @trigger = current_user.triggers.where(:_id => params[:id].to_s).first
    return render_404 unless @trigger

    render :layout => false
  end

  def history
    @trigger = current_user.triggers.where(:_id => params[:id].to_s).only(:name).first
    return render_404 unless @trigger

    @history = current_user.trigger_history.where(:trigger_id => @trigger._id).sort(:_id.desc).map {|h| h}
    render :layout => false
  end

  def create
    manage_trigger(Trigger.new(:user => current_user))
  end

  def regenerate
    trigger = current_user.triggers.where(:_id => params[:id].to_s).first
    return render_404 unless trigger

    trigger.regenerate_secret!

    render :nothing => true, :status => :no_content
  end

  def edit
    @trigger = current_user.triggers.where(:_id => params[:id].to_s).first
    return render_404 unless @trigger

    @active_lights, @active_groups = {}, {}
    if @trigger.respond_to?(:bridges)
      @trigger.bridges.each do |bridge|
        @active_lights[bridge.bridge_id] = {}
        bridge.light_ids.each do |light|
          @active_lights[bridge.bridge_id][light] = true
        end

        @active_groups[bridge.bridge_id] = {}
        bridge.group_ids.each do |group|
          @active_groups[bridge.bridge_id][group] = true
        end
      end

    end

    render :manage
  end

  def update
    trigger = current_user.triggers.where(:_id => params[:id].to_s).first
    return render_404 unless trigger
    manage_trigger(trigger)
  end

  def destroy
    trigger = current_user.triggers.where(:_id => params[:id].to_s).first
    if trigger
      current_user.triggers.where(:secondary_trigger_id => trigger._id).update({"$unset" => {:secondary_trigger_id => true, :secondary_delay => true}}, {:multi => true})
      current_user.schedules.where(:trigger_ids => trigger._id).update({"$pull" => {:trigger_ids => trigger._id}}, {:multi => true})

      trigger.destroy
    end

    render :nothing => true, :status => :no_content
  end

  private
  def load_trigger_class(trigger, klass)
    if trigger.new_record?
      "Trigger::#{klass}".constantize.new(trigger.attributes)
    else
      "Trigger::#{klass}".constantize.new.initialize_from_database(trigger.attributes.merge("_type" => "Trigger::#{klass}"))
    end
  end

  def manage_trigger(trigger)
    trigger.name = params[:name]

    if params[:type] == "flash"
      trigger = load_trigger_class(trigger, "Flash")
    elsif params[:type] == "on"
      trigger = load_trigger_class(trigger, "On")
    elsif params[:type] == "off"
      trigger = load_trigger_class(trigger, "Off")
    elsif params[:type] == "scene"
      trigger = load_trigger_class(trigger, "Flash")
    end

    if BSON::ObjectId.legal?(params[:secondary_trigger_id])
      if Trigger.where(:user_id => current_user._id, :_id => params[:secondary_trigger_id]).exists?
        trigger.secondary_trigger_id = params[:secondary_trigger_id]
        trigger.secondary_delay = params[:secondary_delay].to_i
      end
    else
      trigger.secondary_trigger_id = nil
      trigger.secondary_delay = nil
    end

    if trigger.instance_of?(Trigger::Off)
      trigger.color = Color.new(:on => false, :bri => 0, :transitiontime => params[:transitiontime].to_i)
    elsif trigger.respond_to?(:color)
      if params[:color][:ct]
        trigger.color = Color::Temperature.new
        trigger.color.ct = params[:color][:ct].to_i
      else
        trigger.color = Color::HueSat.new
        trigger.color.hue = params[:color][:hue].to_i
        trigger.color.sat = params[:color][:sat].to_i
      end

      trigger.color.bri = params[:color][:bri].to_i
      trigger.color.on = trigger.color.bri > 0
      trigger.color.transitiontime = params[:transitiontime].to_i
    end

    if trigger.instance_of?(Trigger::Flash)
      trigger.duration = params[:duration].to_i
    end

    if trigger.respond_to?(:bridges)
      # Turn it into an useful format
      summary = {}
      [[:lights, params[:lights]], [:groups, params[:groups]]].each do |key, list|
        next unless list.is_a?(Array)

        list.each do |id|
          bridge_id, object_id = id.split("_", 2)
          summary[bridge_id] ||= {}
          summary[bridge_id][key] ||= {}
          summary[bridge_id][key][object_id] = 0
        end
      end

      # Make sure we own the light/groups
      unless summary.empty?
        Bridge.where(:user_id => current_user._id, :_id.in => summary.keys).only("groups._id", "lights._id").each do |bridge|
          bridge_id = bridge._id.to_s
          if summary[bridge_id][:lights]
            bridge.lights.each do |light|
              if summary[bridge_id][:lights][light._id.to_s]
                summary[bridge_id][:lights][light._id.to_s] = 1
              end
            end
          end

          if summary[bridge_id][:groups]
            bridge.groups.each do |group|
              if summary[bridge_id][:groups][group._id.to_s]
                summary[bridge_id][:groups][group._id.to_s] = 1
              end
            end
          end
        end
      end


      trigger.bridges = []
      summary.each do |bridge_id, data|
        lights, groups = [], []
        if data[:lights]
          data[:lights].each {|id, state| lights.push(id) if state == 1}
        end
        if data[:groups]
          data[:groups].each {|id, state| groups.push(id) if state == 1}
        end


        trigger.bridges << Trigger::Bridge.new(:bridge_id => bridge_id, :light_ids => lights, :group_ids => groups)
      end
    end

    trigger.save
    respond_with_model(trigger)
  end
end