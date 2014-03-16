require "spec_helper"

describe Api::MailgunController do
  before :all do
    @user = create(:user)
    @secondary_trigger = create(:trigger_on, :user => @user)
    @trigger = create(:trigger_on, :user => @user, :secondary_trigger => @secondary_trigger, :secondary_delay => 30)
  end

  before :each do
    TriggerHistory.delete_all
  end

  it "activates a trigger without RemoteHue tag" do
    Trigger::On.any_instance.should_receive(:run).once

    post :trigger, "body-plain" => "#{@trigger.mail_tag.gsub("RemoteHue:", "")}\r\n\r\n\r\n\r\nIFTTT\r\n\r\n\tvia Personal Recipe 3471130:\r\n\thttp://ifttt.com/myrecipes/personal/3471130\r\n\r\n", "secret" => CONFIG[:mailgun_secret]
    response.code.should == "200"

    TriggerHistory.where(:trigger_id => @trigger._id, :results => TriggerHistory::OK, :from => TriggerHistory::IFTTT).exists?.should be_true

    SecondaryTrigger.jobs.should have(1).job
    job = SecondaryTrigger.jobs.last
    job["args"].first.should == @secondary_trigger._id.to_s
    job["at"].should be_within(2).of((Time.now.utc + @trigger.secondary_delay).to_i)
  end

  it "activates a trigger" do
    Trigger::On.any_instance.should_receive(:run).once

    post :trigger, "body-plain" => "#{@trigger.mail_tag}\r\n\r\n\r\n\r\nIFTTT\r\n\r\n\tvia Personal Recipe 3471130:\r\n\thttp://ifttt.com/myrecipes/personal/3471130\r\n\r\n", "secret" => CONFIG[:mailgun_secret]
    response.code.should == "200"

    TriggerHistory.where(:trigger_id => @trigger._id, :results => TriggerHistory::OK, :from => TriggerHistory::IFTTT).exists?.should be_true

    SecondaryTrigger.jobs.should have(1).job
    job = SecondaryTrigger.jobs.last
    job["args"].first.should == @secondary_trigger._id.to_s
    job["at"].should be_within(2).of((Time.now.utc + @trigger.secondary_delay).to_i)
  end

  it "handles a missing user" do
    Trigger::On.any_instance.should_not_receive(:run).once

    post :trigger, "body-plain" => "foobar:#{@trigger.secret}\r\n\r\n\r\n\r\nIFTTT\r\n\r\n\tvia Personal Recipe 3471130:\r\n\thttp://ifttt.com/myrecipes/personal/3471130\r\n\r\n", "secret" => CONFIG[:mailgun_secret]
    response.code.should == "200"
  end

  it "handles a missing trigger" do
    post :trigger, "body-plain" => "#{@trigger.user_id}:foobar\r\n\r\n\r\n\r\nIFTTT\r\n\r\n\tvia Personal Recipe 3471130:\r\n\thttp://ifttt.com/myrecipes/personal/3471130\r\n\r\n", "secret" => CONFIG[:mailgun_secret]
    response.code.should == "200"

    TriggerHistory.where(:results => TriggerHistory::MISSING, :from => TriggerHistory::IFTTT).exists?.should be_true
  end
end