require 'spec_helper'

describe AnonymousShadowCreator do

  it "returns no shadow by default" do
    expect(AnonymousShadowCreator.get(Fabricate.build(:user))).to eq(nil)
  end

  it "returns no shadow if trust level is not met" do
    SiteSetting.allow_anonymous_posting = true
    expect(AnonymousShadowCreator.get(Fabricate.build(:user, trust_level: 0))).to eq(nil)
  end

  it "returns a new shadow once time expires" do
    SiteSetting.allow_anonymous_posting = true
    SiteSetting.anonymous_account_duration_minutes = 1

    user = Fabricate(:user, trust_level: 3)
    shadow = AnonymousShadowCreator.get(user)

    freeze_time 2.minutes.from_now
    shadow2 = AnonymousShadowCreator.get(user)

    expect(shadow.id).to eq(shadow2.id)
    create_post(user: shadow)

    freeze_time 4.minutes.from_now
    shadow3 = AnonymousShadowCreator.get(user)

    expect(shadow2.id).not_to eq(shadow3.id)

  end

  it "returns a shadow for a legit user" do
    SiteSetting.allow_anonymous_posting = true
    user = Fabricate(:user, trust_level: 3)

    shadow = AnonymousShadowCreator.get(user)
    shadow2 = AnonymousShadowCreator.get(user)

    expect(shadow.id).to eq(shadow2.id)

    expect(shadow.trust_level).to eq(1)
    expect(shadow.username).to eq("anonymous")

    expect(shadow.created_at).not_to eq(user.created_at)


    p = create_post
    expect(Guardian.new(shadow).post_can_act?(p, :like)).to eq(false)
    expect(Guardian.new(user).post_can_act?(p, :like)).to eq(true)

    expect(user.anonymous?).to eq(false)
    expect(shadow.anonymous?).to eq(true)
  end

end
