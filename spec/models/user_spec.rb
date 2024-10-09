require "rails_helper"

RSpec.describe User, type: :model do
  user = FactoryBot.build(:user)

  describe "validations" do
    it "validates presence of username" do
      user.username = nil
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("can't be blank")
    end

    it "validates length of username" do
      user.username = "a" * 16
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("is too long (maximum is 15 characters)")
    end

    it "validates presence of email" do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "validates format of email" do
      user.email = "invalid_email"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "validates presence of password on create" do
      user.password = nil
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "validates length of password on create" do
      user.password = "short"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
    end

    it "validates password format" do
      user.password = "password"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("Password must contain atleast one uppercase, lowercase and number")
    end
  end

  describe "associations" do
    it "has many uploads" do
      expect(user).to respond_to(:uploads)
    end
  end

  describe "before save" do
    it "downcases the email before saving" do
      user = FactoryBot.create(:user, username: "Dummy", email: "example@GMAIL.com", password: "123Wqsfdsdd", password_confirmation: "123Wqsfdsdd")
      user.save
      expect(user.email).to eq("example@gmail.com")
    end
  end
end
