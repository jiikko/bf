class BF::ApiCallLog < ::ActiveRecord::Base
  enum api_type: %i(public_api private_api)
end
