require "spec_helper"

describe BridgeSyncer do
  before :all do
    @user = create(:user)
  end

  it "resyncs a bridge" do
    valid_bridge = create(:bridge, :user => @user, :manually_resynced => true, :next_update_at => 5.minutes.ago.utc, :status => Bridge::ACTIVE)
    not_ready_bridge = create(:bridge, :user => @user, :next_update_at => 2.hours.from_now.utc, :status => Bridge::ACTIVE)
    inactive_bridge = create(:bridge, :user => @user, :status => Bridge::OFFLINE)

    Bridge.any_instance.should_receive(:load_data).once

    described_class.new.perform

    valid_bridge.reload
    valid_bridge.manually_resynced.should_not be_true
    valid_bridge.next_update_at.should be_within(5.hours).of(20.hours.from_now.utc)

    not_ready_bridge.next_update_at.should be_within(1.minute).of(2.hours.from_now.utc)
    inactive_bridge.next_update_at.should be_nil
  end
end