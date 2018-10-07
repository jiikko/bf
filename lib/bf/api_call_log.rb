class BF::ApiCallLog < ::ActiveRecord::Base
  enum api_type: %i(public_api private_api)

  scope :old, ->{ where('created_at < ? and api_type in (?)', 100.seconds.ago, BF::ApiCallLog.api_types.values) }
  scope :recent, ->{ where('created_at > ?', 61.seconds.ago) }
end
