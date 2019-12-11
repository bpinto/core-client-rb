require 'hashie'

class Ey::Core::Client::Account < Ey::Core::Model
  extend Ey::Core::Associations

  identity :id

  attribute :cancelled_at, type: :time
  attribute :created_at, type: :time
  attribute :emergency_contact
  attribute :fraudulent
  attribute :legacy_id
  attribute :name
  attribute :plan_type
  attribute :signup_via
  attribute :support_plan
  attribute :type
  attribute :updated_at, type: :time

  has_many :addresses
  has_many :applications
  has_many :deis_clusters
  has_many :environments
  has_many :features
  has_many :projects
  has_many :providers
  has_many :addons
  has_many :users
  has_many :owners, key: :users
  has_many :ssl_certificates
  has_many :referrals, key: :account_referrals
  has_many :costs
  has_many :memberships

  has_one :cancellation, assoc_name: 'account_cancellation', collection: :account_cancellations
  has_one :account_trial
  has_one :support_trial

  assoc_writer :owner

  attr_accessor :name_prefix, :plan  #only used on account create

  def cancel!(params = {})
    result = self.connection.cancel_account(self.id, params[:requested_by].id).body
    Ey::Core::Client::AccountCancellation.new(result["cancellation"])
  end

  def save!
    requires_one :name, :name_prefix

    params = {
      "account" => {
        "plan" => self.plan || "standard-20140130",
      },
      "owner" => self.owner_id,
    }

    if self.name
      params["account"]["name"] = self.name
    elsif self.name_prefix
      params["account"]["name_prefix"] = self.name_prefix
    end

    params["account"]["signup_via"] = self.signup_via if self.signup_via
    params["account"]["type"]       = self.type       if self.type

    if new_record?
      merge_attributes(self.connection.create_account(params).body["account"])
    else raise NotImplementedError # update
    end
  end

  # Get authorization data for an Amazon ECR registry.
  # @param [String] location_id Aws region
  # @return [Hashie::Mash]
  def retrieve_docker_registry_credentials(location_id)
    result = self.connection.retrieve_docker_registry_credentials(self.id, location_id).body
    ::Hashie::Mash.new(result['docker_registry_credentials'])
  end
end
