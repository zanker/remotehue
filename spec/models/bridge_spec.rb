require "spec_helper"

describe Bridge, :vcr => true do
  before :all do
    @user = create(:user)

    @bridge = Bridge.new(:user => @user)
    @bridge.local_ip = "192.168.1.100"
    @bridge.meethue_token = 'KFG/TKZn6nHPp4Z9hbZq2z0ZEUuqRJwiE0Il+hjVDN4='
    @bridge.api_key = "53ea557007444ffa96481ae5a29f48d6edda9904"
    @bridge.bridge_id = "001788fffe094961"
  end

  it "sends a command to MeetHue" do
    res = @bridge.remote_command({:url => "/api/0/lights/1/state", :method => "PUT", :body => {:on => true}})
    res.should be_true
  end

  it "imports @bridge data from MeetHue" do
    @bridge.load_data

    @bridge.total_lights.should == 8
    @bridge.total_groups.should == 1
    @bridge.mac_text.should == "00:17:88:09:49:61"
    @bridge.name.should == "Philips hue"
    @bridge.update_state.should == 0

    @bridge.devices.should have(6).devices
    device = @bridge.devices.first
    device.api_key.should == "06584ed4275c3ac82c8bb6f23c49d75c7d87d78e"
    device.last_used_at.should == Time.parse("Fri, 03 May 2013 11:55:06 UTC +00:00")
    device.name.should == "Remote Hue"
    device.updated_at.should be_within(1).of(Time.now.utc)
    device.created_at.should == Time.parse("Thu, 02 May 2013 08:23:18 UTC +00:00")

    @bridge.lights.should have(8).lights
    light = @bridge.lights.first
    light.light_id.should == 3
    light.name.should == "Bed Bottom"
    light.model_id.should == "LCT001"
    light.swversion.should == "65003148"
    light.type.should == "Extended color light"
    light.updated_at.should be_within(1).of(Time.now.utc)
    light.created_at.should be_within(1).of(Time.now.utc)

    @bridge.groups.should have(1).group
    light_id = @bridge.lights.select {|l| l.light_id == 1}.first._id

    group = @bridge.groups.first
    group.group_id.should == 1
    group.light_ids.should == [light_id]
    group.updated_at.should be_within(1).of(Time.now.utc)
    group.created_at.should be_within(1).of(Time.now.utc)
  end
end